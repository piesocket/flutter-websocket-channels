import 'dart:developer';

import 'package:piesocket_channels/channels.dart';

class Example {
  late Channel room;
  late PieSocket piesocket;

  Example() {
    const options = PieSocketOptions(
        clusterId: 'demo',
        apiKey: 'VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV',
        // forceAuth: true,
        authEndpoint: 'https://www.piesocket.com/test',
        presence: true,
        authHeaders: {"Client": "flutter-app"});

    piesocket = PieSocket(options);
    room = piesocket.join("test-room");

    room.listen("*", (PieSocketEvent event) {
      log("EVENT!");
      print(event.toString());
    });

    room.listen("system:message", (PieSocketEvent event) {
      log("MESSAGE!");
      print(event.toString());
    });

    // any event that start with 'system:'
    room.listen("system:*", (PieSocketEvent event) {
      log("MESSAGE!");
      print(event.toString());
    });
  }

  void click() {
    const testEvent = PieSocketEvent(event: 'testevent', data: 'ok', meta: 'web');
    room.publish(testEvent);
  }
}
