import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
	final http.Client _client;
	final SecureStorage _storage;

	ApiClient(this._client, this._storage);

	Future<http.Response> get(String path) async {
		final token = await _storage.obtenerToken();
		return _client.get(
			Uri.parse('${ApiConstants.baseUrl}$path'),
			headers: _buildHeaders(token),
		);
	}

	Future<http.Response> post(String path, Map<String, dynamic> body) async {
		final token = await _storage.obtenerToken();
		return _client.post(
			Uri.parse('${ApiConstants.baseUrl}$path'),
			headers: _buildHeaders(token),
			body: jsonEncode(body),
		);
	}

	Future<http.Response> patch(String path, Map<String, dynamic> body) async {
		final token = await _storage.obtenerToken();
		return _client.patch(
			Uri.parse('${ApiConstants.baseUrl}$path'),
			headers: _buildHeaders(token),
			body: jsonEncode(body),
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
		return http.Response.fromStream(streamed);
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
