import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:piesocket_channels/src/misc/logger.dart';
import 'package:piesocket_channels/src/misc/piesocket_event.dart';
import 'package:piesocket_channels/src/misc/piesocket_exception.dart';
import 'package:piesocket_channels/src/misc/piesocket_options.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef OnEvent = void Function(PieSocketEvent event);

class Channel {
  static const int NORMAL_CLOSURE_STATUS = 1000;

  final String id;
  final String uuid = const Uuid().v4();
  final Logger logger;
  PieSocketOptions options;

  final Map<String, Map<String, OnEvent>> _listeners = {};
  final Map<String, Map<String, OnEvent>> _prefixListeners = {};
  List _members = [];

  late WebSocketChannel ws;
  bool _shouldReconnect = false;
  bool _connected = false;
  StreamSubscription? _streamSubscription;

  Channel(this.id, this.options, this.logger) {
    _shouldReconnect = false;
  }

  factory Channel.connect(String websocketUrl, bool enableLogs) {
    return Channel(
      'standalone',
      PieSocketOptions(webSocketEndpoint: websocketUrl),
      Logger(enableLogs),
    );
  }

  String buildEndpoint() {
    if (options.webSocketEndpoint.isNotEmpty) {
      return options.webSocketEndpoint;
    }

    String endpoint =
        "wss://${options.clusterId}.piesocket.com/v${options.version}/$id?api_key=${options.apiKey}&notify_self=${options.getNotifySelf()}&source=fluttersdk&v=1&be=1&presence=${options.getPresence()}";

    String? jwt = getAuthToken();
    if (jwt != null) {
      endpoint = "$endpoint&jwt=$jwt";
    }

    if (options.userId.isNotEmpty) {
      endpoint = "$endpoint&user=${options.userId}";
    }

    //Add UUID
    endpoint = "$endpoint&uuid=$uuid";

    return endpoint;
  }

  bool isGuarded() {
    if (options.forceAuth) {
      return true;
    }

    return id.startsWith("private-");
  }

  String? getAuthToken() {
    if (options.jwt.isNotEmpty) {
      return options.jwt;
    }

    if (isGuarded()) {
      if (options.authEndpoint.isNotEmpty) {
        getAuthTokenFromServer();
        throw PieSocketException("JWT not provided, will fetch from authEndpoint.");
      } else {
        throw PieSocketException("Neither JWT, nor authEndpoint is provided for private channel authentication.");
      }
    }

    return null;
  }

