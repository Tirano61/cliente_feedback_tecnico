import 'dart:convert';

/// Arma un JWT de mentira (firma invalida) con el claim `exp` pedido.
String jwtConExpiracion(DateTime expiracion) {
	return [
		_segmento({'alg': 'HS256', 'typ': 'JWT'}),
		_segmento({
			'sub': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
			'exp': expiracion.toUtc().millisecondsSinceEpoch ~/ 1000,
		}),
		'firma-de-prueba',
	].join('.');
}

String jwtSinExpiracion() {
	return [
		_segmento({'alg': 'HS256', 'typ': 'JWT'}),
		_segmento({'sub': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c'}),
		'firma-de-prueba',
	].join('.');
}

String _segmento(Map<String, dynamic> json) {
	return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}
