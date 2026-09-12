import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/dtos/login_response_dto.dart';

class AuthRepositoryImpl implements IAuthRepository {
	final ApiClient _apiClient;
	final SecureStorage _secureStorage;

	AuthRepositoryImpl(this._apiClient, this._secureStorage);

	@override
	Future<Usuario> login({required String email, required String password}) async {
		try {
			final response = await _apiClient.post(ApiConstants.login, {
				'email': email,
				'password': password,
			});

			if (response.statusCode == 200 || response.statusCode == 201) {
				final dynamic json = jsonDecode(response.body);

				if (json is! Map<String, dynamic>) {
					throw const ServerException('Respuesta de login invalida.');
				}

				if (json['access_token'] == null ||
						json['access_token'].toString().isEmpty) {
					throw const ServerException(
						'La respuesta de login no trae access_token.',
					);
				}

				if (json['user'] is! Map<String, dynamic>) {
					throw const ServerException(
						'La respuesta de login no trae los datos del usuario.',
					);
				}

				final loginResponse = LoginResponseDto.fromJson(json);

				await _secureStorage.guardarToken(loginResponse.accessToken);
				await _secureStorage.guardarUsuario(
					jsonEncode(loginResponse.usuario.toJson()),
				);

				return loginResponse.usuario;
			}

			if (response.statusCode == 401) {
				final dynamic json = jsonDecode(response.body);
				final mensaje =
						json is Map<String, dynamic> ? json['message']?.toString() : null;
				throw AuthException(mensaje ?? 'Credenciales invalidas.');
			}

			throw ServerException(
				'No se pudo iniciar sesion.',
				statusCode: response.statusCode,
			);
		} catch (error) {
			if (error is AuthException || error is ServerException) {
				rethrow;
			}
			throw const ServerException('Error de red al iniciar sesion.');
		}
	}

	@override
	Future<void> logout() async {
		return;
	}
}
