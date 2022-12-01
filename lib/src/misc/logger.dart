import 'dart:developer';

class Logger {
  static const String LOG_TAG = "PIESOCKET-SDK-LOGS";
  late bool _enabled;

  Logger(bool enabled) {
    _enabled = enabled;
  }

  void debug(String text) {
    if (_enabled) {
      log("$LOG_TAG: $text");
    }
  }
}
