import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

void main() {
	late SecureStorageEnMemoria storage;

	setUp(() {
		storage = SecureStorageEnMemoria();
	});

	test('un 401 en una llamada normal avisa que la sesion expiro', () async {
		final apiClient = ApiClient(
			MockClient((_) async => http.Response('{"message":"Unauthorized"}', 401)),
			storage,
		);

		final aviso = expectLater(apiClient.sesionExpirada, emits(anything));
		await apiClient.get(ApiConstants.serviciosMios);

		await aviso;
	});

	test('el 401 del login no dispara sesion expirada', () async {
		final apiClient = ApiClient(
			MockClient((_) async => http.Response('{"message":"Unauthorized"}', 401)),
			storage,
		);

		var avisos = 0;
		final suscripcion = apiClient.sesionExpirada.listen((_) => avisos++);

		await apiClient.post(ApiConstants.login, {
			'email': 'tecnico@empresa.com',
			'password': 'incorrecta',
		});
		await Future<void>.delayed(Duration.zero);

		expect(avisos, 0);
		await suscripcion.cancel();
	});

	test('una respuesta OK no dispara sesion expirada', () async {
		final apiClient = ApiClient(
			MockClient((_) async => http.Response('[]', 200)),
			storage,
		);

		var avisos = 0;
		final suscripcion = apiClient.sesionExpirada.listen((_) => avisos++);

		await apiClient.get(ApiConstants.serviciosMios);
		await Future<void>.delayed(Duration.zero);

		expect(avisos, 0);
		await suscripcion.cancel();
	});
}
