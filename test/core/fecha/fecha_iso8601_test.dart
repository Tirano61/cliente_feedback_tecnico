import 'package:cliente_feedback_tecnico/core/fecha/fecha_iso8601.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
	// 21:00:58.129 en Argentina es 00:00:58.129 del dia siguiente en UTC: el caso
	// que se corria tres horas cuando la fecha viajaba sin offset.
	final instante = DateTime.utc(2026, 10, 5, 0, 0, 58, 129);

	test('escribe la hora local de Argentina con offset -03:00', () {
		expect(
			fechaIso8601ConOffset(instante, utcOffsetMinutos: -180),
			'2026-10-04T21:00:58.129-03:00',
		);
	});

	test('el string vuelve a parsear al mismo instante', () {
		final texto = fechaIso8601ConOffset(instante, utcOffsetMinutos: -180);

		expect(DateTime.parse(texto).isAtSameMomentAs(instante), isTrue);
	});

	test('offset positivo, cero y con minutos', () {
		expect(
			fechaIso8601ConOffset(instante, utcOffsetMinutos: 0),
			'2026-10-05T00:00:58.129+00:00',
		);
		expect(
			fechaIso8601ConOffset(instante, utcOffsetMinutos: 330),
			'2026-10-05T05:30:58.129+05:30',
		);
		expect(
			fechaIso8601ConOffset(instante, utcOffsetMinutos: -570),
			'2026-10-04T14:30:58.129-09:30',
		);
	});

	test('sin offset explicito usa el del dispositivo y nunca omite la zona', () {
		final ahora = DateTime.now();
		final texto = fechaIso8601ConOffset(ahora);

		expect(texto, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2}$')));
		expect(texto.endsWith(_offsetComoTexto(ahora.timeZoneOffset.inMinutes)), isTrue);
		expect(
			DateTime.parse(texto).millisecondsSinceEpoch,
			ahora.millisecondsSinceEpoch,
		);
	});
}

String _offsetComoTexto(int minutos) {
	final signo = minutos < 0 ? '-' : '+';
	final absoluto = minutos.abs();
	return '$signo${(absoluto ~/ 60).toString().padLeft(2, '0')}:'
			'${(absoluto % 60).toString().padLeft(2, '0')}';
}
