import 'dart:async';
import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
	final http.Client _client;
	final SecureStorage _storage;
	final StreamController<void> _sesionExpirada =
			StreamController<void>.broadcast();

	ApiClient(this._client, this._storage);

	/// Emite cada vez que el backend rechaza el token con 401.
	///
	/// El AuthBloc lo escucha para limpiar la sesion y volver al login en vez
	/// de dejar la app autenticada contra un token que ya no sirve.
	Stream<void> get sesionExpirada => _sesionExpirada.stream;

	Future<http.Response> get(String path) async {
		final token = await _storage.obtenerToken();
		return _revisarSesion(
			path,
			await _client.get(
				Uri.parse('${ApiConstants.baseUrl}$path'),
				headers: _buildHeaders(token),
			),
		);
	}

	Future<http.Response> post(String path, Map<String, dynamic> body) async {
		final token = await _storage.obtenerToken();
		return _revisarSesion(
			path,
			await _client.post(
				Uri.parse('${ApiConstants.baseUrl}$path'),
				headers: _buildHeaders(token),
				body: jsonEncode(body),
			),
		);
	}

	Future<http.Response> patch(String path, Map<String, dynamic> body) async {
		final token = await _storage.obtenerToken();
		return _revisarSesion(
			path,
			await _client.patch(
				Uri.parse('${ApiConstants.baseUrl}$path'),
				headers: _buildHeaders(token),
				body: jsonEncode(body),
			),
		);
	}

	Future<http.Response> postMultipart({
		required String path,
		required List<http.MultipartFile> archivos,
		Map<String, String>? campos,
	}) async {
		final token = await _storage.obtenerToken();
		final request = http.MultipartRequest(
			'POST',
			Uri.parse('${ApiConstants.baseUrl}$path'),
		);

		request.headers.addAll(_buildMultipartHeaders(token));
		if (campos != null && campos.isNotEmpty) {
			request.fields.addAll(campos);
		}
		request.files.addAll(archivos);

		final streamed = await _client.send(request);
		return _revisarSesion(path, await http.Response.fromStream(streamed));
	}

	/// Un 401 fuera del login significa token vencido o revocado.
	/// El 401 del propio login es "credenciales invalidas" y no toca la sesion.
	http.Response _revisarSesion(String path, http.Response response) {
		if (response.statusCode == 401 &&
				path != ApiConstants.login &&
				!_sesionExpirada.isClosed) {
			_sesionExpirada.add(null);
		}

		return response;
	}

	Future<void> dispose() {
		return _sesionExpirada.close();
	}

	Map<String, String> _buildHeaders(String? token) {
		return {
			'Content-Type': 'application/json',
			if (token != null) 'Authorization': 'Bearer $token',
		};
	}

	Map<String, String> _buildMultipartHeaders(String? token) {
		return {
			if (token != null) 'Authorization': 'Bearer $token',
		};
	}
}
