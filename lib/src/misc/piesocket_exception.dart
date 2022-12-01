class PieSocketException implements Exception {
  String cause;
  PieSocketException(this.cause);

  @override
  String toString() {
    return 'Cause: $cause';
  }
}
