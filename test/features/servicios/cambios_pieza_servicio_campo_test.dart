import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_asignaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/descargar_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/encolar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cliente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_documentos_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_enlace_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/quitar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/subir_documento_firmado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/cambios_pieza_formulario.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/campos_formulario_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _zonaId = '33333333-3333-4333-8333-333333333333';
const String _diagnosticoId = '44444444-4444-4444-8444-444444444444';
const String _resolucionId = '66666666-6666-4666-8666-666666666666';
const String _productoFallaId = '99999999-9999-4999-8999-999999999999';
const String _productoIndicadorId = '88888888-8888-4888-8888-888888888888';
const String _productoPlacaId = '12121212-1212-4212-8212-121212121212';
const String _placaReacondicionadaId = '13131313-1313-4313-8313-131313131313';
const String _indicadorId = '14141414-1414-4414-8414-141414141414';
const String _servicioId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

// Respuesta de POST /servicios (la que usa la app para el PDF).
final Map<String, dynamic> _ordenCreada = {
	'replayed': false,
	'servicioId': _servicioId,
	'idempotencyKey': '2f7b4d37-2f7f-4b0f-b2f0-1f9d9d1a7a1f',
	'estadoOrden': 'cerrada',
	'version': 1,
	'servicio': {'canal': 'campo', 'clienteId': _clienteId},
};

// GET /fabrica/unidades?tipo=placa&estado=reacondicionada_disponible.
final Map<String, dynamic> _placasReacondicionadas = {
	'data': [
		{
			'id': _placaReacondicionadaId,
			'tipo': 'placa',
			'nroSerie': 'PL-2001',
			'estado': 'reacondicionada_disponible',
			'producto': {'id': _productoPlacaId, 'nombre': 'Placa ST455', 'version': null},
		},
	],
	'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
};

final Map<String, dynamic> _sinUnidades = {
	'data': [],
	'meta': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
};

/// Respuesta de POST /fabrica/unidades/asignaciones (endpoints.md, Fabrica).
http.Response _asignada(http.Request request) {
	final body = jsonDecode(request.body) as Map<String, dynamic>;
	final retirada = body['retiradaNroSerie'];
	return _json({
		'indicador': {'id': _indicadorId, 'nroSerie': body['indicadorNroSerie']},
		'instalada': {
			'id': 'instalada-${body['nroSerie']}',
			'tipo': body['tipo'],
			'nroSerie': body['nroSerie'],
			'estado': 'instalada',
			'indicadorActualId': _indicadorId,
		},
		'retiradas': [
			if (retirada != null)
				{'id': 'retirada-$retirada', 'tipo': body['tipo'], 'nroSerie': retirada, 'estado': 'retirada'},
		],
	}, 201);
}

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

http.Response _regla(int status, String codigo, String mensaje) {
	return _json({
		'statusCode': status,
		'error': 'Conflict',
		'codigo': codigo,
		'mensaje': mensaje,
		'message': mensaje,
	}, status);
}

bool _esAsignacion(http.Request r) =>
		r.method == 'POST' && r.url.path.endsWith('/fabrica/unidades/asignaciones');

bool _esAlta(http.Request r) => r.method == 'POST' && r.url.path.endsWith('/servicios');

/// Backend simulado. `asignar` responde cada POST de asignacion; el alta del
/// servicio, las reacondicionadas, mis servicios, la cotizacion y la tarifa
/// responden siempre. Guarda cada request salvo cotizacion y tarifa.
///
/// Con el `storage` de otro escenario simula volver a abrir la app en el mismo
/// dispositivo.
class _Escenario {
	http.Response Function(http.Request request) asignar = _asignada;
	final List<http.Request> requests = [];
	late final SecureStorageEnMemoria storage;
	late final ApiClient apiClient;
	late final ServicioBloc bloc;

