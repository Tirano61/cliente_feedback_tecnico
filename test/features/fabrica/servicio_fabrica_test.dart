import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cambiar_estado_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/devolver_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_servicio_vinculado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_vinculaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/vincular_servicio_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/vinculacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/servicio_fabrica_bloc.dart';
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
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/precarga_formulario_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _recepcionId = '33333333-3333-4333-8333-333333333333';
const String _otraRecepcionId = '34343434-3434-4343-8343-343434343434';
const String _indicadorId = '44444444-4444-4444-8444-444444444444';
const String _tecnicoId = '77777777-7777-4777-8777-777777777777';
const String _productoIndicadorId = '88888888-8888-4888-8888-888888888888';
const String _diagnosticoId = '45454545-4545-4545-8545-454545454545';
const String _resolucionId = '66666666-6666-4666-8666-666666666666';
const String _productoFallaId = '99999999-9999-4999-8999-999999999999';
const String _servicioId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

// Respuesta de la seccion Fabrica de docs/endpoints.md.
Map<String, dynamic> _recepcionJson({
	String id = _recepcionId,
	int numero = 154,
	String estado = 'en_reparacion',
	String? servicioId,
}) =>
		{
			'id': id,
			'numero': numero,
			'cliente': {'id': _clienteId, 'nombre': 'Agro SRL', 'cuit': '20304050607'},
			'indicadorId': _indicadorId,
			'indicador': {
				'id': _indicadorId,
				'tipo': 'indicador',
				'nroSerie': 'IND-1001',
				'estado': 'en_servicio_tecnico',
				'producto': {'id': _productoIndicadorId, 'nombre': 'ST455', 'version': null},
			},
			'queLlego': 'Indicador completo con cable de celdas',
			'sintomaReportado': 'No enciende',
			'tecnicoRecepcion': {'id': _tecnicoId, 'fullName': 'Juan Tecnico'},
			'fechaRecepcion': '2026-10-24T13:00:00.000Z',
			'estado': estado,
			'historialEstados': [
				{
					'estado': 'recibido',
					'fecha': '2026-10-24T13:00:00.000Z',
					'usuarioId': _tecnicoId,
					'usuarioNombre': 'Juan Tecnico',
					'observacion': null,
				},
			],
			'servicioId': servicioId,
			'fechaDevolucion': null,
			'formaDevolucion': null,
			'observaciones': null,
			'ingresos': [],
			'piezasInstaladas': [],
		};

// Respuesta de POST /servicios (la que usa la app para el PDF).
final Map<String, dynamic> _ordenCreada = {
	'replayed': false,
	'servicioId': _servicioId,
	'idempotencyKey': '2f7b4d37-2f7f-4b0f-b2f0-1f9d9d1a7a1f',
	'estadoOrden': 'cerrada',
	'version': 1,
	'servicio': {'canal': 'fabrica', 'clienteId': _clienteId},
};

// GET /servicios/:id: el servicio con sus relaciones (tecnico, diagnosticoCat
// y resolucion como listas de { id, nombre }).
Map<String, dynamic> _servicioJson() => {
			'id': _servicioId,
			'canal': 'fabrica',
			'fecha': '2026-10-25T12:00:00.000Z',
			'fechaHoraServicio': '2026-10-25T09:30:00.000Z',
			'clienteId': _clienteId,
			'equipoNroSerie': 'IND-1001',
			'sintoma': 'No enciende',
			'diagnosticoDetalle': 'Fuente sin salida de 5 V',
			'estadoOrden': 'cerrada',
			'tecnico': {
				'id': _tecnicoId,
				'email': 'tecnico@empresa.com',
				'fullName': 'Juan Tecnico',
				'roles': ['tecnico'],
			},
			'diagnosticoCat': [
				{'id': _diagnosticoId, 'nombre': 'Fuente', 'activo': true},
			],
			'resolucion': [
				{'id': _resolucionId, 'nombre': 'Cambio de fuente', 'activo': true},
				{'id': '67676767-6767-4767-8767-676767676767', 'nombre': 'Prueba 24 h', 'activo': true},
			],
			'cliente': {'id': _clienteId, 'cuit': '20304050607', 'nombre': 'Agro SRL'},
			'aprobado': false,
		};

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

