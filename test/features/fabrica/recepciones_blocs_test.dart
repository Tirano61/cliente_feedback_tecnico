import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cambiar_estado_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/devolver_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_servicio_vinculado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_vinculaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/vincular_servicio_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _recepcionId = '33333333-3333-4333-8333-333333333333';
const String _otraRecepcionId = '34343434-3434-4343-8343-343434343434';
const String _indicadorId = '44444444-4444-4444-8444-444444444444';
const String _placaId = '55555555-5555-4555-8555-555555555555';
const String _tecnicoId = '77777777-7777-4777-8777-777777777777';
const String _productoIndicadorId = '88888888-8888-4888-8888-888888888888';
const String _servicioId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

/// "Hoy" fijo: la recepcion de los ejemplos llego el 24/10.
DateTime _hoy() => DateTime(2026, 10, 27, 10);

// Respuesta de la seccion Fabrica de docs/endpoints.md.
Map<String, dynamic> _recepcionJson({
	String id = _recepcionId,
	int numero = 154,
	String estado = 'recibido',
	String? servicioId,
	String? fechaDevolucion,
	String? formaDevolucion,
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
			'fechaDevolucion': fechaDevolucion,
			'formaDevolucion': formaDevolucion,
			'observaciones': 'Viene de la sucursal',
			'ingresos': [],
			'piezasInstaladas': [
				{'id': _placaId, 'tipo': 'placa', 'nroSerie': 'PL-900', 'estado': 'instalada'},
			],
		};

Map<String, dynamic> _pagina(
	List<Map<String, dynamic>> data, {
	int page = 1,
	int total = 1,
	int totalPages = 1,
}) =>
		{
			'data': data,
			'meta': {'page': page, 'limit': 20, 'total': total, 'totalPages': totalPages},
		};

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

http.Response _regla(int status, String codigo, String mensaje, [Map<String, dynamic> extra = const {}]) {
	return _json({
		'statusCode': status,
		'error': status == 409 ? 'Conflict' : 'Bad Request',
		'codigo': codigo,
		'mensaje': mensaje,
		'message': mensaje,
		...extra,
	}, status);
}

/// Backend simulado: responde lo que diga `responder` y guarda cada request.
/// El resumen del servicio vinculado (`GET /servicios/:id`) responde 404 y no
/// se guarda: lo cubre servicio_fabrica_test.dart.
class _Backend {
	http.Response Function(http.Request request) responder;
	final List<http.Request> requests = [];
	late final ApiClient apiClient;
	late final FabricaRepositoryImpl fabrica;
	late final ServicioRepositoryImpl servicios;

	_Backend(this.responder) {
		final storage = SecureStorageEnMemoria()..valores['jwt_token'] = 'token';
		apiClient = ApiClient(
			MockClient((request) async {
				if (request.method == 'GET' && request.url.path.contains('/servicios/')) {
					return _json({'message': 'No existe'}, 404);
				}
				requests.add(request);
				return responder(request);
			}),
			storage,
		);
		fabrica = FabricaRepositoryImpl(apiClient, storage);
		servicios = ServicioRepositoryImpl(apiClient, storage);
	}

	Map<String, dynamic> body(http.Request request) =>
			jsonDecode(request.body) as Map<String, dynamic>;

	Future<void> cerrar() => apiClient.dispose();
}

Recepcion _recepcion({
	EstadoRecepcion estado = EstadoRecepcion.recibido,
	String? servicioId,
	DateTime? fechaRecepcion,
	DateTime? fechaDevolucion,
}) {
	return Recepcion(
		id: _recepcionId,
		numero: 154,
		cliente: const ClienteFabrica(id: _clienteId, nombre: 'Agro SRL'),
		indicadorId: _indicadorId,
		indicador: const Unidad(
			id: _indicadorId,
			tipo: TipoUnidad.indicador,
			nroSerie: 'IND-1001',
			estado: EstadoUnidad.enServicioTecnico,
		),
		queLlego: 'Indicador',
		sintomaReportado: 'No enciende',
		estado: estado,
		servicioId: servicioId,
		fechaRecepcion: fechaRecepcion ?? DateTime.utc(2026, 10, 24, 13),
		fechaDevolucion: fechaDevolucion,
	);
}

void main() {
	group('reglas de la recepcion', () {
		List<EstadoRecepcion> destinos(EstadoRecepcion estado) => ReglasRecepcion.acciones(
					_recepcion(estado: estado, servicioId: _servicioId),
				).map((a) => a.destino).toList();

		test('solo se ofrecen los cambios permitidos desde cada estado', () {
			expect(destinos(EstadoRecepcion.recibido), [
				EstadoRecepcion.enReparacion,
				EstadoRecepcion.esperandoPresupuesto,
			]);
			expect(destinos(EstadoRecepcion.enReparacion), [
				EstadoRecepcion.esperandoPresupuesto,
				EstadoRecepcion.listoParaDevolver,
			]);
			expect(destinos(EstadoRecepcion.esperandoPresupuesto), [
				EstadoRecepcion.enReparacion,
				EstadoRecepcion.listoParaDevolver,
			]);
			expect(destinos(EstadoRecepcion.listoParaDevolver), [EstadoRecepcion.enReparacion]);
			expect(destinos(EstadoRecepcion.devuelto), isEmpty);
			expect(destinos(EstadoRecepcion.desconocido), isEmpty);
		});

		test('el presupuesto y la prueba final tienen su propia etiqueta', () {
			final esperando = ReglasRecepcion.acciones(
				_recepcion(estado: EstadoRecepcion.esperandoPresupuesto, servicioId: _servicioId),
			);
			expect(esperando.map((a) => a.etiqueta), [
				'Aceptó el presupuesto',
				'No aceptó el presupuesto',
			]);

			final listo = ReglasRecepcion.acciones(
				_recepcion(estado: EstadoRecepcion.listoParaDevolver, servicioId: _servicioId),
			);
			expect(listo.single.etiqueta, 'Falló la prueba final');
		});

		test('listo para devolver queda bloqueado sin servicio de fabrica vinculado', () {
			final sinServicio = ReglasRecepcion.acciones(
				_recepcion(estado: EstadoRecepcion.enReparacion),
			);
			final listo = sinServicio.singleWhere((a) => a.destino == EstadoRecepcion.listoParaDevolver);
			expect(listo.habilitada, isFalse);
			expect(listo.motivoBloqueo, ReglasRecepcion.motivoFaltaServicio);
			expect(
				sinServicio.singleWhere((a) => a.destino == EstadoRecepcion.esperandoPresupuesto).habilitada,
				isTrue,
			);

			final conServicio = ReglasRecepcion.acciones(
				_recepcion(estado: EstadoRecepcion.enReparacion, servicioId: _servicioId),
			);
			expect(conServicio.every((a) => a.habilitada), isTrue);
		});

		test('devolver solo desde listo para devolver', () {
			for (final estado in EstadoRecepcion.values) {
				expect(
					ReglasRecepcion.puedeDevolver(_recepcion(estado: estado)),
					estado == EstadoRecepcion.listoParaDevolver,
					reason: '$estado',
				);
			}
		});

		test('dias en fabrica: hasta hoy si sigue abierta, hasta la devolucion si se devolvio', () {
			final llegada = DateTime(2026, 10, 24, 18);
			expect(
				ReglasRecepcion.diasEnFabrica(_recepcion(fechaRecepcion: llegada), DateTime(2026, 10, 27, 8)),
				3,
			);
			expect(
				ReglasRecepcion.diasEnFabrica(_recepcion(fechaRecepcion: llegada), DateTime(2026, 10, 24, 23)),
				0,
				reason: 'el dia que llega cuenta 0',
			);
			expect(
				ReglasRecepcion.diasEnFabrica(
					_recepcion(
						estado: EstadoRecepcion.devuelto,
						fechaRecepcion: llegada,
						fechaDevolucion: DateTime(2026, 10, 26, 9),
					),
					DateTime(2026, 11, 30),
				),
				2,
			);
		});
	});

	group('listado de equipos en fabrica', () {
		late _Backend backend;
		late RecepcionesBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_pagina([_recepcionJson()])));
			bloc = RecepcionesBloc(
				ObtenerRecepcionesUseCase(backend.fabrica),
				esperaBusqueda: const Duration(milliseconds: 30),
				ahora: _hoy,
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		bool quieto(RecepcionesState s) => !s.cargando && !s.actualizando && !s.cargandoMas;

		/// Espera a que arranque la consulta (el emit del filtro o del texto ya
		/// esta quieto) y despues a que termine.
		Future<RecepcionesState> esperarQuieto() {
			return bloc.stream.skipWhile(quieto).firstWhere(quieto);
		}

		Future<RecepcionesState> despachar(RecepcionesEvent evento) {
			final listo = esperarQuieto();
			bloc.add(evento);
			return listo;
		}

		test('al entrar pide las abiertas y calcula los dias en fabrica', () async {
			final estado = await despachar(const RecepcionesSolicitadas());

			final query = backend.requests.single.url.queryParameters;
			expect(backend.requests.single.url.path, endsWith('/fabrica/recepciones'));
			expect(query['abiertas'], 'true');
			expect(query.containsKey('estado'), isFalse);
			expect(query.containsKey('q'), isFalse);
			expect(query['page'], '1');

			expect(estado.recepciones.single.numero, 154);
			expect(estado.diasEnFabrica(estado.recepciones.single), 3);
			expect(estado.errorListado, isNull);
		});

		test('filtro por estado y ver devueltas cambian la consulta', () async {
			await despachar(const RecepcionesSolicitadas());

			await despachar(const RecepcionesFiltroEstadoCambiado(estado: EstadoRecepcion.enReparacion));
			var query = backend.requests.last.url.queryParameters;
			expect(query['estado'], 'en_reparacion');
			expect(query['abiertas'], 'true');

			final conDevueltas = await despachar(const RecepcionesVerDevueltasCambiado(verDevueltas: true));
			query = backend.requests.last.url.queryParameters;
			expect(query.containsKey('abiertas'), isFalse, reason: 'sin abiertas trae tambien las devueltas');
			expect(conDevueltas.estadosFiltrables, contains(EstadoRecepcion.devuelto));

			await despachar(const RecepcionesFiltroEstadoCambiado(estado: EstadoRecepcion.devuelto));
			expect(backend.requests.last.url.queryParameters['estado'], 'devuelto');

			// Sin las devueltas el filtro "Devuelto" no tiene sentido: se quita.
			final soloAbiertas = await despachar(const RecepcionesVerDevueltasCambiado(verDevueltas: false));
			query = backend.requests.last.url.queryParameters;
			expect(soloAbiertas.filtroEstado, isNull);
			expect(soloAbiertas.estadosFiltrables, isNot(contains(EstadoRecepcion.devuelto)));
			expect(query.containsKey('estado'), isFalse);
			expect(query['abiertas'], 'true');
		});

		test('la busqueda espera a que se deje de tipear y manda un solo pedido', () async {
			await despachar(const RecepcionesSolicitadas());
			final antes = backend.requests.length;

			final listo = esperarQuieto();
			bloc
				..add(const RecepcionesBusquedaCambiada(texto: 'I'))
				..add(const RecepcionesBusquedaCambiada(texto: 'IN'))
				..add(const RecepcionesBusquedaCambiada(texto: ' IND-1001 '));
			final estado = await listo;

			expect(backend.requests.length, antes + 1);
			expect(backend.requests.last.url.queryParameters['q'], 'IND-1001');
			expect(estado.busqueda, ' IND-1001 ', reason: 'el campo conserva lo tipeado');
		});

		test('pagina siguiente: agrega sin repetir y un error no borra lo cargado', () async {
			backend.responder = (request) {
				final page = request.url.queryParameters['page'];
				if (page == '1') {
					return _json(_pagina([_recepcionJson()], total: 2, totalPages: 2));
				}
				return _json(
					_pagina(
						[_recepcionJson(), _recepcionJson(id: _otraRecepcionId, numero: 155)],
						page: 2,
						total: 2,
						totalPages: 2,
					),
				);
			};
			final primera = await despachar(const RecepcionesSolicitadas());
			expect(primera.hayMasPaginas, isTrue);

			final segunda = await despachar(const RecepcionesSiguientePaginaSolicitada());
			expect(segunda.recepciones.map((r) => r.numero), [154, 155]);
			expect(segunda.hayMasPaginas, isFalse);

			// Otra carga, ahora con la pagina 2 fallando.
			backend.responder = (request) => request.url.queryParameters['page'] == '1'
					? _json(_pagina([_recepcionJson()], total: 2, totalPages: 2))
					: _json({'message': 'Fallo interno'}, 500);
			await despachar(const RecepcionesRefrescadas());
			final conError = await despachar(const RecepcionesSiguientePaginaSolicitada());
			expect(conError.recepciones.map((r) => r.numero), [154]);
			expect(conError.errorPaginacion, 'Fallo interno');
		});

		test('si falla el listado muestra el mensaje del backend', () async {
			backend.responder = (_) => _json({'message': 'Base de datos no disponible'}, 503);

			final estado = await despachar(const RecepcionesSolicitadas());

			expect(estado.recepciones, isEmpty);
			expect(estado.errorListado, 'Base de datos no disponible');
		});
	});

	group('detalle de la recepcion', () {
		late _Backend backend;
		late RecepcionDetalleBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_recepcionJson()));
			bloc = RecepcionDetalleBloc(
				ObtenerRecepcionUseCase(backend.fabrica),
				CambiarEstadoRecepcionUseCase(backend.fabrica),
				DevolverRecepcionUseCase(backend.fabrica),
				VincularServicioRecepcionUseCase(backend.fabrica),
				ObtenerServicioVinculadoUseCase(backend.fabrica),
				GuardarVinculacionPendienteUseCase(backend.fabrica),
				ObtenerVinculacionesPendientesUseCase(backend.fabrica),
				QuitarVinculacionPendienteUseCase(backend.fabrica),
				ahora: _hoy,
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<RecepcionDetalleState> abrir(Map<String, dynamic> json) async {
			backend.responder = (_) => _json(json);
			final listo = bloc.stream.firstWhere((s) => !s.cargando && s.recepcion != null);
			bloc.add(const RecepcionDetalleAbierto(recepcionId: _recepcionId));
			final estado = await listo;
			backend.requests.clear();
			return estado;
		}

		/// Espera a que la accion termine (bien o con error).
		Future<RecepcionDetalleState> accion(RecepcionDetalleEvent evento) {
			final listo = bloc.stream.firstWhere(
				(s) => !s.procesandoAccion && (s.errorAccion != null || s.exitoMensaje != null),
			);
			bloc.add(evento);
			return listo;
		}

		test('abre con GET por id y ofrece solo los cambios del estado actual', () async {
			backend.responder = (_) => _json(_recepcionJson());
			final listo = bloc.stream.firstWhere((s) => !s.cargando && s.recepcion != null);
			bloc.add(const RecepcionDetalleAbierto(recepcionId: _recepcionId));
			final estado = await listo;

			expect(backend.requests.single.method, 'GET');
			expect(backend.requests.single.url.path, endsWith('/fabrica/recepciones/$_recepcionId'));
			expect(estado.recepcion!.historialEstados.single.estado, EstadoRecepcion.recibido);
			expect(estado.accionesEstado.map((a) => a.destino), [
				EstadoRecepcion.enReparacion,
				EstadoRecepcion.esperandoPresupuesto,
			]);
			expect(estado.puedeDevolver, isFalse);
			expect(estado.diasEnFabrica, 3);
		});

		test('con la respuesta del alta se muestra sin volver a pedirla', () async {
			final listo = bloc.stream.first;
			bloc.add(RecepcionDetalleAbierto(recepcionId: _recepcionId, recepcion: _recepcion()));
			final estado = await listo;

			expect(backend.requests, isEmpty);
			expect(estado.recepcion!.numero, 154);
		});

		test('cambio de estado: PATCH con el codigo y la observacion, y muestra la recepcion nueva', () async {
			await abrir(_recepcionJson());
			backend.responder = (_) => _json(_recepcionJson(estado: 'esperando_presupuesto'));

			final estado = await accion(
				const RecepcionEstadoCambioSolicitado(
					estado: EstadoRecepcion.esperandoPresupuesto,
					observacion: '  Se envio presupuesto por WhatsApp ',
				),
			);

			final request = backend.requests.single;
			expect(request.method, 'PATCH');
			expect(request.url.path, endsWith('/fabrica/recepciones/$_recepcionId/estado'));
			expect(backend.body(request), {
				'estado': 'esperando_presupuesto',
				'observacion': 'Se envio presupuesto por WhatsApp',
			});
			expect(estado.recepcion!.estado, EstadoRecepcion.esperandoPresupuesto);
			expect(estado.exitoMensaje, 'Estado actualizado: Esperando presupuesto.');
			expect(estado.accionesEstado.map((a) => a.etiqueta), [
				'Aceptó el presupuesto',
				'No aceptó el presupuesto',
			]);
		});

		test('un cambio no permitido no llega al backend', () async {
			await abrir(_recepcionJson());

			final estado = await accion(
				const RecepcionEstadoCambioSolicitado(estado: EstadoRecepcion.devuelto),
			);

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, 'Una recepción en "Recibido" no puede pasar a "Devuelto".');
		});

		test('listo para devolver sin servicio vinculado no llega al backend', () async {
			await abrir(_recepcionJson(estado: 'en_reparacion'));

			final estado = await accion(
				const RecepcionEstadoCambioSolicitado(estado: EstadoRecepcion.listoParaDevolver),
			);

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, ReglasRecepcion.motivoFaltaServicio);
		});

		test('regla rechazada: muestra el mensaje tal cual, conserva la recepcion y la vuelve a pedir', () async {
			await abrir(_recepcionJson());
			const mensaje = 'La recepción ya está en reparación: no puede pasar a en reparación.';
			backend.responder = (request) => request.method == 'PATCH'
					? _regla(409, 'TRANSICION_INVALIDA', mensaje, {
							'estadoActual': 'en_reparacion',
							'permitidos': ['esperando_presupuesto', 'listo_para_devolver'],
						})
					: _json(_recepcionJson(estado: 'en_reparacion'));

			final refrescada = bloc.stream.firstWhere(
				(s) => !s.cargando && s.recepcion?.estado == EstadoRecepcion.enReparacion,
			);
			final estado = await accion(
				const RecepcionEstadoCambioSolicitado(estado: EstadoRecepcion.enReparacion),
			);

			expect(estado.errorAccion, mensaje);
			expect(estado.recepcion!.estado, EstadoRecepcion.recibido, reason: 'no se pierde lo que se veia');

			final despues = await refrescada;
			expect(backend.requests.map((r) => r.method), ['PATCH', 'GET']);
			expect(despues.errorAccion, mensaje, reason: 'el dialogo sigue mostrando por que se rechazo');
			expect(despues.accionesEstado.map((a) => a.destino), [
				EstadoRecepcion.esperandoPresupuesto,
				EstadoRecepcion.listoParaDevolver,
			]);
		});

		test('devolucion: exige la forma antes de llamar al backend', () async {
			await abrir(_recepcionJson(estado: 'listo_para_devolver', servicioId: _servicioId));

			final estado = await accion(const RecepcionDevolucionSolicitada(forma: null));

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, 'Elegí cómo se devuelve el equipo.');
		});

		test('devolucion: PATCH con la forma y queda devuelta', () async {
			final abierta = await abrir(_recepcionJson(estado: 'listo_para_devolver', servicioId: _servicioId));
			expect(abierta.puedeDevolver, isTrue);
			backend.responder = (_) => _json(
						_recepcionJson(
							estado: 'devuelto',
							servicioId: _servicioId,
							fechaDevolucion: '2026-10-28T15:00:00-03:00',
							formaDevolucion: 'retira_cliente',
						),
					);

			final estado = await accion(
				const RecepcionDevolucionSolicitada(
					forma: FormaDevolucion.retiraCliente,
					observacion: 'Retiro en mostrador',
				),
			);

			final request = backend.requests.single;
			expect(request.method, 'PATCH');
			expect(request.url.path, endsWith('/fabrica/recepciones/$_recepcionId/devolucion'));
			expect(backend.body(request), {
				'formaDevolucion': 'retira_cliente',
				'observacion': 'Retiro en mostrador',
			});
			expect(estado.recepcion!.estado, EstadoRecepcion.devuelto);
			expect(estado.recepcion!.formaDevolucion, FormaDevolucion.retiraCliente);
			expect(estado.accionesEstado, isEmpty);
			expect(estado.puedeDevolver, isFalse);
			expect(estado.exitoMensaje, 'Equipo devuelto al cliente (Retira el cliente).');
		});

		test('devolucion de una recepcion ya cerrada: mensaje del backend', () async {
			await abrir(_recepcionJson(estado: 'listo_para_devolver', servicioId: _servicioId));
			backend.responder = (request) => request.method == 'PATCH'
					? _regla(409, 'RECEPCION_CERRADA', 'La recepción 154 ya fue devuelta.')
					: _json(_recepcionJson(estado: 'devuelto', servicioId: _servicioId));

			final estado = await accion(
				const RecepcionDevolucionSolicitada(forma: FormaDevolucion.envio),
			);

			expect(estado.errorAccion, 'La recepción 154 ya fue devuelta.');
			expect(estado.devolviendo, isFalse);
		});
	});

	group('nueva recepcion', () {
		late _Backend backend;
		late NuevaRecepcionBloc bloc;

		const cliente = Cliente(id: _clienteId, nombre: 'Agro SRL', cuit: '20304050607');

		setUp(() {
			backend = _Backend((_) => _json(_recepcionJson(), 201));
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

		void completar() {
			bloc
				..add(const NuevaRecepcionClienteSeleccionado(cliente: cliente))
				..add(
					const NuevaRecepcionCambiada(
						indicadorNroSerie: ' IND-1001 ',
						indicadorProductoId: _productoIndicadorId,
						queLlego: 'Indicador completo con cable de celdas',
						sintomaReportado: 'No enciende',
						observaciones: 'Viene de la sucursal',
					),
				);
		}

		Future<NuevaRecepcionState> guardar() {
			final listo = bloc.stream.firstWhere(
				(s) =>
						!s.guardando &&
						(s.errorMensaje != null || s.recepcionCreada != null || s.recepcionAbierta != null),
			);
			bloc.add(const NuevaRecepcionGuardada());
			return listo;
		}

		test('busca clientes con el buscador existente y selecciona uno', () async {
			backend.responder = (_) => _json([
						{'id': _clienteId, 'cuit': '20304050607', 'nombre': 'Agro SRL'},
					]);

			final encontrados = bloc.stream.firstWhere((s) => !s.buscandoClientes && s.clientesEncontrados.isNotEmpty);
			bloc.add(const NuevaRecepcionBuscarClienteSolicitado(query: ' agro '));
			final estado = await encontrados;

			expect(backend.requests.single.url.path, endsWith('/clientes/buscar'));
			expect(backend.requests.single.url.queryParameters['q'], 'agro');
			expect(estado.clientesEncontrados.single.nombre, 'Agro SRL');

			final seleccionado = bloc.stream.first;
			bloc.add(NuevaRecepcionClienteSeleccionado(cliente: estado.clientesEncontrados.single));
			expect((await seleccionado).clienteSeleccionado!.id, _clienteId);
		});

		test('valida en el BLoC al guardar y vuelve a avisar si se insiste', () async {
			final primero = await guardar();
			expect(
				primero.errorMensaje,
				'Falta completar: cliente, número de serie del indicador, qué llegó, qué reporta el cliente.',
			);

			final segundo = await guardar();
			expect(segundo.errorMensaje, primero.errorMensaje);
			expect(backend.requests, isEmpty);
		});

		test('guarda con el body de endpoints.md y deja la recepcion creada para abrirla', () async {
			completar();

			final estado = await guardar();

			final request = backend.requests.single;
			expect(request.method, 'POST');
			expect(request.url.path, endsWith('/fabrica/recepciones'));
			expect(backend.body(request), {
				'clienteId': _clienteId,
				'indicadorNroSerie': 'IND-1001',
				'indicadorProductoId': _productoIndicadorId,
				'queLlego': 'Indicador completo con cable de celdas',
				'sintomaReportado': 'No enciende',
				'observaciones': 'Viene de la sucursal',
			});
			expect(estado.recepcionCreada!.id, _recepcionId);
			expect(estado.errorMensaje, isNull);
		});

		test('sin modelo ni observaciones no se mandan', () async {
			completar();
			bloc.add(const NuevaRecepcionCambiada(limpiarProducto: true, observaciones: '  '));

			await guardar();

			final body = backend.body(backend.requests.single);
			expect(body.containsKey('indicadorProductoId'), isFalse);
			expect(body.containsKey('observaciones'), isFalse);
		});

		test('indicador con recepcion abierta: ofrece abrir la existente y conserva lo cargado', () async {
			const mensaje = 'El indicador IND-1001 ya tiene la recepción 120 abierta.';
			backend.responder = (_) => _regla(409, 'RECEPCION_ABIERTA', mensaje, {
						'recepcionId': _otraRecepcionId,
						'numero': 120,
					});
			completar();

			final estado = await guardar();

			expect(estado.recepcionAbierta, const RecepcionAbiertaExistente(
				recepcionId: _otraRecepcionId,
				numero: 120,
				mensaje: mensaje,
			));
			expect(estado.recepcionCreada, isNull);
			expect(estado.clienteSeleccionado, cliente);
			expect(estado.indicadorNroSerie, ' IND-1001 ');
			expect(estado.queLlego, 'Indicador completo con cable de celdas');
			expect(estado.sintomaReportado, 'No enciende');
		});

		test('otro rechazo del backend: mensaje tal cual sin perder el formulario', () async {
			backend.responder = (_) => _json({
						'statusCode': 400,
						'error': 'Bad Request',
						'message': ['clienteId must be a UUID'],
					}, 400);
			completar();

			final estado = await guardar();

			expect(estado.errorMensaje, 'clienteId must be a UUID');
			expect(estado.clienteSeleccionado, cliente);
			expect(estado.indicadorProductoId, _productoIndicadorId);
			expect(estado.observaciones, 'Viene de la sucursal');
		});
	});
}
