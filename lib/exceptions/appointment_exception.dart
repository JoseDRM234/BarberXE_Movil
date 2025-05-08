class AppointmentException implements Exception {
  final String message;
  AppointmentException(this.message);

  @override
  String toString() => 'AppointmentException: $message';
}