http.Response _regla(int status, String codigo, String mensaje) {
	return _json({
		'statusCode': status,
		'error': status == 409 ? 'Conflict' : 'Bad Request',
		'codigo': codigo,
		'mensaje': mensaje,
		'message': mensaje,
	}, status);
}

/// Backend simulado: `responder` decide por request; cotizacion y tarifa
/// siempre responden. Guarda cada request (salvo esas dos).
///
/// El resumen del servicio vinculado (`GET /servicios/:id`) lo responde
/// `responderServicio` y queda aparte, en `consultasServicio`.
///
/// Con `storage` de otro backend simula volver a abrir la app en el mismo
/// dispositivo.
class _Backend {
	http.Response Function(http.Request request) responder;
	http.Response Function(http.Request request) responderServicio = (_) => _json(_servicioJson());
	final List<http.Request> requests = [];
	final List<http.Request> consultasServicio = [];
	late final SecureStorageEnMemoria storage;
	late final ApiClient apiClient;
	late final FabricaRepositoryImpl fabrica;
	late final ServicioRepositoryImpl servicios;

	_Backend(this.responder, {SecureStorageEnMemoria? storage}) {
		this.storage = storage ?? (SecureStorageEnMemoria()..valores['jwt_token'] = 'token');
		apiClient = ApiClient(
			MockClient((request) async {
				final path = request.url.path;
				if (request.method == 'GET' && path.endsWith('/cotizacion')) {
					return _json({'valor': 1500});
				}
				if (request.method == 'GET' && path.endsWith('/tarifa-km')) {
					return _json({'valorKmUsd': 0.75});
				}
				if (request.method == 'GET' && path.endsWith('/servicios/$_servicioId')) {
					consultasServicio.add(request);
					return responderServicio(request);
				}
				requests.add(request);
				return responder(request);
			}),
			this.storage,
		);
		fabrica = FabricaRepositoryImpl(apiClient, this.storage);
		servicios = ServicioRepositoryImpl(apiClient, this.storage);
	}

	List<http.Request> de(String metodo, String sufijo) => requests
			.where((r) => r.method == metodo && r.url.path.endsWith(sufijo))
			.toList();

	Map<String, dynamic> body(http.Request request) =>
			jsonDecode(request.body) as Map<String, dynamic>;

	Future<void> cerrar() => apiClient.dispose();
}

