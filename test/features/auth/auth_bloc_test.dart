import 'dart:async';
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

void main() {
	late SecureStorageEnMemoria storage;
	late AuthRepositoryImpl repo;
	late StreamController<void> sesionExpirada;

	final usuarioGuardado = jsonEncode({
		'id': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
		'fullName': 'Juan Perez',
		'email': 'tecnico@empresa.com',
		'roles': ['tecnico'],
	});

	String tokenVigente() => jwtConExpiracion(
				DateTime.now().toUtc().add(const Duration(hours: 8)),
			);

	setUp(() {
		storage = SecureStorageEnMemoria();
		sesionExpirada = StreamController<void>.broadcast();
		repo = AuthRepositoryImpl(
			ApiClient(MockClient((_) async => http.Response('{}', 500)), storage),
			storage,
		);
	});

	tearDown(() async {
		await sesionExpirada.close();
	});

	AuthBloc construirBloc() {
		return AuthBloc(
			LoginUseCase(repo),
			RestaurarSesionUseCase(repo),
			CerrarSesionUseCase(repo),
			sesionExpirada: sesionExpirada.stream,
		);
	}

	test('AppStarted con sesion guardada entra directo', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = usuarioGuardado;

		final bloc = construirBloc();
		final estados = expectLater(
			bloc.stream,
			emitsInOrder([
				isA<AuthLoading>(),
				isA<AuthAuthenticated>().having(
					(estado) => estado.usuario.email,
					'usuario.email',
					'tecnico@empresa.com',
				),
			]),
		);

		bloc.add(const AppStarted());
		await estados;
		await bloc.close();
	});

	test('AppStarted sin sesion guardada pide login', () async {
		final bloc = construirBloc();
		final estados = expectLater(
			bloc.stream,
			emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
		);

		bloc.add(const AppStarted());
		await estados;
		await bloc.close();
	});

	test('AppStarted con token vencido pide login y limpia el storage', () async {
		storage.valores['jwt_token'] = jwtConExpiracion(
			DateTime.now().toUtc().subtract(const Duration(hours: 1)),
		);
		storage.valores['usuario_sesion'] = usuarioGuardado;

		final bloc = construirBloc();
		final estados = expectLater(
			bloc.stream,
			emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
		);

		bloc.add(const AppStarted());
		await estados;

		expect(storage.valores, isEmpty);
		await bloc.close();
	});

	test('LogoutRequested limpia el storage y vuelve al login', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = usuarioGuardado;

		final bloc = construirBloc();
		bloc.add(const AppStarted());
		await bloc.stream.firstWhere((estado) => estado is AuthAuthenticated);

		final estados = expectLater(
			bloc.stream,
			emitsInOrder([isA<AuthUnauthenticated>()]),
		);

		bloc.add(const LogoutRequested());
		await estados;

		expect(storage.valores, isEmpty);
		await bloc.close();
	});

	test('un 401 del backend cierra la sesion y avisa', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = usuarioGuardado;

		final bloc = construirBloc();
		bloc.add(const AppStarted());
		await bloc.stream.firstWhere((estado) => estado is AuthAuthenticated);

		final estados = expectLater(
			bloc.stream,
			emitsInOrder([
				isA<AuthUnauthenticated>().having(
					(estado) => estado.mensaje,
					'mensaje',
					'Tu sesion expiro. Volve a ingresar.',
				),
			]),
		);

		sesionExpirada.add(null);
		await estados;

		expect(storage.valores, isEmpty);
		await bloc.close();
	});

	test('un 401 tardio sin sesion activa no emite nada', () async {
		final bloc = construirBloc();
		bloc.add(const AppStarted());
		await bloc.stream.firstWhere((estado) => estado is AuthUnauthenticated);

		final emitidos = <AuthState>[];
		final suscripcion = bloc.stream.listen(emitidos.add);

		sesionExpirada.add(null);
		await Future<void>.delayed(const Duration(milliseconds: 20));

		expect(emitidos, isEmpty);
		await suscripcion.cancel();
		await bloc.close();
	});
}