  Future<void> getAuthTokenFromServer() async {
    try {
      String apiURL = options.authEndpoint;

      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        ...options.authHeaders,
      };

      final body = json.encode({"channel_name": id, "connection_uuid": uuid});
      final apiResult = await http.post(
        Uri.parse(apiURL),
        headers: headers,
        body: body,
      );

      final jsonObject = json.decode(apiResult.body) as Map;
      if (jsonObject['auth'] != null) {
        logger.debug("Auth token fetched, resuming connection");
        options = options.copyWith(jwt: jsonObject['auth']);
        connect();
      }
    } catch (e) {
      throw PieSocketException("Auth Token Response Parsing Error: ${e.toString()}");
    }
  }

  void connect() {
    if (_connected) return;

    _connected = true;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    logger.debug("Connecting to: $id");

    try {
      final endpoint = buildEndpoint();
      logger.debug("WebSocket Endpoint: $endpoint");

      ws = WebSocketChannel.connect(Uri.parse(endpoint));

      _streamSubscription = ws.stream.listen(
        (message) => onMessage(message),
        cancelOnError: true,
        onError: (error) => onError(error),
        onDone: onClosing,
      );
    } catch (e) {
      if (e.toString().contains("will fetch from authEndpoint")) {
        logger.debug("Defer connection: fetching token from authEndpoint");
      } else {
        _connected = false;
        rethrow;
      }
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _connected = false;
    ws.sink.close(NORMAL_CLOSURE_STATUS);
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  void reconnect() {
    if (_shouldReconnect || !_connected) {
      _connected = false;
      connect();
    }
  }

  bool get hasAnyListener => _listeners.isNotEmpty || _prefixListeners.isNotEmpty;

  String listen(String eventName, OnEvent callback) {
    if (eventName.endsWith('*') && eventName.length > 1) {
      final Map<String, OnEvent> callbacks;
      final prefix = eventName.substring(0, eventName.length - 1);

      if (_prefixListeners.containsKey(prefix)) {
        callbacks = _prefixListeners[prefix]!;
      } else {
        callbacks = {};
      }

      final listenerId = const Uuid().v4();
      callbacks[listenerId] = callback;
      _prefixListeners[prefix] = callbacks;

      return listenerId;
    } else {
      final Map<String, OnEvent> callbacks;
      if (_listeners.containsKey(eventName)) {
        callbacks = _listeners[eventName]!;
      } else {
        callbacks = {};
      }

      final listenerId = const Uuid().v4();
      callbacks[listenerId] = callback;
      _listeners[eventName] = callbacks;

      return listenerId;
    }
  }

  void removeListener(String eventName, String listenerId) {
    if (_listeners.containsKey(eventName)) {
      _listeners[eventName]?.remove(listenerId);
    }

    final prefixEventName = eventName.length > 1 ? eventName.substring(0, eventName.length - 1) : eventName;
    if (_prefixListeners.containsKey(prefixEventName)) {
      _prefixListeners[prefixEventName]?.remove(listenerId);
    }
  }

  void removeAllListeners(String eventName) {
    if (_listeners.containsKey(eventName)) {
      _listeners.remove(eventName);
    }

    final prefixEventName = eventName.length > 1 ? eventName.substring(0, eventName.length - 1) : eventName;
    if (_prefixListeners.containsKey(prefixEventName)) {
      _prefixListeners.remove(prefixEventName);
    }
  }

  void _fireEvent(PieSocketEvent event) {
    logger.debug("Firing Event: $event");

    if (_listeners.containsKey(event.event)) {
      _triggerAllListeners(event.event, event);
    }

    if (_listeners.containsKey("*")) {
      _triggerAllListeners("*", event);
    }

    for (final prefixEntry in _prefixListeners.entries) {
      if (event.event.startsWith(prefixEntry.key)) {
        _triggerPrefixListeners(prefixEntry.key, event);
      }
    }
  }

  void _triggerAllListeners(String eventName, PieSocketEvent event) {
    final Map<String, OnEvent>? callbacks = _listeners[eventName];
    if (callbacks == null) return;

    for (final fn in callbacks.values) {
      fn(event);
    }
  }

  void _triggerPrefixListeners(String eventName, PieSocketEvent event) {
    final Map<String, OnEvent>? callbacks = _prefixListeners[eventName];
    if (callbacks == null) return;

    for (final fn in callbacks.values) {
      fn(event);
    }
  }

  void publish(PieSocketEvent event) {
    ws.sink.add(event.getEncodedData());
  }

  void send(String text) {
    ws.sink.add(text);
  }

  void onOpen() {
    PieSocketEvent event = PieSocketEvent(event: "system:connected");
    _fireEvent(event);

    _shouldReconnect = true;
  }

  void onMessage(String text) {
    if (_listeners.containsKey("system:message")) {
      final payload = PieSocketEvent(event: 'system:message', data: text);
      _triggerAllListeners("system:message", payload);
    }

    try {
      final obj = json.decode(text);

      if (obj["event"] != null) {
        final eventName = obj["event"] as String;

        if (eventName == "system:boot") {
          onOpen();
        } else {
          Object? eventData;
          String? eventMeta;

          if (obj['data'] != null) {
            eventData = obj['data'];
          }

          if (obj["meta"] != null) {
            eventMeta = obj['meta'];
          }

          // Trigger listeners
          final event = PieSocketEvent(
            event: eventName,
            data: eventData ?? '',
            meta: eventMeta ?? '',
          );
          handleSystemEvents(event);
          _fireEvent(event);
        }
      }

      if (obj["error"] != null) {
        _shouldReconnect = false;
        PieSocketEvent event = PieSocketEvent(event: "system:error", data: obj["error"] ?? 'Error');
        _fireEvent(event);
      }
    } catch (e) {
      //Ignore error
      logger.debug("Non-json message received: $text");
    }
  }

  void handleSystemEvents(PieSocketEvent event) {
    try {
      //Update members list
      switch (event.event) {
        case 'system:member_list':
        case 'system:member_joined':
        case 'system:member_left':
          var data = json.decode(event.data as String);
          _members = data["members"] as List;
      }
    } catch (e) {
      throw PieSocketException(e.toString());
    }
  }

  void onClosing() {
    const event = PieSocketEvent(event: 'system:closed');
    _fireEvent(event);

    _connected = false;
    reconnect();
  }

  void onError(dynamic error) {
    final event = PieSocketEvent(event: 'system:error', data: error.toString());
    _fireEvent(event);
  }

  dynamic getMemberByUUID(String uuid) {
    for (var member in _members) {
      try {
        if (member["uuid"] == uuid) {
          return member;
        }
      } catch (e) {
        //Ignore errors, member can be a string and JSONException is possible
      }
    }

    return null;
  }

  dynamic getCurrentMember() {
    return getMemberByUUID(uuid);
  }

  List getAllMembers() {
    return _members;
  }
}