	_Escenario({SecureStorageEnMemoria? storage}) {
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
				requests.add(request);
				if (_esAlta(request)) {
					return _json(_ordenCreada, 201);
				}
				if (_esAsignacion(request)) {
					return asignar(request);
				}
				if (request.method == 'GET' && path.endsWith('/fabrica/unidades')) {
					return _json(
						request.url.queryParameters['tipo'] == 'placa' ? _placasReacondicionadas : _sinUnidades,
					);
				}
				if (request.method == 'GET' && path.endsWith('/servicios/mios')) {
					return _json({
						'data': [],
						'meta': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
					});
				}
				return _json({}, 404);
			}),
			this.storage,
		);
		final servicios = ServicioRepositoryImpl(apiClient, this.storage);
		final fabrica = FabricaRepositoryImpl(apiClient, this.storage);
		bloc = ServicioBloc(
			CargarServicioUseCase(servicios),
			ObtenerMisServiciosUseCase(servicios),
			BuscarClientesUseCase(servicios),
			CrearClienteRapidoUseCase(servicios),
			ObtenerCotizacionActualUseCase(servicios),
			BuscarRepuestosUseCase(servicios),
			GenerarPdfOrdenServicioUseCase(),
			SubirDocumentoFirmadoUseCase(servicios),
			EncolarDocumentoPendienteUseCase(servicios),
			ObtenerDocumentosPendientesUseCase(servicios),
			QuitarDocumentoPendienteUseCase(servicios),
			ObtenerEnlacePdfDocumentoUseCase(servicios),
			DescargarPdfDocumentoUseCase(servicios),
			ObtenerClienteUseCase(servicios),
			AsignarUnidadUseCase(fabrica),
			BuscarUnidadesUseCase(fabrica),
			GuardarAsignacionPendienteUseCase(fabrica),
			ObtenerAsignacionesPendientesUseCase(fabrica),
			QuitarAsignacionPendienteUseCase(fabrica),
		);
	}

	ServicioFormularioState get estado => bloc.state as ServicioFormularioState;

	List<http.Request> get altas => requests.where(_esAlta).toList();

	List<Map<String, dynamic>> get asignaciones => requests
			.where(_esAsignacion)
			.map((r) => jsonDecode(r.body) as Map<String, dynamic>)
			.toList();

	/// Lo que queda guardado en el dispositivo.
	Future<int> pendientesGuardados() async {
		return (await FabricaRepositoryImpl(apiClient, storage).obtenerAsignacionesPendientes()).length;
	}

	/// Formulario nuevo con los valores de facturacion cargados, como en la app.
	Future<void> reiniciar() async {
		final listo = bloc.stream.firstWhere(
			(s) => s is ServicioFormularioState && s.cotizacionDolarSnapshot > 0 && !s.cargandoFacturacion,
		);
		bloc.add(const ServicioFormularioReiniciado());
		await listo;
	}

	Future<void> cargarOrdenDeCampo() async {
		bloc.add(
			ServicioFormularioCambiado(
				canal: Canal.campo,
				clienteId: _clienteId,
				zonaId: _zonaId,
				lugarDetalle: 'Cestari 14',
				km: '120',
				equipoNroSerie: 'SN-001',
				equipoModelo: 'ST455',
				equipoModeloProductoId: _productoIndicadorId,
				equipoUbicacion: 'Tolva principal',
				equipoAnio: '2021',
				precioServicioUsd: '80',
				sintoma: 'No enciende',
				diagnosticoDetalle: 'Placa sin salida de 5 V',
				diagnosticoCatIdsSeleccionados: const [_diagnosticoId],
				resolucionIdsSeleccionados: const [_resolucionId],
				partesFallaronTexto: 'Indicador',
				productosFallaSeleccionados: const [
					ProductoFalla(parteFallo: 'indicador', productoFallaId: _productoFallaId),
				],
			),
		);
		await pumpEventQueue();
	}

	/// Agrega un cambio y espera las reacondicionadas de ese tipo. Devuelve el
	/// id de la fila.
	Future<int> agregarCambio(TipoUnidad tipo) async {
		bloc.add(ServicioCambioPiezaAgregado(tipo: tipo));
		await pumpEventQueue();
		return estado.cambiosPieza.last.id;
	}

	Future<void> cambiar(ServicioCambioPiezaCambiado evento) async {
		bloc.add(evento);
		await pumpEventQueue();
	}

	/// Toca "Guardar" y espera el resultado: exito o error.
	Future<ServicioFormularioState> guardar() async {
		final resultado = bloc.stream.firstWhere(
			(s) =>
					s is ServicioFormularioState &&
					!s.guardando &&
					(s.exitoMensaje != null || s.errorMensaje != null),
		);
		bloc.add(const ServicioGuardarPressed());
		return await resultado as ServicioFormularioState;
	}

	Future<void> cerrar() async {
		await bloc.close();
		await apiClient.dispose();
	}
}

