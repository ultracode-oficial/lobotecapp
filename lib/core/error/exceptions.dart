class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Sem conexão com a internet.']);
}

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  const ValidationException(this.message, {this.errors});
}
