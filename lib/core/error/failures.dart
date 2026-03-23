class ServerException implements Exception {
	final String mensaje;
	final int? statusCode;

	const ServerException(this.mensaje, {this.statusCode});
}

class AuthException implements Exception {
	final String mensaje;

	const AuthException(this.mensaje);
}

class NetworkException implements Exception {
	final String mensaje;

	const NetworkException(this.mensaje);
}
