import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_falla_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_reparacion_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/derivar_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_causas_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_componentes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_historial_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/recibir_de_desarrollo_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/ingreso_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/nuevo_ingreso_page.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _recepcionId = '33333333-3333-4333-8333-333333333333';
const String _indicadorId = '44444444-4444-4444-8444-444444444444';
const String _placaId = '55555555-5555-4555-8555-555555555555';
const String _placaNuevaId = '56565656-5656-4565-8565-565656565656';
const String _reacondicionadaId = '58585858-5858-4585-8585-585858585858';
const String _celdaId = '57575757-5757-4575-8575-575757575757';
const String _ingresoId = '66666666-6666-4666-8666-666666666666';
const String _productoPlacaId = '99999999-9999-4999-8999-999999999999';
const String _servicioCampoId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

// Respuestas de la seccion Fabrica de docs/endpoints.md.

Map<String, dynamic> _unidadJson({
	String id = _placaId,
	String tipo = 'placa',
	String nroSerie = 'PL-900',
	String estado = 'instalada',
	bool conProducto = false,
	String? indicadorActualId,
	List<Map<String, dynamic>>? piezasInstaladas,
}) =>
		{
			'id': id,
			'tipo': tipo,
			'nroSerie': nroSerie,
			'estado': estado,
			'producto': conProducto ? {'id': _productoPlacaId, 'nombre': 'Placa ST455', 'version': 'v3'} : null,
			'indicadorActualId': indicadorActualId,
			'piezasInstaladas': ?piezasInstaladas,
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

Map<String, dynamic> _asignacionJson({List<Map<String, dynamic>>? retiradas}) => {
			'indicador': {'id': _indicadorId, 'nroSerie': 'IND-1001'},
			'instalada': {
				'id': _placaNuevaId,
				'tipo': 'placa',
				'nroSerie': 'PL-2001',
				'estado': 'instalada',
				'indicadorActualId': _indicadorId,
			},
			'retiradas': retiradas ??
					[
						{'id': _placaId, 'tipo': 'placa', 'nroSerie': 'PL-900', 'estado': 'retirada'},
					],
		};

Map<String, dynamic> _historialJson() => {
			'unidad': {'id': _placaId, 'tipo': 'placa', 'nroSerie': 'PL-900', 'estado': 'reacondicionada_disponible'},
			'movimientos': [
				{
					'tipo': 'alta',
					'fecha': '2026-10-01T12:00:00.000Z',
					'usuario': {'fullName': 'Juan Tecnico'},
					'indicador': null,
					'servicioId': null,
					'recepcionId': null,
					'ingresoId': null,
					'observacion': null,
				},
				{'tipo': 'retiro', 'indicador': {'nroSerie': 'IND-1001'}, 'recepcionId': _recepcionId},
				{'tipo': 'ingreso_fabrica', 'ingresoId': _ingresoId, 'observacion': 'No da tension en la salida de 5 V'},
				{'tipo': 'derivacion_desarrollo'},
				{'tipo': 'reparada', 'observacion': 'Cambio de regulador y prueba 24 h'},
				{'tipo': 'vuelta_a_servicio_tecnico'},
				{'tipo': 'instalacion', 'indicador': {'nroSerie': 'IND-2002'}, 'servicioId': _servicioCampoId},
			],
		};

Map<String, dynamic> _ingresoJson() => {
			'id': _ingresoId,
			'numero': 37,
			'unidadId': _placaId,
			'unidad': {'id': _placaId, 'tipo': 'placa', 'nroSerie': 'PL-900', 'estado': 'en_servicio_tecnico'},
			'clienteOrigen': {'id': _clienteId, 'nombre': 'Agro SRL'},
			'indicadorOrigenId': _indicadorId,
			'indicadorOrigen': {'id': _indicadorId, 'nroSerie': 'IND-1001'},
			'recepcionId': _recepcionId,
			'servicioId': null,
			'fechaIngreso': '2026-10-24T13:30:00.000Z',
			'observacionTecnico': 'No da tension en la salida de 5 V',
			'estado': 'en_servicio_tecnico',
			'falla': null,
			'reparacion': null,
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
class _Backend {
	http.Response Function(http.Request request) responder;
	final List<http.Request> requests = [];
	late final ApiClient apiClient;
	late final FabricaRepositoryImpl fabrica;

	_Backend(this.responder) {
		final storage = SecureStorageEnMemoria()..valores['jwt_token'] = 'token';
		apiClient = ApiClient(
			MockClient((request) async {
				requests.add(request);
				return responder(request);
			}),
			storage,
		);
		fabrica = FabricaRepositoryImpl(apiClient, storage);
	}

	List<http.Request> de(String metodo, String sufijo) => requests
			.where((r) => r.method == metodo && r.url.path.endsWith(sufijo))
			.toList();

	Map<String, dynamic> body(http.Request request) =>
			jsonDecode(request.body) as Map<String, dynamic>;

	Future<void> cerrar() => apiClient.dispose();
}

const PrecargaAsignacionRecepcion _precarga = PrecargaAsignacionRecepcion(
	recepcionId: _recepcionId,
	numero: 154,
	clienteNombre: 'Agro SRL',
	indicadorId: _indicadorId,
	indicadorNroSerie: 'IND-1001',
	piezasInstaladas: [
		Unidad(id: _placaId, tipo: TipoUnidad.placa, nroSerie: 'PL-900', estado: EstadoUnidad.instalada),
		Unidad(id: _celdaId, tipo: TipoUnidad.celda, nroSerie: 'CE-77', estado: EstadoUnidad.instalada),
	],
);

void main() {
	group('poner placa/celda desde la recepcion', () {
		late _Backend backend;
		late AsignacionUnidadBloc bloc;

		/// Las reacondicionadas disponibles, salvo que el test diga otra cosa.
		http.Response reacondicionadas(http.Request request) => _json(
					_pagina([
						_unidadJson(
							id: _reacondicionadaId,
							nroSerie: 'PL-500',
							estado: 'reacondicionada_disponible',
							conProducto: true,
						),
					]),
				);

		setUp(() {
			backend = _Backend(reacondicionadas);
			bloc = AsignacionUnidadBloc(
				AsignarUnidadUseCase(backend.fabrica),
				BuscarUnidadesUseCase(backend.fabrica),
				ObtenerUnidadUseCase(backend.fabrica),
			);
			bloc.add(const AsignacionIniciada(precarga: _precarga));
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		/// Elige el tipo y espera la lista de reacondicionadas.
		Future<AsignacionUnidadState> elegirTipo(TipoUnidad tipo) async {
			final listo = bloc.stream.firstWhere(
				(s) => s.tipo == tipo && !s.cargandoReacondicionadas,
			);
			bloc.add(AsignacionCambiada(tipo: tipo));
			final estado = await listo;
			return estado;
		}

		Future<AsignacionUnidadState> guardar() {
			final listo = bloc.stream.firstWhere(
				(s) => !s.guardando && (s.asignada || s.errorAsignacion != null),
			);
			bloc.add(const AsignacionGuardada());
			return listo;
		}

		test('arranca con el indicador, la recepcion y las piezas instaladas', () async {
			await pumpEventQueue();

			expect(bloc.state.precarga, _precarga);
			expect(bloc.state.piezasInstaladas, hasLength(2));
			expect(bloc.state.piezasParaRetirar, isEmpty);
			expect(backend.requests, isEmpty);
		});

		test('al elegir el tipo trae las reacondicionadas disponibles de ese tipo', () async {
			final estado = await elegirTipo(TipoUnidad.placa);

			final request = backend.requests.single;
			expect(request.url.path, endsWith('/fabrica/unidades'));
			expect(request.url.queryParameters, {
				'tipo': 'placa',
				'estado': 'reacondicionada_disponible',
				'page': '1',
				'limit': '20',
			});
			expect(estado.reacondicionadas.single.nroSerie, 'PL-500');
			expect(estado.piezasParaRetirar.map((p) => p.nroSerie), ['PL-900']);
			expect(estado.avisoRetirada, 'Si no elegís, sale la placa que tiene el indicador (PL-900).');
		});

		test('valida en el BLoC al guardar y vuelve a avisar si se insiste', () async {
			await pumpEventQueue();
			final avisos = bloc.stream.where((s) => s.errorMensaje != null).take(2).toList();
			bloc.add(const AsignacionGuardada());
			bloc.add(const AsignacionGuardada());

			final mensajes = (await avisos).map((s) => s.errorMensaje).toList();
			expect(mensajes, [
				'Falta completar: tipo de pieza, número de serie de la pieza que se pone.',
				'Falta completar: tipo de pieza, número de serie de la pieza que se pone.',
			]);
			expect(backend.requests, isEmpty);
		});

		test('la pieza que sale no puede ser la misma que se pone', () async {
			await elegirTipo(TipoUnidad.placa);
			backend.requests.clear();
			bloc.add(const AsignacionCambiada(nroSerie: 'pl-900 ', retiradaNroSerie: 'PL-900'));

			final aviso = bloc.stream.firstWhere((s) => s.errorMensaje != null);
			bloc.add(const AsignacionGuardada());

			expect((await aviso).errorMensaje, 'La pieza que se saca no puede ser la misma que se pone.');
			expect(backend.requests, isEmpty);
		});

		test('placa nueva sin elegir la que sale: POST sin retiradaNroSerie y muestra instalada y retiradas', () async {
			await elegirTipo(TipoUnidad.placa);
			backend.responder = (_) => _json(_asignacionJson(), 201);
			bloc.add(
				const AsignacionCambiada(
					nroSerie: ' PL-2001 ',
					productoId: _productoPlacaId,
					observacion: ' Cambio de placa por falla de fuente ',
				),
			);

			final estado = await guardar();

			final request = backend.de('POST', '/fabrica/unidades/asignaciones').single;
			expect(backend.body(request), {
				'indicadorNroSerie': 'IND-1001',
				'tipo': 'placa',
				'nroSerie': 'PL-2001',
				'productoId': _productoPlacaId,
				'recepcionId': _recepcionId,
				'observacion': 'Cambio de placa por falla de fuente',
			});
			expect(estado.resultado!.instalada.nroSerie, 'PL-2001');
			expect(estado.textoInstalada, 'Placa PL-2001 puesta en el indicador IND-1001.');
			expect(estado.textosRetiradas, ['Placa PL-900']);
		});

		test('elegir una reacondicionada completa el numero y el modelo', () async {
			final conLista = await elegirTipo(TipoUnidad.placa);
			bloc.add(AsignacionReacondicionadaElegida(unidad: conLista.reacondicionadas.single));
			await pumpEventQueue();

			expect(bloc.state.nroSerie, 'PL-500');
			expect(bloc.state.productoId, _productoPlacaId);
			expect(bloc.state.reacondicionadaElegida!.id, _reacondicionadaId);

			// Si despues escribe otro numero, ya no es la reacondicionada.
			bloc.add(const AsignacionCambiada(nroSerie: 'PL-501'));
			await pumpEventQueue();
			expect(bloc.state.reacondicionadaElegida, isNull);
		});

		test('celda: se elige la que sale de las instaladas y va en el body', () async {
			await elegirTipo(TipoUnidad.celda);
			expect(bloc.state.piezasParaRetirar.map((p) => p.nroSerie), ['CE-77']);
			expect(bloc.state.avisoRetirada, 'Si no elegís ninguna, la celda se agrega sin sacar otra.');

			bloc.add(AsignacionRetiradaElegida(pieza: bloc.state.piezasParaRetirar.single));
			bloc.add(const AsignacionCambiada(nroSerie: 'CE-90'));
			await pumpEventQueue();
			expect(bloc.state.retiradaNroSerie, 'CE-77');
			expect(bloc.state.avisoRetirada, isNull);

			backend.responder = (_) => _json(
						{
							'indicador': {'id': _indicadorId, 'nroSerie': 'IND-1001'},
							'instalada': {'id': 'celda-nueva', 'tipo': 'celda', 'nroSerie': 'CE-90', 'estado': 'instalada'},
							'retiradas': [
								{'id': _celdaId, 'tipo': 'celda', 'nroSerie': 'CE-77', 'estado': 'retirada'},
							],
						},
						201,
					);
			final estado = await guardar();

			final body = backend.body(backend.de('POST', '/fabrica/unidades/asignaciones').single);
			expect(body['tipo'], 'celda');
			expect(body['retiradaNroSerie'], 'CE-77');
			expect(body.containsKey('observacion'), isFalse);
			expect(estado.textosRetiradas, ['Celda CE-77']);
		});

		test('tocar de nuevo la pieza que sale la deja sin elegir', () async {
			await elegirTipo(TipoUnidad.placa);
			final placa = bloc.state.piezasParaRetirar.single;
			bloc.add(AsignacionRetiradaElegida(pieza: placa));
			bloc.add(AsignacionRetiradaElegida(pieza: placa));
			await pumpEventQueue();

			expect(bloc.state.retiradaNroSerie, '');
		});

		test('cambiar el tipo quita el modelo, la que sale y trae las reacondicionadas del tipo nuevo', () async {
			await elegirTipo(TipoUnidad.placa);
			bloc.add(const AsignacionCambiada(productoId: _productoPlacaId, retiradaNroSerie: 'PL-900'));
			backend.requests.clear();

			final estado = await elegirTipo(TipoUnidad.celda);

			expect(estado.productoId, isNull);
			expect(estado.retiradaNroSerie, '');
			expect(backend.requests.single.url.queryParameters['tipo'], 'celda');
		});

		test('regla rechazada: mensaje tal cual sin perder lo cargado', () async {
			await elegirTipo(TipoUnidad.placa);
			backend.responder = (_) => _regla(
						409,
						'UNIDAD_EN_OTRO_INDICADOR',
						'La placa PL-2001 figura instalada en el indicador IND-3003.',
						{'indicadorNroSerie': 'IND-3003'},
					);
			bloc.add(const AsignacionCambiada(nroSerie: 'PL-2001', observacion: 'Cambio'));

			final estado = await guardar();

			expect(estado.errorAsignacion, 'La placa PL-2001 figura instalada en el indicador IND-3003.');
			expect(estado.asignada, isFalse);
			expect(estado.tipo, TipoUnidad.placa);
			expect(estado.nroSerie, 'PL-2001');
			expect(estado.observacion, 'Cambio');

			// El proximo intento limpia el error mientras se guarda.
			backend.responder = (_) => _json(_asignacionJson(), 201);
			final enCurso = bloc.stream.firstWhere((s) => s.guardando);
			bloc.add(const AsignacionGuardada());
			expect((await enCurso).errorAsignacion, isNull);
		});

		test('la que sale no esta en el indicador: vuelve a pedir sus piezas', () async {
			await elegirTipo(TipoUnidad.placa);
			backend.responder = (request) => request.method == 'POST'
					? _regla(409, 'RETIRADA_NO_INSTALADA', 'La placa PL-900 no figura instalada en el indicador IND-1001.')
					: _json(
							_unidadJson(
								id: _indicadorId,
								tipo: 'indicador',
								nroSerie: 'IND-1001',
								estado: 'en_servicio_tecnico',
								piezasInstaladas: [
									_unidadJson(id: 'otra-placa', nroSerie: 'PL-777'),
								],
							),
						);
			bloc.add(const AsignacionCambiada(nroSerie: 'PL-2001', retiradaNroSerie: 'PL-900'));

			final actualizado = bloc.stream.firstWhere(
				(s) => s.piezasParaRetirar.any((p) => p.nroSerie == 'PL-777'),
			);
			final estado = await guardar();
			expect(estado.errorAsignacion, 'La placa PL-900 no figura instalada en el indicador IND-1001.');

			final conPiezas = await actualizado;
			expect(backend.de('GET', '/fabrica/unidades/$_indicadorId'), hasLength(1));
			expect(conPiezas.piezasParaRetirar.map((p) => p.nroSerie), ['PL-777']);
			// Lo cargado no se toca: el tecnico corrige.
			expect(conPiezas.retiradaNroSerie, 'PL-900');
			expect(conPiezas.errorAsignacion, isNotNull);
		});

		test('reacondicionada que ya no esta disponible: vuelve a pedir la lista', () async {
			await elegirTipo(TipoUnidad.placa);
			backend.responder = (request) => request.method == 'POST'
					? _regla(409, 'UNIDAD_NO_DISPONIBLE', 'La placa PL-500 no esta disponible para instalar.')
					: _json(_pagina(const [], total: 0, totalPages: 0));
			bloc.add(const AsignacionCambiada(nroSerie: 'PL-500'));

			final sinLista = bloc.stream.firstWhere(
				(s) => !s.cargandoReacondicionadas && s.reacondicionadas.isEmpty,
			);
			final estado = await guardar();
			expect(estado.errorAsignacion, 'La placa PL-500 no esta disponible para instalar.');

			final actualizado = await sinLista;
			expect(backend.de('GET', '/fabrica/unidades'), hasLength(2));
			expect(
				actualizado.avisoReacondicionadas,
				'No hay placas reacondicionadas disponibles: cargá el número de serie de la nueva.',
			);
			expect(actualizado.nroSerie, 'PL-500');
		});

		test('si la lista de reacondicionadas falla, se puede reintentar', () async {
			backend.responder = (_) => http.Response('{"message":"Error interno"}', 500);
			final conError = await elegirTipo(TipoUnidad.placa);
			expect(conError.errorReacondicionadas, isNotNull);

			backend.responder = reacondicionadas;
			final listo = bloc.stream.firstWhere(
				(s) => !s.cargandoReacondicionadas && s.reacondicionadas.isNotEmpty,
			);
			bloc.add(const AsignacionReacondicionadasSolicitadas());
			final estado = await listo;

			expect(estado.errorReacondicionadas, isNull);
			expect(estado.reacondicionadas.single.nroSerie, 'PL-500');
		});

		test('con mas reacondicionadas que las de la pagina avisa que se puede escribir el numero', () async {
			backend.responder = (_) => _json(
						_pagina(
							[_unidadJson(id: _reacondicionadaId, nroSerie: 'PL-500', estado: 'reacondicionada_disponible')],
							total: 25,
							totalPages: 2,
						),
					);
			final estado = await elegirTipo(TipoUnidad.placa);

			expect(
				estado.avisoReacondicionadas,
				'Se muestran 1 de 25: si no está en la lista, escribí su número de serie.',
			);
		});
	});

	group('poner placa/celda: precarga desde el detalle de la recepcion', () {
		Recepcion recepcion(EstadoRecepcion estado) => Recepcion(
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
					piezasInstaladas: const [
						Unidad(id: _placaId, tipo: TipoUnidad.placa, nroSerie: 'PL-900', estado: EstadoUnidad.instalada),
						Unidad(id: _celdaId, tipo: TipoUnidad.celda, nroSerie: 'CE-77', estado: EstadoUnidad.instalada),
					],
				);

		test('precarga el indicador, la recepcion y las piezas instaladas', () {
			final state = RecepcionDetalleState(
				recepcionId: _recepcionId,
				recepcion: recepcion(EstadoRecepcion.enReparacion),
			);

			expect(state.puedePonerPieza, isTrue);
			expect(state.precargaAsignacion, _precarga);
		});

		test('una recepcion devuelta ya no pone piezas', () {
			final state = RecepcionDetalleState(
				recepcionId: _recepcionId,
				recepcion: recepcion(EstadoRecepcion.devuelto),
			);

			expect(state.puedePonerPieza, isFalse);
		});
	});

	group('pestaña piezas', () {
		late _Backend backend;
		late PiezasBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_pagina([_unidadJson()])));
			bloc = PiezasBloc(
				BuscarUnidadesUseCase(backend.fabrica),
				esperaBusqueda: const Duration(milliseconds: 30),
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		bool quieto(PiezasState s) => !s.cargando && !s.actualizando && !s.cargandoMas;

		Future<PiezasState> despachar(PiezasEvent evento) {
			final listo = bloc.stream.skipWhile(quieto).firstWhere(quieto);
			bloc.add(evento);
			return listo;
		}

		test('sin numero de serie ni atajo no pide nada', () async {
			bloc.add(const PiezasSolicitadas());
			await pumpEventQueue();

			expect(backend.requests, isEmpty);
			expect(bloc.state.piezas, isEmpty);
			expect(
				bloc.state.textoVacio,
				'Buscá una pieza por número de serie o mirá las placas reacondicionadas disponibles.',
			);
		});

		test('la busqueda por numero de serie espera a que se deje de tipear y va en q', () async {
			final listo = despachar(const PiezasBusquedaCambiada(texto: 'P'));
			bloc.add(const PiezasBusquedaCambiada(texto: 'PL-9'));
			bloc.add(const PiezasBusquedaCambiada(texto: 'PL-90 '));
			final estado = await listo;

			final request = backend.requests.single;
			expect(request.url.path, endsWith('/fabrica/unidades'));
			expect(request.url.queryParameters, {'q': 'PL-90', 'page': '1', 'limit': '20'});
			expect(estado.piezas.single.nroSerie, 'PL-900');
		});

		test('atajo: placas reacondicionadas disponibles', () async {
			final estado = await despachar(const PiezasReacondicionadasAlternadas(activas: true));

			expect(backend.requests.single.url.queryParameters, {
				'tipo': 'placa',
				'estado': 'reacondicionada_disponible',
				'page': '1',
				'limit': '20',
			});
			expect(estado.soloReacondicionadas, isTrue);
		});

		test('apagar el atajo sin busqueda vacia el listado sin pedir nada', () async {
			await despachar(const PiezasReacondicionadasAlternadas(activas: true));
			backend.requests.clear();

			bloc.add(const PiezasReacondicionadasAlternadas(activas: false));
			await pumpEventQueue();

			expect(backend.requests, isEmpty);
			expect(bloc.state.piezas, isEmpty);
			expect(bloc.state.soloReacondicionadas, isFalse);
		});

		test('pagina siguiente: agrega sin repetir', () async {
			backend.responder = (_) => _json(_pagina([_unidadJson()], total: 2, totalPages: 2));
			await despachar(const PiezasReacondicionadasAlternadas(activas: true));

			backend.responder = (_) => _json(
						_pagina(
							[_unidadJson(), _unidadJson(id: _placaNuevaId, nroSerie: 'PL-2001')],
							page: 2,
							total: 2,
							totalPages: 2,
						),
					);
			final estado = await despachar(const PiezasSiguientePaginaSolicitada());

			expect(backend.requests.last.url.queryParameters['page'], '2');
			expect(estado.piezas.map((p) => p.nroSerie), ['PL-900', 'PL-2001']);
		});

		test('si falla el listado muestra el mensaje del backend', () async {
			backend.responder = (_) => _json({'statusCode': 500, 'message': 'Error interno'}, 500);
			final estado = await despachar(const PiezasBusquedaCambiada(texto: 'PL'));

			expect(estado.errorListado, 'Error interno');
			expect(estado.piezas, isEmpty);
		});
	});

	group('detalle de pieza', () {
		late _Backend backend;
		late PiezaDetalleBloc bloc;

		setUp(() {
			backend = _Backend((request) {
				if (request.url.path.endsWith('/historial')) {
					return _json(_historialJson());
				}
				return _json(_unidadJson(estado: 'reacondicionada_disponible', conProducto: true));
			});
			bloc = PiezaDetalleBloc(
				ObtenerUnidadUseCase(backend.fabrica),
				ObtenerHistorialUnidadUseCase(backend.fabrica),
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<PiezaDetalleState> abrir({String unidadId = _placaId, Unidad? unidad}) {
			final listo = bloc.stream.firstWhere((s) => !s.cargando);
			bloc.add(PiezaDetalleAbierta(unidadId: unidadId, unidad: unidad));
			return listo;
		}

		test('pide la pieza y su historial, del mas viejo al mas nuevo, con textos legibles', () async {
			final estado = await abrir();

			expect(backend.de('GET', '/fabrica/unidades/$_placaId'), hasLength(1));
			expect(backend.de('GET', '/fabrica/unidades/$_placaId/historial'), hasLength(1));
			expect(estado.completo, isTrue);
			expect(estado.unidad!.producto!.nombre, 'Placa ST455');
			expect(estado.esIndicador, isFalse);
			expect(estado.pasos.map((p) => p.titulo).toList(), [
				'Placa dada de alta',
				'Retirada del indicador IND-1001 en fábrica',
				'Ingresó a fábrica para revisión',
				'Derivada a desarrollo',
				'Reparada',
				'Volvió a servicio técnico: reacondicionada disponible',
				'Puesta en el indicador IND-2002 en un servicio',
			]);
			final alta = estado.pasos.first;
			expect(alta.usuario, 'Juan Tecnico');
			expect(alta.fecha, DateTime.utc(2026, 10, 1, 12));
			expect(estado.pasos[2].observacion, 'No da tension en la salida de 5 V');
			expect(estado.pasos[1].usuario, isNull);
		});

		test('un indicador muestra sus piezas instaladas', () async {
			backend.responder = (request) => request.url.path.endsWith('/historial')
					? _json({
							'unidad': {'id': _indicadorId, 'tipo': 'indicador', 'nroSerie': 'IND-1001', 'estado': 'instalada'},
							'movimientos': [
								{'tipo': 'alta'},
								{'tipo': 'recepcion', 'recepcionId': _recepcionId},
								{'tipo': 'devolucion_cliente', 'recepcionId': _recepcionId},
							],
						})
					: _json(
							_unidadJson(
								id: _indicadorId,
								tipo: 'indicador',
								nroSerie: 'IND-1001',
								piezasInstaladas: [
									_unidadJson(nroSerie: 'PL-2001', indicadorActualId: _indicadorId),
									_unidadJson(id: _celdaId, tipo: 'celda', nroSerie: 'CE-77'),
								],
							),
						);

			final estado = await abrir(unidadId: _indicadorId);

			expect(estado.esIndicador, isTrue);
			expect(estado.piezasInstaladas.map((p) => p.nroSerie), ['PL-2001', 'CE-77']);
			expect(estado.pasos.map((p) => p.titulo), [
				'Indicador dado de alta',
				'Llegó a fábrica (recepción del equipo)',
				'Devuelto al cliente',
			]);
		});

		test('con la pieza del listado la muestra mientras llega el resto', () async {
			const delListado = Unidad(
				id: _placaId,
				tipo: TipoUnidad.placa,
				nroSerie: 'PL-900',
				estado: EstadoUnidad.reacondicionadaDisponible,
			);
			final primero = bloc.stream.first;
			bloc.add(const PiezaDetalleAbierta(unidadId: _placaId, unidad: delListado));

			final mientras = await primero;
			expect(mientras.unidad, delListado);
			expect(mientras.cargando, isTrue);
			expect(mientras.completo, isFalse);
		});

		test('si falla la carga muestra el mensaje del backend y se puede reintentar', () async {
			backend.responder = (_) => _json({'statusCode': 404, 'message': 'Pieza no encontrada'}, 404);
			final conError = await abrir();
			expect(conError.errorCarga, 'Pieza no encontrada');
			expect(conError.completo, isFalse);

			backend.responder = (request) => request.url.path.endsWith('/historial')
					? _json(_historialJson())
					: _json(_unidadJson());
			final listo = bloc.stream.firstWhere((s) => !s.cargando);
			bloc.add(const PiezaDetalleRefrescada());
			final estado = await listo;

			expect(estado.errorCarga, isNull);
			expect(estado.completo, isTrue);
		});

		test('un movimiento que la app no conoce no rompe el historial', () {
			final pasos = pasosHistorial(TipoUnidad.celda, const [
				Movimiento(tipo: TipoMovimiento.desconocido),
				Movimiento(tipo: TipoMovimiento.descartada, observacion: '  '),
			]);

			expect(pasos.map((p) => p.titulo), ['Movimiento sin descripción', 'Descartada por irreparable']);
			expect(pasos.last.observacion, isNull);
		});
	});

	group('ingreso abierto desde la recepcion', () {
		testWidgets('quien abre el alta espera hasta volver del detalle del ingreso', (tester) async {
			final backend = _Backend((request) {
				if (request.method == 'POST' && request.url.path.endsWith('/fabrica/ingresos')) {
					return _json(_ingresoJson(), 201);
				}
				if (request.url.path.endsWith('/fabrica/ingresos/$_ingresoId')) {
					return _json(_ingresoJson());
				}
				return _json(const []);
			});
			final servicios = ServicioRepositoryImpl(backend.apiClient, SecureStorageEnMemoria());
			final nuevoIngresoBloc = NuevoIngresoBloc(
				CrearIngresoUseCase(backend.fabrica),
				BuscarClientesUseCase(servicios),
				CrearClienteRapidoUseCase(servicios),
			);
			addTearDown(() async {
				await nuevoIngresoBloc.close();
				await backend.cerrar();
			});

			var cerrado = false;
			await tester.pumpWidget(
				MultiBlocProvider(
					providers: [
						BlocProvider(
							create: (_) => CatalogoBloc(
								ObtenerCatalogosUseCase(CatalogoRepositoryImpl(backend.apiClient)),
							),
						),
						BlocProvider.value(value: nuevoIngresoBloc),
						BlocProvider(
							create: (_) => IngresoDetalleBloc(
								ObtenerIngresoUseCase(backend.fabrica),
								DerivarIngresoUseCase(backend.fabrica),
								CargarFallaIngresoUseCase(backend.fabrica),
								CargarReparacionIngresoUseCase(backend.fabrica),
								RecibirDeDesarrolloUseCase(backend.fabrica),
								ObtenerComponentesUseCase(backend.fabrica),
								ObtenerCausasUseCase(backend.fabrica),
							),
						),
					],
					child: MaterialApp(
						home: Builder(
							builder: (context) => Scaffold(
								body: TextButton(
									onPressed: () async {
										await NuevoIngresoPage.abrir(
											context,
											recepcion: const PrecargaIngresoRecepcion(
												recepcionId: _recepcionId,
												numero: 154,
												clienteNombre: 'Agro SRL',
												indicadorNroSerie: 'IND-1001',
											),
										);
										cerrado = true;
									},
									child: const Text('Ingresar pieza retirada'),
								),
							),
						),
					),
				),
			);

			await tester.tap(find.text('Ingresar pieza retirada'));
			await tester.pumpAndSettle();
			expect(find.byType(NuevoIngresoPage), findsOneWidget);

			nuevoIngresoBloc
				..add(const NuevoIngresoCambiado(
					tipo: TipoUnidad.placa,
					nroSerie: 'PL-900',
					observacionTecnico: 'No da tension',
				))
				..add(const NuevoIngresoGuardado());
			await tester.pumpAndSettle();

			// El alta quedo reemplazada por el detalle, pero todavia no se volvio.
			expect(find.byType(IngresoDetallePage), findsOneWidget);
			expect(find.byType(NuevoIngresoPage), findsNothing);
			expect(cerrado, isFalse);

			tester.state<NavigatorState>(find.byType(Navigator)).pop();
			await tester.pumpAndSettle();

			expect(find.byType(IngresoDetallePage), findsNothing);
			expect(cerrado, isTrue);
		});
	});
}
