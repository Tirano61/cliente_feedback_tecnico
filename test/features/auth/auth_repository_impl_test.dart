import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

void main() {
	late SecureStorageEnMemoria storage;

	setUp(() {
		storage = SecureStorageEnMemoria();
	});

	AuthRepositoryImpl construirRepo(MockClient client) {
		return AuthRepositoryImpl(ApiClient(client, storage), storage);
	}

	test('login parsea access_token y user, y persiste ambos', () async {
		late http.Request requestEnviada;
		final client = MockClient((request) async {
			requestEnviada = request;
			return http.Response(
				jsonEncode({
					'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc.def',
					'user': {
						'id': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
						'fullName': 'Juan Perez',
						'email': 'tecnico@empresa.com',
						'roles': ['tecnico'],
					},
				}),
				201,
				headers: {'content-type': 'application/json'},
			);
		});

		final usuario = await construirRepo(client).login(
			email: 'tecnico@empresa.com',
			password: 'Abc123',
		);

		expect(jsonDecode(requestEnviada.body), {
			'email': 'tecnico@empresa.com',
			'password': 'Abc123',
		});

		expect(usuario.id, '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c');
		expect(usuario.fullName, 'Juan Perez');
		expect(usuario.email, 'tecnico@empresa.com');
		expect(usuario.roles, ['tecnico']);

		expect(
			storage.valores['jwt_token'],
			'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc.def',
		);
		expect(jsonDecode(storage.valores['usuario_sesion']!), {
			'id': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
			'fullName': 'Juan Perez',
			'email': 'tecnico@empresa.com',
			'roles': ['tecnico'],
		});
	});

	test('login soporta varios roles', () async {
		final client = MockClient((request) async {
			return http.Response(
				jsonEncode({
					'access_token': 'token-multi-rol',
					'user': {
						'id': 'abc',
						'fullName': 'Ana Gomez',
						'email': 'ana@empresa.com',
						'roles': ['tecnico', 'admin-tecnico'],
					},
				}),
				200,
			);
		});

		final usuario = await construirRepo(client).login(
			email: 'ana@empresa.com',
			password: 'Abc123',
		);

		expect(usuario.roles, ['tecnico', 'admin-tecnico']);
	});

	test('el token guardado viaja como Bearer en la siguiente request', () async {
		String? authorizationRecibido;
		final client = MockClient((request) async {
			if (request.url.path.endsWith('/auth/login')) {
				return http.Response(
					jsonEncode({
						'access_token': 'token-de-sesion',
						'user': {
							'id': 'abc',
							'fullName': 'Juan Perez',
							'email': 'tecnico@empresa.com',
							'roles': ['tecnico'],
						},
					}),
					201,
				);
			}
			authorizationRecibido = request.headers['Authorization'];
			return http.Response('[]', 200);
		});

		final apiClient = ApiClient(client, storage);
		await AuthRepositoryImpl(apiClient, storage).login(
			email: 'tecnico@empresa.com',
			password: 'Abc123',
		);
		await apiClient.get('/servicios/mios');

		expect(authorizationRecibido, 'Bearer token-de-sesion');
	});

	test('401 del backend se mapea a AuthException con el mensaje real', () async {
		final client = MockClient((request) async {
			return http.Response(
				jsonEncode({
					'message': 'Credentials are not valid',
					'error': 'Unauthorized',
					'statusCode': 401,
				}),
				401,
			);
		});

		expect(
			() => construirRepo(client).login(
				email: 'tecnico@empresa.com',
				password: 'incorrecta',
			),
			throwsA(
				isA<AuthException>().having(
					(e) => e.mensaje,
					'mensaje',
					'Credentials are not valid',
				),
			),
		);
	});

	test('respuesta sin access_token falla y no guarda sesion', () async {
		final client = MockClient((request) async {
			return http.Response(jsonEncode({'token': 'shape-viejo'}), 201);
		});

		await expectLater(
			construirRepo(client).login(
				email: 'tecnico@empresa.com',
				password: 'Abc123',
			),
			throwsA(isA<ServerException>()),
		);
		expect(storage.valores, isEmpty);
	});

	test('respuesta sin user falla y no guarda sesion', () async {
		final client = MockClient((request) async {
			return http.Response(jsonEncode({'access_token': 'solo-token'}), 201);
		});

		await expectLater(
			construirRepo(client).login(
				email: 'tecnico@empresa.com',
				password: 'Abc123',
			),
			throwsA(isA<ServerException>()),
		);
		expect(storage.valores, isEmpty);
	});
}
