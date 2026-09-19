import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';

/// Storage en memoria: evita el canal nativo de flutter_secure_storage.
class SecureStorageEnMemoria implements SecureStorage {
	final Map<String, String> valores = {};

	@override
	Future<void> guardarToken(String token) async => valores['jwt_token'] = token;

	@override
	Future<String?> obtenerToken() async => valores['jwt_token'];

	@override
	Future<void> borrarToken() async => valores.remove('jwt_token');

	@override
	Future<void> guardarUsuario(String usuarioJson) async =>
			valores['usuario_sesion'] = usuarioJson;

	@override
	Future<String?> obtenerUsuario() async => valores['usuario_sesion'];

	@override
	Future<void> borrarUsuario() async => valores.remove('usuario_sesion');

	@override
	Future<void> guardarValor({required String key, required String value}) async =>
			valores[key] = value;

	@override
	Future<String?> obtenerValor(String key) async => valores[key];

	@override
	Future<void> borrarValor(String key) async => valores.remove(key);
}