void main() {
	// El alta genera el PDF de la orden: sin binding el cargador de fuentes
	// ensucia la salida del test.
	TestWidgetsFlutterBinding.ensureInitialized();

	group('cambio de placa/celda en el servicio de campo', () {
		late _Escenario escenario;

		setUp(() async {
			escenario = _Escenario();
			await escenario.reiniciar();
			await escenario.cargarOrdenDeCampo();
		});

		tearDown(() => escenario.cerrar());

		test('con un cambio: guarda el servicio y despues pone la pieza con su servicioId', () async {
			final id = await escenario.agregarCambio(TipoUnidad.placa);

			// Las reacondicionadas de ese tipo, para elegir la que se pone.
			final consulta = escenario.requests.singleWhere(
				(r) => r.method == 'GET' && r.url.path.endsWith('/fabrica/unidades'),
			);
			expect(consulta.url.queryParameters['tipo'], 'placa');
			expect(consulta.url.queryParameters['estado'], 'reacondicionada_disponible');
			final reacondicionadas = escenario.estado.reacondicionadas[TipoUnidad.placa]!;
			expect(reacondicionadas.unidades.single.nroSerie, 'PL-2001');

			escenario.bloc.add(
				ServicioCambioPiezaReacondicionadaElegida(id: id, unidad: reacondicionadas.unidades.single),
			);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: id, retiradaNroSerie: 'PL-900'));
			final cambio = escenario.estado.cambiosPieza.single;
			expect(cambio.nroSerie, 'PL-2001');
			expect(cambio.productoId, _productoPlacaId);

			final estado = await escenario.guardar();

			// Primero el servicio, una sola vez; despues la asignacion.
			final orden = escenario.requests.where((r) => _esAlta(r) || _esAsignacion(r)).toList();
			expect(orden.map(_esAlta), [true, false]);
			expect(escenario.asignaciones.single, {
				'indicadorNroSerie': 'SN-001',
				'tipo': 'placa',
				'nroSerie': 'PL-2001',
				'productoId': _productoPlacaId,
				'indicadorProductoId': _productoIndicadorId,
				'retiradaNroSerie': 'PL-900',
				'servicioId': _servicioId,
			});

			final resultado = estado.resultadoCambiosPieza!;
			expect(resultado.servicioId, _servicioId);
			expect(resultado.pendientes, 0);
			expect(resultado.cambios.single.texto, 'Placa PL-2001 puesta en el indicador SN-001.');
			// La que sale queda retirada hasta su ingreso a fabrica.
			expect(resultado.cambios.single.textosRetiradas, ['Placa PL-900']);
			expect(resultado.hayRetiradas, isTrue);
			expect(ResultadoCambiosPieza.recordatorioRetiradas, contains('Piezas ingresadas'));
			expect(estado.exitoMensaje, isNot(contains('pendiente')));
			expect(await escenario.pendientesGuardados(), 0);
		});

		test('con dos cambios: los registra en orden con el mismo servicio', () async {
			final placa = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: placa, nroSerie: ' pl-3001 '));
			final celda = await escenario.agregarCambio(TipoUnidad.celda);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: celda, nroSerie: 'CE-77'));

			final estado = await escenario.guardar();

			expect(escenario.altas, hasLength(1));
			final bodies = escenario.asignaciones;
			expect(bodies.map((b) => b['tipo']), ['placa', 'celda']);
			expect(bodies.map((b) => b['nroSerie']), ['pl-3001', 'CE-77']);
			expect(bodies.map((b) => b['servicioId']), [_servicioId, _servicioId]);
			expect(bodies.map((b) => b['indicadorNroSerie']), ['SN-001', 'SN-001']);
			// Sin la que se saca no viaja la clave: en placa sale la que tenia.
			expect(bodies.every((b) => !b.containsKey('retiradaNroSerie')), isTrue);
			expect(estado.resultadoCambiosPieza!.cambios.map((c) => c.pendiente), [false, false]);
			expect(await escenario.pendientesGuardados(), 0);
		});

		test('una asignacion rechazada queda pendiente y se reintenta sin crear otro servicio', () async {
			escenario.asignar = (_) => _regla(
						409,
						'UNIDAD_NO_DISPONIBLE',
						'La placa PL-4001 está descartada y no se puede instalar.',
					);
			final id = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: id, nroSerie: 'PL-4001'));

			final estado = await escenario.guardar();

			// El servicio quedo guardado igual.
			expect(escenario.altas, hasLength(1));
			expect(estado.ordenActual!.servicioId, _servicioId);
			expect(estado.exitoMensaje, contains('quedaron pendientes'));
			final cambio = estado.resultadoCambiosPieza!.cambios.single;
			expect(cambio.pendiente, isTrue);
			expect(cambio.error, 'La placa PL-4001 está descartada y no se puede instalar.');
			expect(estado.resultadoCambiosPieza!.pendientes, 1);
			expect(await escenario.pendientesGuardados(), 1);

			// Como en la app: al abrir el aviso de exito el formulario arranca de nuevo.
			await escenario.reiniciar();
			expect(escenario.estado.cambiosPieza, isEmpty);
			expect(escenario.estado.resultadoCambiosPieza!.pendientes, 1);

			// "Reintentar" desde el aviso de exito.
			escenario.asignar = _asignada;
			final reintentado = escenario.bloc.stream.firstWhere(
				(s) =>
						s is ServicioFormularioState &&
						s.resultadoCambiosPieza?.pendientes == 0 &&
						!s.resultadoCambiosPieza!.reintentando,
			);
			escenario.bloc.add(const ServicioAsignacionesPendientesReintentadas(servicioId: _servicioId));
			final despues = await reintentado as ServicioFormularioState;

			expect(despues.resultadoCambiosPieza!.cambios.single.texto, 'Placa PL-4001 puesta en el indicador SN-001.');
			expect(escenario.altas, hasLength(1));
			expect(escenario.asignaciones, hasLength(2));
			expect(escenario.asignaciones.last['servicioId'], _servicioId);
			expect(await escenario.pendientesGuardados(), 0);
		});

		test('sin conexion queda pendiente y se reintenta desde Mis servicios al volver a abrir la app', () async {
			escenario.asignar = (_) => throw http.ClientException('Sin red');
			final id = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: id, nroSerie: 'PL-5001', retiradaNroSerie: 'PL-900'));
			final estado = await escenario.guardar();
			expect(estado.resultadoCambiosPieza!.cambios.single.pendiente, isTrue);
			expect(await escenario.pendientesGuardados(), 1);

			// Otra sesion de la app en el mismo dispositivo.
			final reabierta = _Escenario(storage: escenario.storage);
			addTearDown(reabierta.cerrar);
			final listado = reabierta.bloc.stream.firstWhere((s) => s is MisServiciosLoaded);
			reabierta.bloc.add(const MisServiciosSolicitados());
			final misServicios = await listado as MisServiciosLoaded;

			final pendiente = misServicios.asignacionesPendientes.single;
			expect(descripcionAsignacionPendiente(pendiente), 'Placa PL-5001 en el indicador SN-001');
			expect(pendiente.mensajeError, contains('Revisá la conexión'));

			final reintentado = reabierta.bloc.stream.firstWhere(
				(s) => s is MisServiciosLoaded && !s.reintentandoAsignaciones && s.mensajePendientes != null,
			);
			reabierta.bloc.add(const ServicioAsignacionesPendientesReintentadas());
			final despues = await reintentado as MisServiciosLoaded;

			expect(despues.asignacionesPendientes, isEmpty);
			expect(despues.mensajePendientes, contains('Cambios de placa/celda registrados.'));
			expect(despues.mensajePendientes, contains('Piezas ingresadas'));
			expect(reabierta.altas, isEmpty);
			expect(reabierta.asignaciones.single, {
				'indicadorNroSerie': 'SN-001',
				'tipo': 'placa',
				'nroSerie': 'PL-5001',
				'indicadorProductoId': _productoIndicadorId,
				'retiradaNroSerie': 'PL-900',
				'servicioId': _servicioId,
			});
			expect(await reabierta.pendientesGuardados(), 0);
		});

		test('en un reintento, la pieza ya puesta en ese indicador se da por registrada', () async {
			escenario.asignar = (_) => throw http.ClientException('Se corto la respuesta');
			final id = await escenario.agregarCambio(TipoUnidad.celda);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: id, nroSerie: 'CE-9'));
			await escenario.guardar();
			expect(await escenario.pendientesGuardados(), 1);

			escenario.asignar = (_) => _regla(409, 'UNIDAD_YA_INSTALADA', 'La celda CE-9 ya está en ese indicador.');
			final reintentado = escenario.bloc.stream.firstWhere(
				(s) => s is ServicioFormularioState && s.resultadoCambiosPieza?.pendientes == 0,
			);
			escenario.bloc.add(const ServicioAsignacionesPendientesReintentadas(servicioId: _servicioId));
			final despues = await reintentado as ServicioFormularioState;

			expect(
				despues.resultadoCambiosPieza!.cambios.single.texto,
				'Celda CE-9 ya figuraba puesta en el indicador SN-001.',
			);
			expect(await escenario.pendientesGuardados(), 0);
		});

		test('sin numero de serie no guarda el servicio', () async {
			await escenario.agregarCambio(TipoUnidad.celda);

			final estado = await escenario.guardar();

			expect(estado.errorMensaje, 'Completa el número de serie de la celda que se pone.');
			expect(estado.avisoValidacion!.campo, CampoFormularioServicio.cambiosPieza);
			expect(estado.avisoValidacion!.paso, PasoFormularioServicio.falla);
			expect(escenario.altas, isEmpty);
			expect(escenario.asignaciones, isEmpty);
		});

		test('la misma pieza dos veces no guarda el servicio', () async {
			final primera = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: primera, nroSerie: 'PL-6001'));
			final segunda = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: segunda, nroSerie: 'pl-6001 '));

			final estado = await escenario.guardar();

			expect(estado.errorMensaje, 'La pieza PL-6001 está dos veces en los cambios de placa/celda.');
			expect(estado.avisoValidacion!.campo, CampoFormularioServicio.cambiosPieza);
			expect(escenario.altas, isEmpty);
		});

		test('la pieza que se saca no puede ser la que se pone', () async {
			final id = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: id, nroSerie: 'PL-7001', retiradaNroSerie: 'pl-7001'));

			final estado = await escenario.guardar();

			expect(estado.errorMensaje, 'La pieza que se saca no puede ser la misma que se pone.');
			expect(escenario.altas, isEmpty);
		});

		test('fuera de campo no hay cambios de placa/celda', () async {
			final id = await escenario.agregarCambio(TipoUnidad.placa);
			await escenario.cambiar(ServicioCambioPiezaCambiado(id: id, nroSerie: 'PL-8001'));

			escenario.bloc.add(const ServicioFormularioCambiado(canal: Canal.remoto));
			await pumpEventQueue();
			expect(escenario.estado.cambiosPieza, isEmpty);

			escenario.bloc.add(const ServicioCambioPiezaAgregado(tipo: TipoUnidad.placa));
			await pumpEventQueue();
			expect(escenario.estado.cambiosPieza, isEmpty);
		});
	});
}
