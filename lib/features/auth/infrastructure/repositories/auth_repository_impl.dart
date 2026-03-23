import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/dtos/usuario_dto.dart';

class AuthRepositoryImpl implements IAuthRepository {
	final ApiClient _apiClient;

	AuthRepositoryImpl(this._apiClient);

	@override
	Future<Usuario> login({required String email, required String password}) async {
		try {
			final response = await _apiClient.post(ApiConstants.login, {
				'email': email,
				'password': password,
			});

			if (response.statusCode == 200 || response.statusCode == 201) {
				final dynamic json = jsonDecode(response.body);

				if (json is Map<String, dynamic> && json['usuario'] is Map<String, dynamic>) {
					return UsuarioDto.fromJson(json['usuario'] as Map<String, dynamic>);
				}

				return UsuarioDto(
					id: '',
					nombre: 'Tecnico',
					email: email,
					rol: 'tecnico',
				);
			}

			if (response.statusCode == 401) {
				throw const AuthException('Credenciales invalidas.');
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
