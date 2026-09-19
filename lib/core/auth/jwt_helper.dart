import 'dart:convert';

/// Lectura minima del payload de un JWT, sin dependencias externas.
///
/// Solo se usa para decidir si conviene intentar restaurar la sesion: la
/// validacion real del token siempre la hace el backend.
class JwtHelper {
	const JwtHelper._();

	/// Momento de expiracion declarado en el claim `exp`, o null si el token
	/// no es un JWT legible o no declara expiracion.
	static DateTime? obtenerExpiracion(String token) {
		final payload = _decodificarPayload(token);
		if (payload == null) {
			return null;
		}

		final dynamic exp = payload['exp'];
		if (exp is! num) {
			return null;
		}

		return DateTime.fromMillisecondsSinceEpoch(
			exp.toInt() * 1000,
			isUtc: true,
		);
	}

	/// True si el token ya vencio o si no se puede leer.
	///
	/// Un token ilegible se trata como vencido: es preferible pedir login antes
	/// que arrancar con una sesion rota. Un JWT valido sin claim `exp` se
	/// considera vigente y queda en manos del backend rechazarlo con 401.
	static bool estaVencido(
		String token, {
		Duration margen = const Duration(seconds: 30),
	}) {
		if (_decodificarPayload(token) == null) {
			return true;
		}

		final expiracion = obtenerExpiracion(token);
		if (expiracion == null) {
			return false;
		}

		return DateTime.now().toUtc().add(margen).isAfter(expiracion);
	}

	static Map<String, dynamic>? _decodificarPayload(String token) {
		final partes = token.split('.');
		if (partes.length != 3) {
			return null;
		}

		try {
			final bytes = base64Url.decode(base64Url.normalize(partes[1]));
			final dynamic json = jsonDecode(utf8.decode(bytes));
			return json is Map<String, dynamic> ? json : null;
		} catch (_) {
			return null;
		}
	}
}