ServicioFabricaBloc _servicioBloc(_Backend backend) {
	final repositorio = backend.servicios;
	return ServicioFabricaBloc(
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
}

RecepcionDetalleBloc _detalleBloc(_Backend backend) {
	return RecepcionDetalleBloc(
		ObtenerRecepcionUseCase(backend.fabrica),
		CambiarEstadoRecepcionUseCase(backend.fabrica),
		DevolverRecepcionUseCase(backend.fabrica),
		VincularServicioRecepcionUseCase(backend.fabrica),
		ObtenerServicioVinculadoUseCase(backend.fabrica),
		GuardarVinculacionPendienteUseCase(backend.fabrica),
		ObtenerVinculacionesPendientesUseCase(backend.fabrica),
		QuitarVinculacionPendienteUseCase(backend.fabrica),
		ahora: () => DateTime(2026, 10, 27, 10),
	);
}

const PrecargaFormularioServicio _precarga = PrecargaFormularioServicio(
	canal: Canal.fabrica,
	cliente: Cliente(id: _clienteId, nombre: 'Agro SRL', cuit: '20304050607'),
	equipoNroSerie: 'IND-1001',
	equipoModelo: 'ST455',
	equipoModeloProductoId: _productoIndicadorId,
	sintoma: 'No enciende',
);

void main() {
	// El alta genera el PDF de la orden: sin binding el cargador de fuentes
	// ensucia la salida del test.
	TestWidgetsFlutterBinding.ensureInitialized();

	group('formulario de servicio abierto desde la recepcion', () {
		late _Backend backend;
		late ServicioBloc bloc;

		setUp(() {
			backend = _Backend((request) {
				if (request.method == 'POST' && request.url.path.endsWith('/servicios')) {
					return _json(_ordenCreada, 201);
				}
				return _json({}, 404);
			});
			bloc = _servicioBloc(backend);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<ServicioFormularioState> reiniciar({PrecargaFormularioServicio? precarga}) async {
			final listo = bloc.stream.firstWhere(
				(s) => s is ServicioFormularioState && s.cotizacionDolarSnapshot > 0 && !s.cargandoFacturacion,
			);
			bloc.add(ServicioFormularioReiniciado(precarga: precarga));
			return await listo as ServicioFormularioState;
		}

		ServicioFormularioState estado() => bloc.state as ServicioFormularioState;

		test('arranca con canal fabrica fijo, el cliente, el indicador y el sintoma', () async {
			final inicial = await reiniciar(precarga: _precarga);

			expect(inicial.canal, Canal.fabrica);
			expect(inicial.canalFijo, isTrue);
			expect(inicial.clienteId, _clienteId);
			expect(inicial.clienteSeleccionado!.nombre, 'Agro SRL');
			expect(inicial.equipoNroSerie, 'IND-1001');
			expect(inicial.equipoModelo, 'ST455');
			expect(inicial.sintoma, 'No enciende');
		});

		test('el canal fijo no se puede cambiar; el resto si', () async {
			await reiniciar(precarga: _precarga);

			bloc.add(const ServicioFormularioCambiado(canal: Canal.campo, sintoma: 'No enciende ni carga'));
			await Future<void>.delayed(Duration.zero);

			expect(estado().canal, Canal.fabrica);
			expect(estado().requiereDatosDeCampo, isFalse);
			expect(estado().sintoma, 'No enciende ni carga');
		});

		test('sin precarga el formulario queda como siempre, con el canal libre', () async {
			await reiniciar(precarga: _precarga);

			final vacio = await reiniciar();

			expect(vacio.canalFijo, isFalse);
			expect(vacio.canal, isNull);
			expect(vacio.clienteId, isEmpty);
			expect(vacio.equipoNroSerie, isEmpty);
		});

		test('guarda un servicio de canal fabrica con los datos de la recepcion', () async {
			await reiniciar(precarga: _precarga);
			bloc.add(
				ServicioFormularioCambiado(
					equipoUbicacion: 'Taller',
					equipoAnio: '2021',
					precioServicioUsd: '50',
					diagnosticoDetalle: 'Fuente sin salida',
					diagnosticoCatIdsSeleccionados: const [_diagnosticoId],
					resolucionIdsSeleccionados: const [_resolucionId],
					partesFallaronTexto: 'indicador',
					productosFallaSeleccionados: [
						ProductoFalla(parteFallo: 'indicador', productoFallaId: _productoFallaId),
					],
				),
			);
			await Future<void>.delayed(Duration.zero);

			final guardado = bloc.stream.firstWhere(
				(s) => s is ServicioFormularioState && s.ordenActual != null,
			);
			bloc.add(const ServicioGuardarPressed());
			final resultado = await guardado as ServicioFormularioState;

			final body = backend.body(backend.de('POST', '/servicios').single);
			expect(body['canal'], 'fabrica');
			expect(body['clienteId'], _clienteId);
			expect(body['equipoNroSerie'], 'IND-1001');
			expect(body['equipoModelo'], 'ST455');
			expect(body['sintoma'], 'No enciende');
			expect(body.containsKey('km'), isFalse);
			expect(body.containsKey('lugarProvinciaId'), isFalse);
			expect(resultado.ordenActual!.servicioId, _servicioId);
		});
	});

	group('vinculacion del servicio con la recepcion', () {
		late _Backend backend;
		late RecepcionDetalleBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_recepcionJson()));
			bloc = _detalleBloc(backend);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<RecepcionDetalleState> abrir(String recepcionId) async {
			final listo = bloc.stream.firstWhere(
				(s) => s.recepcionId == recepcionId && !s.cargando && s.recepcion != null,
			);
			bloc.add(RecepcionDetalleAbierto(recepcionId: recepcionId));
			return listo;
		}

		Future<RecepcionDetalleState> vincular(RecepcionDetalleEvent evento) {
			final listo = bloc.stream.firstWhere(
				(s) => !s.vinculando && (s.errorVinculacion != null || s.exitoMensaje != null),
			);
			bloc.add(evento);
			return listo;
		}

		test('sin servicio ofrece cargarlo, precargado con los datos de la recepcion', () async {
			final estado = await abrir(_recepcionId);

			expect(estado.puedeCargarServicio, isTrue);
			expect(estado.servicioVinculadoId, isNull);
			expect(estado.precargaServicio, _precarga);
		});

		test('con servicio vinculado lo muestra y no ofrece cargar otro', () async {
			backend.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));

			final estado = await abrir(_recepcionId);

			expect(estado.servicioVinculadoId, _servicioId);
			expect(estado.puedeCargarServicio, isFalse);
		});

		test('una recepcion devuelta no ofrece cargar servicio', () async {
			backend.responder = (_) => _json(_recepcionJson(estado: 'devuelto'));

			final estado = await abrir(_recepcionId);

			expect(estado.puedeCargarServicio, isFalse);
		});

		test('al guardar el servicio lo vincula con PATCH y muestra la recepcion actualizada', () async {
			await abrir(_recepcionId);
			backend.requests.clear();
			backend.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));

			final estado = await vincular(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			final request = backend.requests.single;
			expect(request.method, 'PATCH');
			expect(request.url.path, endsWith('/fabrica/recepciones/$_recepcionId/servicio'));
			expect(backend.body(request), {'servicioId': _servicioId});
			expect(estado.servicioVinculadoId, _servicioId);
			expect(estado.servicioPorVincular, isNull);
			expect(estado.puedeCargarServicio, isFalse);
			expect(estado.exitoMensaje, 'Servicio de fábrica vinculado a la recepción.');
			// Ya tiene servicio: listo para devolver deja de estar bloqueado.
			expect(
				estado.accionesEstado
						.firstWhere((a) => a.destino == EstadoRecepcion.listoParaDevolver)
						.habilitada,
				isTrue,
			);
		});

		test('si la vinculacion falla conserva el servicio y reintenta con el mismo, sin crear otro', () async {
			await abrir(_recepcionId);
			backend.requests.clear();
			backend.responder = (_) => _json({'message': 'Error interno'}, 500);

			final fallo = await vincular(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			expect(fallo.servicioPorVincular, _servicioId);
			expect(fallo.errorVinculacion, 'Error interno');
			expect(fallo.puedeCargarServicio, isFalse);
			expect(fallo.puedeReintentarVinculacion, isTrue);
			expect(fallo.servicioVinculadoId, isNull);

			backend.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));
			final reintento = await vincular(const RecepcionVinculacionReintentada());

			final patches = backend.de('PATCH', '/fabrica/recepciones/$_recepcionId/servicio');
			expect(patches, hasLength(2));
			expect(patches.map(backend.body), everyElement({'servicioId': _servicioId}));
			expect(backend.de('POST', '/servicios'), isEmpty);
			expect(reintento.servicioVinculadoId, _servicioId);
			expect(reintento.servicioPorVincular, isNull);
			expect(reintento.errorVinculacion, isNull);
		});

		test('sin conexion tambien queda para reintentar', () async {
			await abrir(_recepcionId);
			backend.responder = (_) => throw http.ClientException('sin red');

			final fallo = await vincular(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			expect(fallo.servicioPorVincular, _servicioId);
			expect(fallo.errorVinculacion, isNotNull);
			expect(fallo.puedeCargarServicio, isFalse);
		});

		test('el servicio sin vincular sigue pendiente al volver a abrir la recepcion', () async {
			await abrir(_recepcionId);
			backend.responder = (_) => _json({'message': 'Error interno'}, 500);
			await vincular(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			backend.responder = (request) => _json(
						_recepcionJson(
							id: request.url.path.endsWith(_otraRecepcionId) ? _otraRecepcionId : _recepcionId,
						),
					);
			final otra = await abrir(_otraRecepcionId);
			expect(otra.servicioPorVincular, isNull);
			expect(otra.puedeCargarServicio, isTrue);

			final deNuevo = await abrir(_recepcionId);
			expect(deNuevo.servicioPorVincular, _servicioId);
			expect(deNuevo.puedeCargarServicio, isFalse);
			expect(deNuevo.puedeReintentarVinculacion, isTrue);
		});

		test('si al recargar la recepcion ya tiene el servicio, deja de estar pendiente', () async {
			await abrir(_recepcionId);
			backend.responder = (_) => _json({'message': 'Error interno'}, 500);
			await vincular(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			// La vinculacion llego al backend aunque la respuesta se perdio.
			backend.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));
			final recargada = bloc.stream.firstWhere((s) => !s.cargando && s.servicioVinculadoId != null);
			bloc.add(const RecepcionDetalleRefrescado());
			final estado = await recargada;

			expect(estado.servicioPorVincular, isNull);
			expect(estado.errorVinculacion, isNull);
			expect(estado.puedeReintentarVinculacion, isFalse);
		});

		test('regla rechazada: mensaje tal cual, conserva el servicio y vuelve a pedir la recepcion', () async {
			await abrir(_recepcionId);
			backend.requests.clear();
			const mensaje = 'El servicio ya está vinculado a la recepción 120.';
			backend.responder = (request) => request.method == 'PATCH'
					? _regla(409, 'SERVICIO_YA_VINCULADO', mensaje)
					: _json(_recepcionJson());

			final fallo = await vincular(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);
			final recargada = await bloc.stream.firstWhere((s) => !s.cargando);

			expect(fallo.errorVinculacion, mensaje);
			expect(backend.de('GET', '/fabrica/recepciones/$_recepcionId'), hasLength(1));
			expect(recargada.servicioPorVincular, _servicioId);
			expect(recargada.errorVinculacion, mensaje);
		});

		test('servicio guardado y vinculado de punta a punta: un solo POST y un PATCH', () async {
			final servicioBloc = _servicioBloc(backend);
			addTearDown(servicioBloc.close);
			await abrir(_recepcionId);
			backend.requests.clear();
			backend.responder = (request) {
				if (request.method == 'POST') {
					return _json(_ordenCreada, 201);
				}
				return _json(_recepcionJson(servicioId: _servicioId));
			};

			final listoFormulario = servicioBloc.stream.firstWhere(
				(s) => s is ServicioFormularioState && s.cotizacionDolarSnapshot > 0,
			);
			servicioBloc.add(ServicioFormularioReiniciado(precarga: bloc.state.precargaServicio));
			await listoFormulario;
			servicioBloc.add(
				ServicioFormularioCambiado(
					equipoUbicacion: 'Taller',
					equipoAnio: '2021',
					diagnosticoDetalle: 'Fuente sin salida',
					diagnosticoCatIdsSeleccionados: const [_diagnosticoId],
					resolucionIdsSeleccionados: const [_resolucionId],
					partesFallaronTexto: 'indicador',
					productosFallaSeleccionados: [
						ProductoFalla(parteFallo: 'indicador', productoFallaId: _productoFallaId),
					],
				),
			);
			final guardado = servicioBloc.stream.firstWhere(
				(s) => s is ServicioFormularioState && s.ordenActual != null,
			);
			servicioBloc.add(const ServicioGuardarPressed());
			final orden = (await guardado as ServicioFormularioState).ordenActual!;

			// Lo que hace la pagina del formulario con la orden guardada.
			final estado = await vincular(
				RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: orden.servicioId),
			);

			expect(backend.de('POST', '/servicios'), hasLength(1));
			expect(backend.de('PATCH', '/servicio'), hasLength(1));
			expect(estado.servicioVinculadoId, _servicioId);
		});
	});

	group('alta rapida de cliente en la nueva recepcion', () {
		late _Backend backend;
		late NuevaRecepcionBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json({}, 404));
			bloc = NuevaRecepcionBloc(
				CrearRecepcionUseCase(backend.fabrica),
				BuscarClientesUseCase(backend.servicios),
				CrearClienteRapidoUseCase(backend.servicios),
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<NuevaRecepcionState> crear(NuevaRecepcionClienteRapidoSolicitado evento) {
			final listo = bloc.stream.firstWhere(
				(s) => !s.creandoCliente && (s.clienteCreado != null || s.errorAltaCliente != null),
			);
			bloc.add(evento);
			return listo;
		}

		test('crea el cliente con POST /clientes, lo selecciona y la recepcion lo usa', () async {
			backend.responder = (request) {
				if (request.url.path.endsWith('/clientes')) {
					return _json({
						'id': _clienteId,
						'cuit': '20304050607',
						'nombre': 'Agro SRL',
						'contacto': 'Juan',
						'telefono': '3462-552333',
						'localidad': 'Venado Tuerto',
					}, 201);
				}
				return _json(_recepcionJson(), 201);
			};

			final estado = await crear(
				const NuevaRecepcionClienteRapidoSolicitado(
					cuit: ' 20304050607 ',
					nombre: 'Agro SRL',
					contacto: 'Juan',
					telefono: '3462-552333',
					localidad: 'Venado Tuerto',
				),
			);

			final alta = backend.de('POST', '/clientes').single;
			expect(backend.body(alta), {
				'cuit': '20304050607',
				'nombre': 'Agro SRL',
				'contacto': 'Juan',
				'telefono': '3462-552333',
				'localidad': 'Venado Tuerto',
			});
			expect(estado.clienteCreado!.id, _clienteId);
			expect(estado.clienteSeleccionado!.id, _clienteId);
			expect(estado.errorAltaCliente, isNull);

			bloc.add(
				const NuevaRecepcionCambiada(
					indicadorNroSerie: 'IND-1001',
					queLlego: 'Indicador',
					sintomaReportado: 'No enciende',
				),
			);
			final guardada = bloc.stream.firstWhere((s) => s.recepcionCreada != null);
			bloc.add(const NuevaRecepcionGuardada());
			await guardada;

			expect(backend.body(backend.de('POST', '/fabrica/recepciones').single)['clienteId'], _clienteId);
		});

		test('los datos opcionales vacios no se mandan', () async {
			backend.responder = (_) => _json({'id': _clienteId, 'cuit': '20304050607', 'nombre': 'Agro SRL'}, 201);

			await crear(const NuevaRecepcionClienteRapidoSolicitado(cuit: '20304050607', nombre: 'Agro SRL'));

			expect(backend.body(backend.requests.single), {'cuit': '20304050607', 'nombre': 'Agro SRL'});
		});

		test('valida en el BLoC: sin CUIT ni nombre no llega al backend', () async {
			final estado = await crear(const NuevaRecepcionClienteRapidoSolicitado(cuit: ' ', nombre: ''));

			expect(estado.errorAltaCliente, 'Falta completar: CUIT, nombre.');
			expect(estado.clienteCreado, isNull);
			expect(backend.requests, isEmpty);
		});

		test('cliente que ya existe: avisa con el CUIT y no pierde lo cargado de la recepcion', () async {
			backend.responder = (_) => _json({
						'statusCode': 400,
						'error': 'Bad Request',
						'message': 'El cliente ya existe',
					}, 400);
			bloc.add(const NuevaRecepcionCambiada(indicadorNroSerie: 'IND-1001', queLlego: 'Indicador'));

			final estado = await crear(
				const NuevaRecepcionClienteRapidoSolicitado(cuit: '20304050607', nombre: 'Agro SRL'),
			);

			expect(estado.errorAltaCliente, 'El cliente con el CUIT: 20304050607 ya existe.');
			expect(estado.clienteCreado, isNull);
			expect(estado.clienteSeleccionado, isNull);
			expect(estado.indicadorNroSerie, 'IND-1001');
			expect(estado.queLlego, 'Indicador');
		});
	});

	group('vinculacion pendiente guardada en el dispositivo', () {
		final cerrar = <Future<void> Function()>[];

		tearDown(() async {
			for (final c in cerrar.reversed) {
				await c();
			}
			cerrar.clear();
		});

		/// Una "sesion" de la app: backend y bloc nuevos sobre el mismo storage.
		(_Backend, RecepcionDetalleBloc) abrirApp(
			http.Response Function(http.Request request) responder, {
			SecureStorageEnMemoria? storage,
		}) {
			final backend = _Backend(responder, storage: storage);
			final bloc = _detalleBloc(backend);
			cerrar
				..add(backend.cerrar)
				..add(bloc.close);
			return (backend, bloc);
		}

		Future<RecepcionDetalleState> abrir(RecepcionDetalleBloc bloc) {
			final listo = bloc.stream.firstWhere(
				(s) => s.recepcionId == _recepcionId && !s.cargando && s.recepcion != null,
			);
			bloc.add(const RecepcionDetalleAbierto(recepcionId: _recepcionId));
			return listo;
		}

		Future<RecepcionDetalleState> vincular(RecepcionDetalleBloc bloc, RecepcionDetalleEvent evento) {
			final listo = bloc.stream.firstWhere(
				(s) => !s.vinculando && (s.errorVinculacion != null || s.exitoMensaje != null),
			);
			bloc.add(evento);
			return listo;
		}

		test('si la vinculacion falla y se cierra la app, al volver se reintenta con el mismo servicio', () async {
			final (antes, blocAntes) = abrirApp((request) {
				return request.method == 'PATCH'
						? _json({'message': 'Error interno'}, 500)
						: _json(_recepcionJson());
			});
			await abrir(blocAntes);
			await vincular(
				blocAntes,
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);
			await blocAntes.close();

			// La app se vuelve a abrir: otro bloc, mismo dispositivo.
			final (despues, blocDespues) = abrirApp(
				(_) => _json(_recepcionJson()),
				storage: antes.storage,
			);
			final reabierta = await abrir(blocDespues);

			expect(reabierta.servicioPorVincular, _servicioId);
			expect(reabierta.puedeCargarServicio, isFalse);
			expect(reabierta.puedeReintentarVinculacion, isTrue);

			despues.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));
			final vinculada = await vincular(blocDespues, const RecepcionVinculacionReintentada());

			final patch = despues.de('PATCH', '/fabrica/recepciones/$_recepcionId/servicio').single;
			expect(despues.body(patch), {'servicioId': _servicioId});
			expect(despues.de('POST', '/servicios'), isEmpty);
			expect(vinculada.servicioVinculadoId, _servicioId);
			expect(vinculada.servicioPorVincular, isNull);

			// Ya vinculada, no queda nada pendiente en el dispositivo.
			await blocDespues.close();
			await pumpEventQueue();
			expect(await despues.fabrica.obtenerVinculacionesPendientes(), isEmpty);
		});

		test('al vincular bien no queda nada guardado', () async {
			final (backend, bloc) = abrirApp((_) => _json(_recepcionJson()));
			await abrir(bloc);
			backend.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));

			await vincular(
				bloc,
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);
			await bloc.close();
			await pumpEventQueue();

			expect(await backend.fabrica.obtenerVinculacionesPendientes(), isEmpty);
		});

		test('si al abrir la recepcion ya tiene el servicio, se borra lo guardado', () async {
			final (antes, _) = abrirApp((_) => _json(_recepcionJson()));
			await antes.fabrica.guardarVinculacionPendiente(
				const VinculacionPendiente(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			// La vinculacion llego al backend aunque la respuesta se perdio.
			final (despues, bloc) = abrirApp(
				(_) => _json(_recepcionJson(servicioId: _servicioId)),
				storage: antes.storage,
			);
			final estado = await abrir(bloc);
			await bloc.close();
			await pumpEventQueue();

			expect(estado.servicioPorVincular, isNull);
			expect(estado.servicioVinculadoId, _servicioId);
			expect(await despues.fabrica.obtenerVinculacionesPendientes(), isEmpty);
		});

		test('sin poder escribir en el dispositivo la vinculacion sigue funcionando', () async {
			final (backend, bloc) = abrirApp((_) => _json(_recepcionJson()));
			backend.storage.fallarEscrituras = true;
			await abrir(bloc);
			backend.responder = (request) => request.method == 'PATCH'
					? _json({'message': 'Error interno'}, 500)
					: _json(_recepcionJson());

			final fallo = await vincular(
				bloc,
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);

			expect(fallo.servicioPorVincular, _servicioId);
			expect(fallo.errorVinculacion, 'Error interno');
			expect(fallo.puedeReintentarVinculacion, isTrue);
		});
	});

	group('resumen del servicio vinculado', () {
		late _Backend backend;
		late RecepcionDetalleBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_recepcionJson(servicioId: _servicioId)));
			bloc = _detalleBloc(backend);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		/// Abre la recepcion y espera a que termine de pedir el resumen.
		Future<RecepcionDetalleState> abrirConResumen() {
			final listo = bloc.stream.firstWhere(
				(s) =>
						s.recepcion != null &&
						!s.cargando &&
						!s.cargandoServicioVinculado &&
						(s.resumenServicioVinculado != null ||
								s.servicioVinculadoNoDisponible ||
								s.errorServicioVinculado != null),
			);
			bloc.add(const RecepcionDetalleAbierto(recepcionId: _recepcionId));
			return listo;
		}

		test('con servicio vinculado trae fecha, tecnico, diagnostico y resoluciones', () async {
			final estado = await abrirConResumen();

			expect(backend.consultasServicio.single.url.path, endsWith('/servicios/$_servicioId'));
			final resumen = estado.resumenServicioVinculado!;
			expect(resumen.fecha, DateTime.utc(2026, 10, 25, 9, 30));
			expect(resumen.tecnicoNombre, 'Juan Tecnico');
			expect(resumen.diagnosticos, ['Fuente']);
			expect(resumen.diagnosticoDetalle, 'Fuente sin salida de 5 V');
			expect(resumen.resoluciones, ['Cambio de fuente', 'Prueba 24 h']);
			expect(estado.servicioVinculadoId, _servicioId);
		});

		test('sin servicio vinculado no lo pide', () async {
			backend.responder = (_) => _json(_recepcionJson());
			final listo = bloc.stream.firstWhere((s) => s.recepcion != null && !s.cargando);
			bloc.add(const RecepcionDetalleAbierto(recepcionId: _recepcionId));
			final estado = await listo;
			await pumpEventQueue();

			expect(backend.consultasServicio, isEmpty);
			expect(estado.resumenServicioVinculado, isNull);
		});

		for (final status in [403, 404]) {
			test('si responde $status sigue mostrando el id, sin error', () async {
				backend.responderServicio = (_) => _json({'statusCode': status, 'message': 'No disponible'}, status);

				final estado = await abrirConResumen();

				expect(estado.servicioVinculadoNoDisponible, isTrue);
				expect(estado.servicioVinculadoId, _servicioId);
				expect(estado.resumenServicioVinculado, isNull);
				expect(estado.errorServicioVinculado, isNull);
				expect(estado.errorMensaje, isNull);

				// Actualizar la recepcion no lo vuelve a pedir.
				final refrescada = bloc.stream.firstWhere((s) => !s.cargando);
				bloc.add(const RecepcionDetalleRefrescado());
				await refrescada;
				await pumpEventQueue();
				expect(backend.consultasServicio, hasLength(1));
			});
		}

		test('otro error queda a la vista y se puede reintentar', () async {
			backend.responderServicio = (_) => _json({'message': 'Error interno'}, 500);

			final fallo = await abrirConResumen();
			expect(fallo.errorServicioVinculado, 'Error interno');
			expect(fallo.servicioVinculadoId, _servicioId);

			backend.responderServicio = (_) => _json(_servicioJson());
			final listo = bloc.stream.firstWhere(
				(s) => !s.cargandoServicioVinculado && s.resumenServicioVinculado != null,
			);
			bloc.add(const RecepcionServicioVinculadoSolicitado());
			final reintento = await listo;

			expect(reintento.errorServicioVinculado, isNull);
			expect(reintento.resumenServicioVinculado!.tecnicoNombre, 'Juan Tecnico');
			expect(backend.consultasServicio, hasLength(2));
		});

		test('al vincular el servicio trae su resumen', () async {
			backend.responder = (_) => _json(_recepcionJson());
			final abierta = bloc.stream.firstWhere((s) => s.recepcion != null && !s.cargando);
			bloc.add(const RecepcionDetalleAbierto(recepcionId: _recepcionId));
			await abierta;
			backend.responder = (_) => _json(_recepcionJson(servicioId: _servicioId));

			final conResumen = bloc.stream.firstWhere((s) => s.resumenServicioVinculado != null);
			bloc.add(
				const RecepcionServicioGuardado(recepcionId: _recepcionId, servicioId: _servicioId),
			);
			final estado = await conResumen;

			expect(estado.servicioVinculadoId, _servicioId);
			expect(estado.resumenServicioVinculado!.resoluciones, ['Cambio de fuente', 'Prueba 24 h']);
		});
	});
}
