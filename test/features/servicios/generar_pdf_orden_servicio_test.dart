import 'dart:convert';
import 'dart:io';

import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

/// Textos con todo lo que puede aparecer en nombres de clientes, localidades
/// y texto libre del técnico.
const String _nombreCliente = 'Estancia La Ñandú — Peña & Muñoz S.R.L.';
const String _localidad = 'Pehuajó, Bs. As. (Coronel Suárez)';
const String _contacto = 'José Ángel Güemes';
const String _lugar = 'Campo «El Ombú», 2° tranquera';
const String _ubicacion = 'Cestari 14 — línea N° 3';
const String _sintoma = '¿No pesa? ¡Marca 0,0 kg! Pantalla “Err-1” al encender…';
const String _diagnostico = 'Celda dañada por humedad; cable pelado ½ m. 25 °C, 80 %.';
const String _observaciones = 'Pagó en €/US\$; dueño Ítalo Ñúñez. Ç ü ö ä ß ã õ ê ô ‘ok’ – fin';
const String _descripcionItem = 'Viático 120 km (ida y vuelta) · pañol';
const String _firmante = 'Íñigo Úrsula Pérez';

OrdenServicioRespuesta _ordenConAcentos() {
	return OrdenServicioRespuesta(
		replayed: false,
		servicioId: '11111111-1111-4111-8111-111111111111',
		idempotencyKey: '33333333-3333-4333-8333-333333333333',
		estadoOrden: 'cerrada',
		version: 1,
		fechaHoraServicio: DateTime.utc(2026, 10, 3, 15, 30),
		servicio: const Servicio(
			id: '11111111-1111-4111-8111-111111111111',
			canal: Canal.campo,
			clienteId: '22222222-2222-4222-8222-222222222222',
			clienteNombre: _nombreCliente,
			clienteCuit: '30-12345678-9',
			clienteTelefono: '+54 9 2396 45-6789',
			clienteLocalidad: _localidad,
			clienteContacto: _contacto,
			lugarProvinciaNombre: 'Córdoba',
			lugarDetalle: _lugar,
			equipoNroSerie: 'SN-Ñ900',
			equipoModelo: 'ST455',
			equipoUbicacion: _ubicacion,
			equipoAnio: 2019,
			partesFallaron: ['celda'],
			km: 120,
			sintoma: _sintoma,
			diagnosticoDetalle: _diagnostico,
			diagnosticoCatIds: ['cat-1'],
			resolucionIds: ['res-1'],
			observaciones: _observaciones,
		),
		facturacionItems: const [
			FacturacionItem(
				tipoItem: 'viatico',
				descripcion: _descripcionItem,
				cantidad: 120,
				precioUnitarioUsd: 0.5,
				precioUnitarioArs: 500,
				subtotalUsd: 60,
				subtotalArs: 60000,
			),
		],
	);
}

/// Cuenta cada intento de abrir una conexión HTTP y lo hace fallar.
class _RedProhibida extends HttpOverrides {
	int intentos = 0;

	@override
	HttpClient createHttpClient(SecurityContext? context) {
		intentos++;
		throw const SocketException('Sin conexión (test)');
	}
}

/// Junta los bytes crudos del PDF con el contenido descomprimido de cada
/// stream, para poder buscar los nombres de fuente aunque estén comprimidos.
String _contenidoLegible(Uint8List pdf) {
	final crudo = latin1.decode(pdf);
	final buffer = StringBuffer(crudo);
	final streams = RegExp(r'stream\r?\n').allMatches(crudo);
	for (final inicio in streams) {
		final fin = crudo.indexOf('endstream', inicio.end);
		if (fin < 0) {
			continue;
		}
		try {
			buffer.write(latin1.decode(zlib.decode(pdf.sublist(inicio.end, fin))));
		} on FormatException {
			// Stream no comprimido o binario sin zlib: ya está en los bytes crudos.
		}
	}
	return buffer.toString();
}

void main() {
	TestWidgetsFlutterBinding.ensureInitialized();

	test('genera el PDF sin ninguna petición de red', () async {
		final red = _RedProhibida();

		final pdf = await HttpOverrides.runZoned(
			() => GenerarPdfOrdenServicioUseCase().ejecutar(
				_ordenConAcentos(),
				firmaClienteNombre: _firmante,
				firmaClienteDocumento: '12.345.678',
				firmaFechaHora: DateTime.utc(2026, 10, 3, 16),
			),
			createHttpClient: red.createHttpClient,
		);

		expect(red.intentos, 0);
		expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
		if (Platform.environment['PDF_SALIDA'] case final ruta?) {
			File(ruta).writeAsBytesSync(pdf);
		}
	});

	test('embebe Noto Sans del bundle y no cae a Helvetica', () async {
		final pdf = await GenerarPdfOrdenServicioUseCase().ejecutar(_ordenConAcentos());
		final contenido = _contenidoLegible(pdf);

		expect(contenido, contains('NotoSans'));
		expect(contenido, contains('/FontFile2'));
		expect(contenido, isNot(contains('Helvetica')));
	});

	test('la fuente embebida cubre todos los caracteres de la orden', () async {
		final textos = [
			_nombreCliente,
			_localidad,
			_contacto,
			_lugar,
			_ubicacion,
			_sintoma,
			_diagnostico,
			_observaciones,
			_descripcionItem,
			_firmante,
			'Córdoba',
			'SN-Ñ900',
			// Alfabeto español completo y signos habituales.
			'ABCDEFGHIJKLMNÑOPQRSTUVWXYZabcdefghijklmnñopqrstuvwxyz',
			'áéíóúÁÉÍÓÚüÜñÑ¿¡ºª°«»“”‘’–—…·€\$%&@#/\\()[]{}+-=*_.,;:!?\'"0123456789',
		];

		for (final ruta in [
			GenerarPdfOrdenServicioUseCase.rutaFuenteBase,
			GenerarPdfOrdenServicioUseCase.rutaFuenteNegrita,
		]) {
			final fuente = TtfParser(await rootBundle.load(ruta));
			final faltantes = {
				for (final texto in textos)
					for (final caracter in texto.runes)
						if ((fuente.charToGlyphIndexMap[caracter] ?? 0) == 0)
							String.fromCharCode(caracter),
			};
			expect(faltantes, isEmpty, reason: '$ruta no tiene glifos para $faltantes');
		}
	});
}
