import 'dart:convert';
import 'dart:core';

class PieSocketEvent {
  const PieSocketEvent({
    required this.event,
    this.data,
    this.meta,
  });

  final String event;
  final Object? data;
  final Object? meta;

  String getEncodedData() {
    final Map<String, dynamic> payload = {};
    payload['event'] = event;
    payload['meta'] = meta;
    payload['data'] = data;
    return json.encode(payload);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PieSocketEvent && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() {
    return 'PieSocketEvent{event: $event, data: $data, meta: $meta}';
  }
}
