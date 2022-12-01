import 'dart:developer';

import 'package:piesocket_channels/channels.dart';

class Example {
  late Channel room;
  late PieSocket piesocket;

  Example() {
    var options = PieSocketOptions();
    options.setClusterId("demo");
    options.setApiKey("VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV");
    // options.setForceAuth(true);
    options.setAuthEndpoint("https://www.piesocket.com/test");
    options.setPresence(true);

    var headers = {"Client": "tetsdk"};
    options.setAuthHeaders(headers);

    piesocket = PieSocket(options);
    room = piesocket.join("test");

    room.listen("*", (PieSocketEvent event) {
      log("EVENT!");
      print(event.toString());
    });

    room.listen("system:message", (PieSocketEvent event) {
      log("MESSAGE!");
      print(event.toString());
    });
  }

  void click() {
    PieSocketEvent testevent = PieSocketEvent("testevent");
    testevent.setData("ok");
    testevent.setMeta("meta");

    room.publish(testevent);
  }
}
