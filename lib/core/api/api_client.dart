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

	Map<String, String> _buildHeaders(String? token) {
		return {
			'Content-Type': 'application/json',
			if (token != null) 'Authorization': 'Bearer $token',
		};
	}
}
