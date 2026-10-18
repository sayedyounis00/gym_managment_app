class DatabaseException implements Exception {
  final String message;
  const DatabaseException([this.message = 'Database exception']);

  @override
  String toString() => 'DatabaseException: $message';
}
