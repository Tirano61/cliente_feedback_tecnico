import 'package:cliente_feedback_tecnico/core/auth/jwt_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/jwt_de_prueba.dart';

void main() {
	test('un token con exp futura esta vigente', () {
		final token = jwtConExpiracion(
			DateTime.now().toUtc().add(const Duration(hours: 2)),
		);

		expect(JwtHelper.estaVencido(token), isFalse);
	});

	test('un token con exp pasada esta vencido', () {
		final token = jwtConExpiracion(
			DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
		);

		expect(JwtHelper.estaVencido(token), isTrue);
	});

	test('el margen evita usar un token que vence en segundos', () {
		final token = jwtConExpiracion(
			DateTime.now().toUtc().add(const Duration(seconds: 5)),
		);

		expect(JwtHelper.estaVencido(token), isTrue);
	});

	test('un token ilegible se trata como vencido', () {
		expect(JwtHelper.estaVencido('no-es-un-jwt'), isTrue);
		expect(JwtHelper.estaVencido('a.b.c'), isTrue);
		expect(JwtHelper.estaVencido(''), isTrue);
	});

	test('un JWT sin exp queda a criterio del backend', () {
		expect(JwtHelper.estaVencido(jwtSinExpiracion()), isFalse);
		expect(JwtHelper.obtenerExpiracion(jwtSinExpiracion()), isNull);
	});

	test('obtenerExpiracion devuelve la fecha del claim exp', () {
		final esperada = DateTime.utc(2030, 1, 1, 12);

		expect(
			JwtHelper.obtenerExpiracion(jwtConExpiracion(esperada)),
			esperada,
		);
	});
}
