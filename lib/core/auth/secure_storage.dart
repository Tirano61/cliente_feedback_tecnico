import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
	static const String _tokenKey = 'jwt_token';
	final FlutterSecureStorage _storage;

	SecureStorage({FlutterSecureStorage? storage})
			: _storage = storage ?? const FlutterSecureStorage();

	Future<void> guardarToken(String token) {
		return _storage.write(key: _tokenKey, value: token);
	}

	Future<String?> obtenerToken() {
		return _storage.read(key: _tokenKey);
	}

	Future<void> borrarToken() {
		return _storage.delete(key: _tokenKey);
	}

	Future<void> guardarValor({required String key, required String value}) {
		return _storage.write(key: key, value: value);
	}

	Future<String?> obtenerValor(String key) {
		return _storage.read(key: key);
	}

	Future<void> borrarValor(String key) {
		return _storage.delete(key: key);
	}
}
