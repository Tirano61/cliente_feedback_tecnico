import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/descargar_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/encolar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_documentos_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_enlace_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/quitar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/subir_documento_firmado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _zonaId = '33333333-3333-4333-8333-333333333333';
const String _diagnosticoUnoId = '44444444-4444-4444-8444-444444444444';
const String _diagnosticoDosId = '55555555-5555-4555-8555-555555555555';
const String _resolucionUnaId = '66666666-6666-4666-8666-666666666666';
const String _resolucionOtraId = '77777777-7777-4777-8777-777777777777';
const String _productoId = '88888888-8888-4888-8888-888888888888';

/// Respuesta minima de POST /servicios: al bloc le alcanza para cerrar el
/// flujo, lo que miran estos tests es el body que viajo.
final Map<String, dynamic> _respuestaAlta = {
	'replayed': false,
	'servicioId': '99999999-9999-4999-8999-999999999999',
	'idempotencyKey': '2f7b4d37-2f7f-4b0f-b2f0-1f9d9d1a7a1f',
	'estadoOrden': 'cerrada',
	'version': 1,
	'servicio': {'canal': 'campo', 'clienteId': _clienteId},
};

/// Completa el formulario por el evento real, guarda y devuelve el body del
/// POST /servicios tal como lo recibe el backend.
Future<Map<String, dynamic>> _guardarOrden({
	required Canal canal,
	List<String> resoluciones = const [_resolucionUnaId],
	String parteFallo = 'Indicador',
}) async {
	Map<String, dynamic>? bodyEnviado;

	final storage = SecureStorageEnMemoria();
	final apiClient = ApiClient(
		MockClient((request) async {
			if (request.method == 'POST' && request.url.path.endsWith('/servicios')) {
				bodyEnviado = jsonDecode(request.body) as Map<String, dynamic>;
				return http.Response(jsonEncode(_respuestaAlta), 201);
			}
			return http.Response('{}', 404);
		}),
		storage,
	);
	final repositorio = ServicioRepositoryImpl(apiClient, storage);
	final bloc = ServicioBloc(
		CargarServicioUseCase(repositorio),
		ObtenerMisServiciosUseCase(repositorio),
		BuscarClientesUseCase(repositorio),
		CrearClienteRapidoUseCase(repositorio),
		ObtenerCotizacionActualUseCase(repositorio),
		BuscarRepuestosUseCase(repositorio),
		GenerarPdfOrdenServicioUseCase(),
		SubirDocumentoFirmadoUseCase(repositorio),
		EncolarDocumentoPendienteUseCase(repositorio),
		ObtenerDocumentosPendientesUseCase(repositorio),
		QuitarDocumentoPendienteUseCase(repositorio),
		ObtenerEnlacePdfDocumentoUseCase(repositorio),
		DescargarPdfDocumentoUseCase(repositorio),
	);

	// El tecnico carga los mismos datos en los tres canales: es el bloc el que
	// decide que provincia, lugar y km solo aplican en campo.
	bloc.add(
		ServicioFormularioCambiado(
			canal: canal,
			clienteId: _clienteId,
			zonaId: _zonaId,
			lugarDetalle: 'Cestari 14',
			km: '120',
			equipoNroSerie: 'SN-001',
			equipoModelo: 'ST455',
			equipoUbicacion: 'Tolva principal',
			equipoAnio: '2021',
			precioServicioUsd: '80',
			sintoma: 'No inicia',
			diagnosticoDetalle: 'Fuente sin salida',
			diagnosticoCatIdsSeleccionados: const [_diagnosticoUnoId, _diagnosticoDosId],
			resolucionIdsSeleccionados: resoluciones,
			partesFallaronTexto: parteFallo,
			productosFallaSeleccionados: [
				ProductoFalla(parteFallo: parteFallo, productoFallaId: _productoId),
			],
		),
	);

	final cerrado = bloc.stream.firstWhere(
		(estado) =>
			estado is ServicioFormularioState &&
			(estado.exitoMensaje != null || estado.errorMensaje != null),
	);
	bloc.add(const ServicioGuardarPressed());
	final estadoFinal = await cerrado as ServicioFormularioState;

	await bloc.close();
	await apiClient.dispose();

	expect(
		estadoFinal.errorMensaje,
		isNull,
		reason: 'la orden de canal ${canal.name} no llego a guardarse',
	);
	expect(bodyEnviado, isNotNull, reason: 'no se hizo el POST /servicios');
	return bodyEnviado!;
}

void main() {
	// El alta genera el PDF de la orden: sin binding el cargador de fuentes
	// ensucia la salida del test.
	TestWidgetsFlutterBinding.ensureInitialized();

	group('arrays del contrato', () {
		test('resolucionId viaja con todas las resoluciones elegidas', () async {
			final body = await _guardarOrden(
				canal: Canal.campo,
				resoluciones: const [_resolucionUnaId, _resolucionOtraId],
			);

			expect(body['resolucionId'], [_resolucionUnaId, _resolucionOtraId]);
		});

		test('diagnosticoCatId y partesFallaron tambien viajan como array', () async {
			final body = await _guardarOrden(canal: Canal.campo);

			expect(body['diagnosticoCatId'], [_diagnosticoUnoId, _diagnosticoDosId]);
			expect(body['partesFallaron'], ['indicador']);
		});
	});

	group('partes que fallaron', () {
		test('la parte web viaja como web y no como app_pc', () async {
			final body = await _guardarOrden(canal: Canal.campo, parteFallo: 'Web');

			expect(body['partesFallaron'], ['web']);
			expect(
				(body['productosFalla'] as List).single,
				{'parteFallo': 'web', 'productoFallaId': _productoId},
			);
		});

		test('la app de PC sigue mapeando a app_pc', () async {
			final body = await _guardarOrden(canal: Canal.campo, parteFallo: 'App PC');

			expect(body['partesFallaron'], ['app_pc']);
		});
	});

	group('reglas por canal', () {
		test('campo manda provincia, lugar y km', () async {
			final body = await _guardarOrden(canal: Canal.campo);

			expect(body['lugarProvinciaId'], _zonaId);
			expect(body['lugarDetalle'], 'Cestari 14');
			expect(body['km'], 120);
		});

		test('remoto guarda sin provincia, lugar ni km', () async {
			final body = await _guardarOrden(canal: Canal.remoto);

			expect(body.containsKey('lugarProvinciaId'), isFalse);
			expect(body.containsKey('lugarDetalle'), isFalse);
			expect(body.containsKey('km'), isFalse);
		});

		test('fabrica guarda sin provincia, lugar ni km', () async {
			final body = await _guardarOrden(canal: Canal.fabrica);

			expect(body.containsKey('lugarProvinciaId'), isFalse);
			expect(body.containsKey('lugarDetalle'), isFalse);
			expect(body.containsKey('km'), isFalse);
		});

		test('remoto no factura viatico por km', () async {
			final body = await _guardarOrden(canal: Canal.remoto);
			final tipos = (body['facturacionItems'] as List)
					.map((item) => (item as Map<String, dynamic>)['tipoItem'])
					.toList();

			expect(tipos, contains('mano_obra'));
			expect(tipos, isNot(contains('viatico')));
		});
	});
}
