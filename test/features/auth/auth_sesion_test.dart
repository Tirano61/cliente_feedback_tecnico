import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/jwt_de_prueba.dart';
import '../../support/secure_storage_en_memoria.dart';

void main() {
	late SecureStorageEnMemoria storage;
	late AuthRepositoryImpl repo;

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
		// Ninguna prueba de sesion toca la red: el restore es 100% local.
		final client = MockClient((_) async => http.Response('{}', 500));
		repo = AuthRepositoryImpl(ApiClient(client, storage), storage);
	});

	test('restaura la sesion cuando hay token vigente y usuario', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = usuarioGuardado;

		final usuario = await repo.obtenerSesionGuardada();

		expect(usuario, isNotNull);
		expect(usuario!.id, '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c');
		expect(usuario.fullName, 'Juan Perez');
		expect(usuario.email, 'tecnico@empresa.com');
		expect(usuario.roles, ['tecnico']);
		expect(storage.valores.keys, containsAll(['jwt_token', 'usuario_sesion']));
	});

	test('sin nada guardado devuelve null', () async {
		expect(await repo.obtenerSesionGuardada(), isNull);
	});

	test('token vencido: devuelve null y limpia las dos claves', () async {
		storage.valores['jwt_token'] = jwtConExpiracion(
			DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
		);
		storage.valores['usuario_sesion'] = usuarioGuardado;

		expect(await repo.obtenerSesionGuardada(), isNull);
		expect(storage.valores, isEmpty);
	});

	test('token sin usuario guardado: devuelve null y limpia', () async {
		storage.valores['jwt_token'] = tokenVigente();

		expect(await repo.obtenerSesionGuardada(), isNull);
		expect(storage.valores, isEmpty);
	});

	test('usuario sin token guardado: devuelve null y limpia', () async {
		storage.valores['usuario_sesion'] = usuarioGuardado;

		expect(await repo.obtenerSesionGuardada(), isNull);
		expect(storage.valores, isEmpty);
	});

	test('usuario ilegible: devuelve null y limpia', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = 'no-es-json';

		expect(await repo.obtenerSesionGuardada(), isNull);
		expect(storage.valores, isEmpty);
	});

	test('usuario sin id ni email: devuelve null y limpia', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = jsonEncode({'roles': ['tecnico']});

		expect(await repo.obtenerSesionGuardada(), isNull);
		expect(storage.valores, isEmpty);
	});

	test('logout borra el token Y el usuario', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = usuarioGuardado;

		await repo.logout();

		expect(storage.valores, isEmpty);
	});

	test('despues del logout no se revive la sesion', () async {
		storage.valores['jwt_token'] = tokenVigente();
		storage.valores['usuario_sesion'] = usuarioGuardado;

		await repo.logout();

		expect(await repo.obtenerSesionGuardada(), isNull);
	});
}
