import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/cerrar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/restaurar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/jwt_de_prueba.dart';
import '../../support/secure_storage_en_memoria.dart';

/// Ciclo completo: login -> cerrar la app -> reabrir -> logout -> reabrir.
///
/// El storage sobrevive a los tres AuthBloc, igual que el secure storage
/// sobrevive a que el tecnico cierre y reabra la app.
void main() {
	test('el tecnico se loguea una vez y vuelve a entrar directo', () async {
		final storage = SecureStorageEnMemoria();
		final token = jwtConExpiracion(
			DateTime.now().toUtc().add(const Duration(hours: 8)),
		);

		final client = MockClient((request) async {
			if (request.url.path.endsWith('/auth/login')) {
				return http.Response(
					jsonEncode({
						'access_token': token,
						'user': {
							'id': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
							'fullName': 'Juan Perez',
							'email': 'tecnico@empresa.com',
							'roles': ['tecnico'],
						},
					}),
					201,
				);
			}
			return http.Response('[]', 200);
		});

		final repo = AuthRepositoryImpl(ApiClient(client, storage), storage);
		AuthBloc abrirApp() => AuthBloc(
					LoginUseCase(repo),
					RestaurarSesionUseCase(repo),
					CerrarSesionUseCase(repo),
				);

		// 1. Login.
		final primeraApertura = abrirApp();
		primeraApertura.add(
			const LoginSubmitted(
				email: 'tecnico@empresa.com',
				password: 'Abc123',
			),
		);
		final logueado = await primeraApertura.stream.firstWhere(
			(estado) => estado is AuthAuthenticated,
		);
		expect((logueado as AuthAuthenticated).usuario.email, 'tecnico@empresa.com');
		expect(storage.valores.keys, containsAll(['jwt_token', 'usuario_sesion']));

		// 2. Cerrar la app.
		await primeraApertura.close();

		// 3. Reabrir: entra directo, pasando por el splash.
		final segundaApertura = abrirApp();
		final restaurando = expectLater(
			segundaApertura.stream,
			emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
		);
		segundaApertura.add(const AppStarted());
		await restaurando;

		// 4. Logout.
		segundaApertura.add(const LogoutRequested());
		await segundaApertura.stream.firstWhere(
			(estado) => estado is AuthUnauthenticated,
		);
		expect(storage.valores, isEmpty);
		await segundaApertura.close();

		// 5. Reabrir: ahora pide login.
		final terceraApertura = abrirApp();
		final pidiendoLogin = expectLater(
			terceraApertura.stream,
			emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
		);
		terceraApertura.add(const AppStarted());
		await pidiendoLogin;
		await terceraApertura.close();
	});
}
