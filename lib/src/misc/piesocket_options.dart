import 'dart:core';

class PieSocketOptions {
  const PieSocketOptions({
    this.apiKey = '',
    this.clusterId = '',
    this.enableLogs = false,
    this.notifySelf = false,
    this.jwt = '',
    this.presence = false,
    this.authEndpoint = '',
    this.authHeaders = const {},
    this.forceAuth = false,
    this.userId = '',
    this.webSocketEndpoint = '',
  });

  final String version = '3';
  final String apiKey;
  final String clusterId;
  final bool enableLogs;
  final bool notifySelf;
  final String jwt;
  final bool presence;
  final String authEndpoint;
  final Map<String, String> authHeaders;
  final bool forceAuth;
  final String userId;
  final String webSocketEndpoint;

  int getNotifySelf() {
    return notifySelf ? 1 : 0;
  }

  int getPresence() {
    return presence ? 1 : 0;
  }

  PieSocketOptions copyWith({
    String? apiKey,
    String? clusterId,
    bool? enableLogs,
    bool? notifySelf,
    String? jwt,
    bool? presence,
    String? authEndpoint,
    Map<String, String>? authHeaders,
    bool? forceAuth,
    String? userId,
    String? webSocketEndpoint,
  }) {
    return PieSocketOptions(
      apiKey: apiKey ?? this.apiKey,
      clusterId: clusterId ?? this.clusterId,
      enableLogs: enableLogs ?? this.enableLogs,
      notifySelf: notifySelf ?? this.notifySelf,
      jwt: jwt ?? this.jwt,
      presence: presence ?? this.presence,
      authEndpoint: authEndpoint ?? this.authEndpoint,
      authHeaders: authHeaders ?? this.authHeaders,
      forceAuth: forceAuth ?? this.forceAuth,
      userId: userId ?? this.userId,
      webSocketEndpoint: webSocketEndpoint ?? this.webSocketEndpoint,
    );
  }

  @override
  String toString() {
    return 'PieSocketOptions{version: $version, apiKey: $apiKey, clusterId: $clusterId, enableLogs: $enableLogs, notifySelf: $notifySelf, jwt: $jwt, presence: $presence, authEndpoint: $authEndpoint, authHeaders: $authHeaders, forceAuth: $forceAuth, userId: $userId, webSocketEndpoint: $webSocketEndpoint}';
  }
}
