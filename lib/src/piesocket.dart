import 'dart:collection';

import 'channel.dart';
import 'misc/logger.dart';
import 'misc/piesocket_exception.dart';
import 'misc/piesocket_options.dart';

class PieSocket {
  String counter = "ok";

  late Map<String, Channel> rooms;
  late PieSocketOptions options;
  late Logger logger;

  PieSocket(PieSocketOptions pieSocketOptions) {
    rooms = HashMap();
    options = pieSocketOptions;
    logger = Logger(options.getEnableLogs());

    _validateOptions();
  }

  void _validateOptions() {
    if (options.getClusterId().isEmpty) {
      throw PieSocketException("Cluster ID is not provided");
    }

    if (options.getApiKey().isEmpty) {
      throw PieSocketException("API Key is not provided");
    }
  }

  Channel join(String roomId) {
    if (rooms.containsKey(roomId)) {
      logger.debug("Returning existing room instance: $roomId");
      return rooms[roomId]!;
    }

    Channel room = Channel(roomId, options, logger);
    rooms[roomId] = room;

    return room;
  }

  void leave(String roomId) {
    if (rooms.containsKey(roomId)) {
      logger.debug("DISCONNECT: Closing room connection: $roomId");
      rooms[roomId]?.disconnect();
      rooms.remove(roomId);
    } else {
      logger.debug("DISCONNECT: Room does not exist: $roomId");
    }
  }

  Map<String, Channel> getAllRooms() {
    return rooms;
  }
}
