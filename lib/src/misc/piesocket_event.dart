import 'dart:convert';
import 'dart:core';

class PieSocketEvent {
  late String _event;
  late String _data;
  late String _meta;

  PieSocketEvent(this._event) {
    _data = "";
    _meta = "";
  }

  String getEvent() {
    return _event;
  }

  PieSocketEvent setEvent(String event) {
    _event = event;
    return this;
  }

  String getData() {
    return _data;
  }

  PieSocketEvent setData(String data) {
    _data = data;
    return this;
  }

  String getMeta() {
    return _meta;
  }

  PieSocketEvent setMeta(String meta) {
    _meta = meta;
    return this;
  }

  @override
  String toString() {
    final Map<String, dynamic> data = {};
    data['event'] = _event;
    data['data'] = _data;
    data['meta'] = _meta;

    return json.encode(data).toString();
  }
}
