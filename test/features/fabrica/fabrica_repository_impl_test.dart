import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cambiar_estado_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_falla_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_reparacion_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/derivar_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_asignaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/devolver_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_causas_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_componentes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_historial_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingresos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_servicio_vinculado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_vinculaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/recibir_de_desarrollo_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/vincular_servicio_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/asignacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/vinculacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _recepcionId = '33333333-3333-4333-8333-333333333333';
const String _indicadorId = '44444444-4444-4444-8444-444444444444';
const String _placaId = '55555555-5555-4555-8555-555555555555';
const String _placaNuevaId = '56565656-5656-4565-8565-565656565656';
const String _ingresoId = '66666666-6666-4666-8666-666666666666';
const String _tecnicoId = '77777777-7777-4777-8777-777777777777';
const String _productoIndicadorId = '88888888-8888-4888-8888-888888888888';
const String _productoPlacaId = '99999999-9999-4999-8999-999999999999';
const String _componenteId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _causaId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _servicioId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

// Respuestas copiadas de la seccion Fabrica de docs/endpoints.md.

Map<String, dynamic> _recepcionJson({String estado = 'recibido'}) => {
			'id': _recepcionId,
			'numero': 154,
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
			'servicioId': null,
			'fechaDevolucion': null,
			'formaDevolucion': null,
			'observaciones': 'Viene de la sucursal',
			'ingresos': [],
			'piezasInstaladas': [
				{'id': _placaId, 'tipo': 'placa', 'nroSerie': 'PL-900', 'estado': 'instalada'},
			],
		};

Map<String, dynamic> _ingresoJson({
	String estado = 'en_servicio_tecnico',
	Map<String, dynamic>? falla,
	Map<String, dynamic>? reparacion,
}) =>
		{
			'id': _ingresoId,
			'numero': 37,
			'unidadId': _placaId,
			'unidad': {
				'id': _placaId,
				'tipo': 'placa',
				'nroSerie': 'PL-900',
				'estado': 'en_servicio_tecnico',
				'producto': {'id': _productoPlacaId, 'nombre': 'Placa ST455', 'version': 'v3'},
			},
			'clienteOrigen': {'id': _clienteId, 'nombre': 'Agro SRL'},
			'indicadorOrigenId': _indicadorId,
			'indicadorOrigen': {'id': _indicadorId, 'nroSerie': 'IND-1001'},
			'recepcionId': _recepcionId,
			'servicioId': null,
			'tecnico': {'id': _tecnicoId, 'fullName': 'Juan Tecnico'},
			'fechaIngreso': '2026-10-24T13:30:00.000Z',
			'observacionTecnico': 'No da tension en la salida de 5 V',
			'estado': estado,
			'falla': falla,
			'reparacion': reparacion,
		};

final Map<String, dynamic> _fallaJson = {
	'id': 'falla-1',
	'componente': {
		'id': _componenteId,
		'nombre': 'Regulador de tension',
		'productoId': _productoPlacaId,
	},
	'componenteOtro': null,
	'causa': {'id': _causaId, 'nombre': 'Sobretension'},
	'detalle': 'Regulador en corto por sobretension en la alimentacion',
	'usuario': {'id': _tecnicoId, 'fullName': 'Juan Tecnico'},
	'fecha': '2026-10-25T12:00:00.000Z',
};

Map<String, dynamic> _pagina(List<Map<String, dynamic>> data, {int total = 1}) => {
			'data': data,
			'meta': {'page': 1, 'limit': 20, 'total': total, 'totalPages': 1},
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

/// Backend simulado: responde lo que diga `responder` y guarda cada request
/// que llego para revisar metodo, ruta, query y body.
class _Escenario {
	final http.Response Function(http.Request request) responder;
	final List<http.Request> requests = [];
	final SecureStorageEnMemoria storage = SecureStorageEnMemoria();

	late final ApiClient _apiClient;
	late final FabricaRepositoryImpl repositorio;

	_Escenario(this.responder) {
		_apiClient = ApiClient(
			MockClient((request) async {
				requests.add(request);
				return responder(request);
			}),
			storage,
		);
		repositorio = FabricaRepositoryImpl(_apiClient, storage);
	}

	http.Request get unico => requests.single;

	Map<String, dynamic> get body => jsonDecode(unico.body) as Map<String, dynamic>;

	Future<void> cerrar() => _apiClient.dispose();
}

void main() {
	group('recepciones', () {
		test('crear: manda el body de endpoints.md y lee la recepcion completa', () async {
			final escenario = _Escenario((_) => _json(_recepcionJson(), 201));

			final recepcion = await CrearRecepcionUseCase(escenario.repositorio).ejecutar(
				const NuevaRecepcion(
					clienteId: _clienteId,
					indicadorNroSerie: 'IND-1001',
					indicadorProductoId: _productoIndicadorId,
					queLlego: 'Indicador completo con cable de celdas',
					sintomaReportado: 'No enciende',
					observaciones: 'Viene de la sucursal',
				),
			);
			await escenario.cerrar();

			expect(escenario.unico.method, 'POST');
			expect(escenario.unico.url.path, endsWith('/fabrica/recepciones'));
			expect(escenario.body, {
				'clienteId': _clienteId,
				'indicadorNroSerie': 'IND-1001',
				'indicadorProductoId': _productoIndicadorId,
				'queLlego': 'Indicador completo con cable de celdas',
				'sintomaReportado': 'No enciende',
				'observaciones': 'Viene de la sucursal',
			});

			expect(recepcion.id, _recepcionId);
			expect(recepcion.numero, 154);
			expect(recepcion.cliente.nombre, 'Agro SRL');
			expect(recepcion.cliente.cuit, '20304050607');
			expect(recepcion.indicador.tipo, TipoUnidad.indicador);
			expect(recepcion.indicador.nroSerie, 'IND-1001');
			expect(recepcion.indicador.estado, EstadoUnidad.enServicioTecnico);
			expect(recepcion.indicador.producto!.nombre, 'ST455');
			expect(recepcion.indicador.producto!.version, isNull);
			expect(recepcion.tecnicoRecepcion!.fullName, 'Juan Tecnico');
			expect(recepcion.fechaRecepcion, DateTime.utc(2026, 10, 24, 13));
			expect(recepcion.estado, EstadoRecepcion.recibido);
			expect(recepcion.historialEstados.single.estado, EstadoRecepcion.recibido);
			expect(recepcion.historialEstados.single.usuarioNombre, 'Juan Tecnico');
			expect(recepcion.historialEstados.single.observacion, isNull);
			expect(recepcion.servicioId, isNull);
			expect(recepcion.formaDevolucion, isNull);
			expect(recepcion.ingresos, isEmpty);
			expect(recepcion.piezasInstaladas.single.tipo, TipoUnidad.placa);
			expect(recepcion.piezasInstaladas.single.estado, EstadoUnidad.instalada);
		});

		test('crear: los opcionales en null no se mandan', () async {
			final escenario = _Escenario((_) => _json(_recepcionJson(), 201));

			await CrearRecepcionUseCase(escenario.repositorio).ejecutar(
				const NuevaRecepcion(
					clienteId: _clienteId,
					indicadorNroSerie: 'IND-1001',
					queLlego: 'Indicador',
					sintomaReportado: 'No enciende',
				),
			);
			await escenario.cerrar();

			expect(escenario.body.containsKey('indicadorProductoId'), isFalse);
			expect(escenario.body.containsKey('observaciones'), isFalse);
		});

		test('listado: por defecto pide las abiertas y lee data y meta', () async {
			final escenario = _Escenario((_) => _json(_pagina([_recepcionJson()], total: 41)));

			final pagina = await ObtenerRecepcionesUseCase(escenario.repositorio).ejecutar(
				pagina: 1,
				busqueda: '  IND-1001 ',
				estado: EstadoRecepcion.esperandoPresupuesto,
			);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/recepciones'));
			expect(escenario.unico.url.queryParameters, {
				'estado': 'esperando_presupuesto',
				'abiertas': 'true',
				'q': 'IND-1001',
				'page': '1',
				'limit': '20',
			});
			expect(pagina.items.single.numero, 154);
			expect(pagina.total, 41);
			expect(pagina.limite, 20);
		});

		test('listado: con abiertas null trae tambien las devueltas', () async {
			final escenario = _Escenario((_) => _json(_pagina([])));

			await ObtenerRecepcionesUseCase(escenario.repositorio).ejecutar(pagina: 2, abiertas: null);
			await escenario.cerrar();

			expect(escenario.unico.url.queryParameters, {'page': '2', 'limit': '20'});
		});

		test('detalle: GET por id', () async {
			final escenario = _Escenario((_) => _json(_recepcionJson(estado: 'en_reparacion')));

			final recepcion = await ObtenerRecepcionUseCase(escenario.repositorio).ejecutar(_recepcionId);
			await escenario.cerrar();

			expect(escenario.unico.method, 'GET');
			expect(escenario.unico.url.path, endsWith('/fabrica/recepciones/$_recepcionId'));
			expect(recepcion.estado, EstadoRecepcion.enReparacion);
		});

		test('cambio de estado: PATCH con el codigo del estado', () async {
			final escenario = _Escenario((_) => _json(_recepcionJson(estado: 'esperando_presupuesto')));

			final recepcion = await CambiarEstadoRecepcionUseCase(escenario.repositorio).ejecutar(
				recepcionId: _recepcionId,
				estado: EstadoRecepcion.esperandoPresupuesto,
				observacion: 'Se envio presupuesto por WhatsApp',
			);
			await escenario.cerrar();

			expect(escenario.unico.method, 'PATCH');
			expect(escenario.unico.url.path, endsWith('/fabrica/recepciones/$_recepcionId/estado'));
			expect(escenario.body, {
				'estado': 'esperando_presupuesto',
				'observacion': 'Se envio presupuesto por WhatsApp',
			});
			expect(recepcion.estado, EstadoRecepcion.esperandoPresupuesto);
		});

		test('vincular servicio: PATCH con servicioId', () async {
			final escenario = _Escenario(
				(_) => _json({..._recepcionJson(estado: 'en_reparacion'), 'servicioId': _servicioId}),
			);

			final recepcion = await VincularServicioRecepcionUseCase(escenario.repositorio).ejecutar(
				recepcionId: _recepcionId,
				servicioId: _servicioId,
			);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/recepciones/$_recepcionId/servicio'));
			expect(escenario.body, {'servicioId': _servicioId});
			expect(recepcion.servicioId, _servicioId);
		});

		test('devolucion: forma con su codigo y fecha con offset', () async {
			final escenario = _Escenario(
				(_) => _json({
					..._recepcionJson(estado: 'devuelto'),
					'formaDevolucion': 'retira_cliente',
					'fechaDevolucion': '2026-10-28T18:00:00.000Z',
				}),
			);

			final recepcion = await DevolverRecepcionUseCase(escenario.repositorio).ejecutar(
				recepcionId: _recepcionId,
				solicitud: SolicitudDevolucion(
					formaDevolucion: FormaDevolucion.retiraCliente,
					fechaDevolucion: DateTime.utc(2026, 10, 28, 18),
				),
			);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/recepciones/$_recepcionId/devolucion'));
			expect(escenario.body['formaDevolucion'], 'retira_cliente');
			expect(
				DateTime.parse(escenario.body['fechaDevolucion'] as String),
				DateTime.utc(2026, 10, 28, 18),
			);
			expect(escenario.body['fechaDevolucion'], matches(RegExp(r'[+-]\d{2}:\d{2}$')));
			expect(escenario.body.containsKey('observacion'), isFalse);
			expect(recepcion.estado, EstadoRecepcion.devuelto);
			expect(recepcion.formaDevolucion, FormaDevolucion.retiraCliente);
		});

		test('un estado que la app no conoce no rompe el parseo', () async {
			final escenario = _Escenario((_) => _json(_recepcionJson(estado: 'en_garantia')));

			final recepcion = await ObtenerRecepcionUseCase(escenario.repositorio).ejecutar(_recepcionId);
			await escenario.cerrar();

			expect(recepcion.estado, EstadoRecepcion.desconocido);
		});
	});

	group('ingresos', () {
		test('crear sin recepcion: manda cliente de origen y omite los null', () async {
			final escenario = _Escenario((_) => _json(_ingresoJson(), 201));

			final ingreso = await CrearIngresoUseCase(escenario.repositorio).ejecutar(
				const NuevoIngreso(
					tipo: TipoUnidad.celda,
					nroSerie: 'CEL-77',
					clienteOrigenId: _clienteId,
					observacionTecnico: 'Deriva con temperatura',
				),
			);
			await escenario.cerrar();

			expect(escenario.unico.method, 'POST');
			expect(escenario.unico.url.path, endsWith('/fabrica/ingresos'));
			expect(escenario.body, {
				'tipo': 'celda',
				'nroSerie': 'CEL-77',
				'clienteOrigenId': _clienteId,
				'observacionTecnico': 'Deriva con temperatura',
			});
			expect(ingreso.numero, 37);
		});

		test('detalle: lee unidad, origen, falla y reparacion', () async {
			final escenario = _Escenario(
				(_) => _json(
					_ingresoJson(
						estado: 'reparado',
						falla: _fallaJson,
						reparacion: {
							'resultado': 'reparada',
							'trabajoRealizado': 'Cambio de regulador y prueba 24 h',
							'componentesReemplazados': 'LM7805',
						},
					),
				),
			);

			final ingreso = await ObtenerIngresoUseCase(escenario.repositorio).ejecutar(_ingresoId);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/ingresos/$_ingresoId'));
			expect(ingreso.unidad.tipo, TipoUnidad.placa);
			expect(ingreso.unidad.producto!.version, 'v3');
			expect(ingreso.clienteOrigen!.nombre, 'Agro SRL');
			expect(ingreso.clienteOrigen!.cuit, isNull);
			expect(ingreso.indicadorOrigen!.nroSerie, 'IND-1001');
			expect(ingreso.recepcionId, _recepcionId);
			expect(ingreso.servicioId, isNull);
			expect(ingreso.fechaIngreso, DateTime.utc(2026, 10, 24, 13, 30));
			expect(ingreso.estado, EstadoIngreso.reparado);

			final falla = ingreso.falla!;
			expect(falla.componente!.nombre, 'Regulador de tension');
			expect(falla.componente!.productoId, _productoPlacaId);
			expect(falla.componenteOtro, isNull);
			expect(falla.causa!.nombre, 'Sobretension');
			expect(falla.usuario!.fullName, 'Juan Tecnico');
			expect(falla.fecha, DateTime.utc(2026, 10, 25, 12));

			final reparacion = ingreso.reparacion!;
			expect(reparacion.resultado, ResultadoReparacion.reparada);
			expect(reparacion.trabajoRealizado, 'Cambio de regulador y prueba 24 h');
			expect(reparacion.componentesReemplazados, 'LM7805');
		});

		test('listado: filtro por tipo y estado con sus codigos', () async {
			final escenario = _Escenario((_) => _json(_pagina([_ingresoJson()])));

			final pagina = await ObtenerIngresosUseCase(escenario.repositorio).ejecutar(
				pagina: 1,
				tipo: TipoUnidad.placa,
				estado: EstadoIngreso.derivadoDesarrollo,
			);
			await escenario.cerrar();

			expect(escenario.unico.url.queryParameters, {
				'estado': 'derivado_desarrollo',
				'tipo': 'placa',
				'page': '1',
				'limit': '20',
			});
			expect(pagina.items.single.id, _ingresoId);
		});

		test('derivar: PATCH sin body cuando no hay observacion', () async {
			final escenario = _Escenario((_) => _json(_ingresoJson(estado: 'derivado_desarrollo')));

			final ingreso = await DerivarIngresoUseCase(escenario.repositorio).ejecutar(ingresoId: _ingresoId);
			await escenario.cerrar();

			expect(escenario.unico.method, 'PATCH');
			expect(escenario.unico.url.path, endsWith('/fabrica/ingresos/$_ingresoId/derivar'));
			expect(escenario.body, isEmpty);
			expect(ingreso.estado, EstadoIngreso.derivadoDesarrollo);
		});

		test('falla: PUT con todas las claves, aunque vengan en null', () async {
			final escenario = _Escenario((_) => _json(_ingresoJson(falla: _fallaJson)));

			await CargarFallaIngresoUseCase(escenario.repositorio).ejecutar(
				ingresoId: _ingresoId,
				solicitud: const SolicitudFalla(
					componenteId: _componenteId,
					causaId: _causaId,
					detalle: 'Regulador en corto por sobretension en la alimentacion',
				),
			);
			await escenario.cerrar();

			expect(escenario.unico.method, 'PUT');
			expect(escenario.unico.url.path, endsWith('/fabrica/ingresos/$_ingresoId/falla'));
			expect(escenario.body, {
				'componenteId': _componenteId,
				'componenteOtro': null,
				'causaId': _causaId,
				'detalle': 'Regulador en corto por sobretension en la alimentacion',
			});
		});

		test('reparacion: POST con el codigo del resultado', () async {
			final escenario = _Escenario(
				(_) => _json(
					_ingresoJson(
						estado: 'descartado',
						falla: _fallaJson,
						reparacion: {'resultado': 'irreparable'},
					),
					201,
				),
			);

			final ingreso = await CargarReparacionIngresoUseCase(escenario.repositorio).ejecutar(
				ingresoId: _ingresoId,
				solicitud: const SolicitudReparacion(resultado: ResultadoReparacion.irreparable),
			);
			await escenario.cerrar();

			expect(escenario.unico.method, 'POST');
			expect(escenario.unico.url.path, endsWith('/fabrica/ingresos/$_ingresoId/reparacion'));
			expect(escenario.body, {'resultado': 'irreparable'});
			expect(ingreso.estado, EstadoIngreso.descartado);
			expect(ingreso.reparacion!.resultado, ResultadoReparacion.irreparable);
			expect(ingreso.reparacion!.trabajoRealizado, isNull);
		});
	});

	group('vuelta de desarrollo', () {
		test('PATCH a vuelta-servicio-tecnico sin body cuando no hay observacion', () async {
			final escenario = _Escenario(
				(_) => _json(_ingresoJson(estado: 'devuelto_a_servicio_tecnico')),
			);

			final ingreso = await RecibirDeDesarrolloUseCase(escenario.repositorio)
					.ejecutar(ingresoId: _ingresoId);
			await escenario.cerrar();

			expect(escenario.unico.method, 'PATCH');
			expect(
				escenario.unico.url.path,
				endsWith('/fabrica/ingresos/$_ingresoId/vuelta-servicio-tecnico'),
			);
			expect(escenario.body, isEmpty);
			expect(ingreso.estado, EstadoIngreso.devueltoAServicioTecnico);
		});

		test('con observacion la manda', () async {
			final escenario = _Escenario(
				(_) => _json(_ingresoJson(estado: 'devuelto_a_servicio_tecnico')),
			);

			await RecibirDeDesarrolloUseCase(escenario.repositorio)
					.ejecutar(ingresoId: _ingresoId, observacion: 'Probada 24 h');
			await escenario.cerrar();

			expect(escenario.body, {'observacion': 'Probada 24 h'});
		});
	});

	group('servicio vinculado a la recepcion', () {
		test('GET /servicios/:id: fecha, tecnico, diagnostico y resoluciones', () async {
			final escenario = _Escenario(
				(_) => _json({
					'id': _servicioId,
					'canal': 'fabrica',
					'fecha': '2026-10-25T12:00:00.000Z',
					'fechaHoraServicio': '2026-10-25T09:30:00.000Z',
					'sintoma': 'No enciende',
					'diagnosticoDetalle': 'Fuente sin salida de 5 V',
					'tecnico': {'id': _tecnicoId, 'email': 'tecnico@empresa.com', 'fullName': 'Juan Tecnico'},
					'diagnosticoCat': [
						{'id': 'diag-1', 'nombre': 'Fuente', 'activo': true},
						{'id': 'diag-2', 'nombre': 'Conector', 'activo': true},
					],
					'resolucion': [
						{'id': 'res-1', 'nombre': 'Cambio de fuente', 'activo': true},
					],
					'aprobado': false,
				}),
			);

			final servicio = await ObtenerServicioVinculadoUseCase(escenario.repositorio).ejecutar(_servicioId);
			await escenario.cerrar();

			expect(escenario.unico.method, 'GET');
			expect(escenario.unico.url.path, endsWith('/servicios/$_servicioId'));
			expect(servicio.id, _servicioId);
			expect(servicio.fecha, DateTime.utc(2026, 10, 25, 9, 30));
			expect(servicio.tecnicoNombre, 'Juan Tecnico');
			expect(servicio.diagnosticos, ['Fuente', 'Conector']);
			expect(servicio.diagnosticoDetalle, 'Fuente sin salida de 5 V');
			expect(servicio.resoluciones, ['Cambio de fuente']);
		});

		test('sin fecha del servicio usa la de carga; sin relaciones quedan vacias', () async {
			final escenario = _Escenario(
				(_) => _json({'id': _servicioId, 'fecha': '2026-10-25T12:00:00.000Z', 'tecnico': null}),
			);

			final servicio = await ObtenerServicioVinculadoUseCase(escenario.repositorio).ejecutar(_servicioId);
			await escenario.cerrar();

			expect(servicio.fecha, DateTime.utc(2026, 10, 25, 12));
			expect(servicio.tecnicoNombre, isNull);
			expect(servicio.diagnosticos, isEmpty);
			expect(servicio.resoluciones, isEmpty);
		});

		test('servicio de otro tecnico: ServerException con el 403', () async {
			final escenario = _Escenario(
				(_) => _json({'statusCode': 403, 'message': 'No tienes permisos para ver este servicio'}, 403),
			);

			await expectLater(
				ObtenerServicioVinculadoUseCase(escenario.repositorio).ejecutar(_servicioId),
				throwsA(
					isA<ServerException>()
							.having((e) => e.statusCode, 'statusCode', 403)
							.having((e) => e, 'no es regla', isNot(isA<ReglaFabricaException>())),
				),
			);
			await escenario.cerrar();
		});
	});

	group('vinculaciones pendientes en el dispositivo', () {
		const pendiente = VinculacionPendiente(recepcionId: _recepcionId, servicioId: _servicioId);

		test('se guardan, se leen y se quitan por recepcion', () async {
			final escenario = _Escenario((_) => _json({}));
			final repositorio = escenario.repositorio;

			await GuardarVinculacionPendienteUseCase(repositorio).ejecutar(pendiente);
			await GuardarVinculacionPendienteUseCase(repositorio).ejecutar(
				const VinculacionPendiente(recepcionId: 'otra-recepcion', servicioId: 'otro-servicio'),
			);
			expect(await ObtenerVinculacionesPendientesUseCase(repositorio).ejecutar(), hasLength(2));

			await QuitarVinculacionPendienteUseCase(repositorio).ejecutar(_recepcionId);
			expect(
				await ObtenerVinculacionesPendientesUseCase(repositorio).ejecutar(),
				[const VinculacionPendiente(recepcionId: 'otra-recepcion', servicioId: 'otro-servicio')],
			);
			await escenario.cerrar();

			// No hablan con el backend.
			expect(escenario.requests, isEmpty);
		});

		test('una recepcion tiene una sola: la nueva reemplaza a la anterior', () async {
			final escenario = _Escenario((_) => _json({}));
			final repositorio = escenario.repositorio;

			await GuardarVinculacionPendienteUseCase(repositorio).ejecutar(
				const VinculacionPendiente(recepcionId: _recepcionId, servicioId: 'servicio-viejo'),
			);
			await GuardarVinculacionPendienteUseCase(repositorio).ejecutar(pendiente);
			await escenario.cerrar();

			expect(await ObtenerVinculacionesPendientesUseCase(repositorio).ejecutar(), [pendiente]);
		});

		test('lo guardado sobrevive a otra instancia del repositorio (la app se cerro)', () async {
			final antes = _Escenario((_) => _json({}));
			await GuardarVinculacionPendienteUseCase(antes.repositorio).ejecutar(pendiente);
			await antes.cerrar();

			final despues = FabricaRepositoryImpl(
				ApiClient(MockClient((_) async => _json({})), antes.storage),
				antes.storage,
			);

			expect(await ObtenerVinculacionesPendientesUseCase(despues).ejecutar(), [pendiente]);
		});

		test('un valor ilegible en el dispositivo se descarta', () async {
			final escenario = _Escenario((_) => _json({}));
			escenario.storage.valores['fabrica_vinculaciones_pendientes_v1'] = '{roto';
			final repositorio = escenario.repositorio;

			expect(await ObtenerVinculacionesPendientesUseCase(repositorio).ejecutar(), isEmpty);

			escenario.storage.valores['fabrica_vinculaciones_pendientes_v1'] =
					'[{"recepcionId":"$_recepcionId"},{"recepcionId":"$_recepcionId","servicioId":"$_servicioId"}]';
			expect(await ObtenerVinculacionesPendientesUseCase(repositorio).ejecutar(), [pendiente]);
			await escenario.cerrar();
		});
	});

	group('cambios de placa/celda pendientes en el dispositivo', () {
		AsignacionPendiente pendiente(String nroSerie, {String? retirada, String? error}) {
			return AsignacionPendiente(
				solicitud: SolicitudAsignacion(
					indicadorNroSerie: 'IND-1001',
					tipo: TipoUnidad.placa,
					nroSerie: nroSerie,
					productoId: 'producto-placa',
					retiradaNroSerie: retirada,
					servicioId: _servicioId,
				),
				mensajeError: error,
			);
		}

		test('se guardan con el body y el mensaje, en orden, y se quitan por clave', () async {
			final escenario = _Escenario((_) => _json({}));
			final repositorio = escenario.repositorio;
			final primera = pendiente('PL-1', retirada: 'PL-900');
			final segunda = pendiente('PL-2');

			await GuardarAsignacionPendienteUseCase(repositorio).ejecutar(primera);
			await GuardarAsignacionPendienteUseCase(repositorio).ejecutar(segunda);
			// El mismo cambio con el mensaje del intento fallido reemplaza al anterior
			// sin cambiar el orden.
			final conError = primera.conError('La placa PL-1 está descartada.');
			await GuardarAsignacionPendienteUseCase(repositorio).ejecutar(conError);
			expect(await ObtenerAsignacionesPendientesUseCase(repositorio).ejecutar(), [conError, segunda]);

			// La clave no distingue mayusculas ni espacios en el numero de serie.
			expect(pendiente(' pl-2 ').clave, segunda.clave);
			await QuitarAsignacionPendienteUseCase(repositorio).ejecutar(segunda.clave);
			expect(await ObtenerAsignacionesPendientesUseCase(repositorio).ejecutar(), [conError]);
			await escenario.cerrar();

			// No hablan con el backend.
			expect(escenario.requests, isEmpty);
		});

		test('un valor ilegible o incompleto en el dispositivo se descarta', () async {
			final escenario = _Escenario((_) => _json({}));
			final repositorio = escenario.repositorio;
			escenario.storage.valores['fabrica_asignaciones_pendientes_v1'] = '{roto';
			expect(await ObtenerAsignacionesPendientesUseCase(repositorio).ejecutar(), isEmpty);

			escenario.storage.valores['fabrica_asignaciones_pendientes_v1'] = jsonEncode([
				{'solicitud': {'indicadorNroSerie': 'IND-1001', 'tipo': 'placa', 'nroSerie': 'PL-1'}},
				{'solicitud': {'indicadorNroSerie': 'IND-1001', 'tipo': 'indicador', 'nroSerie': 'X', 'servicioId': _servicioId}},
				{
					'solicitud': {
						'indicadorNroSerie': 'IND-1001',
						'tipo': 'placa',
						'nroSerie': 'PL-1',
						'productoId': 'producto-placa',
						'servicioId': _servicioId,
					},
				},
			]);
			expect(await ObtenerAsignacionesPendientesUseCase(repositorio).ejecutar(), [pendiente('PL-1')]);
			await escenario.cerrar();
		});
	});

	group('piezas', () {
		test('reacondicionadas disponibles: filtra por tipo y estado', () async {
			final escenario = _Escenario(
				(_) => _json(
					_pagina([
						{
							'id': _placaId,
							'tipo': 'placa',
							'nroSerie': 'PL-900',
							'estado': 'reacondicionada_disponible',
						},
					]),
				),
			);

			final pagina = await BuscarUnidadesUseCase(escenario.repositorio).ejecutar(
				pagina: 1,
				tipo: TipoUnidad.placa,
				estado: EstadoUnidad.reacondicionadaDisponible,
			);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/unidades'));
			expect(escenario.unico.url.queryParameters, {
				'tipo': 'placa',
				'estado': 'reacondicionada_disponible',
				'page': '1',
				'limit': '20',
			});
			expect(pagina.items.single.estado, EstadoUnidad.reacondicionadaDisponible);
		});

		test('indicador: trae sus piezas instaladas', () async {
			final escenario = _Escenario(
				(_) => _json({
					'id': _indicadorId,
					'tipo': 'indicador',
					'nroSerie': 'IND-1001',
					'estado': 'instalada',
					'piezasInstaladas': [
						{
							'id': _placaId,
							'tipo': 'placa',
							'nroSerie': 'PL-900',
							'estado': 'instalada',
							'indicadorActualId': _indicadorId,
						},
					],
				}),
			);

			final unidad = await ObtenerUnidadUseCase(escenario.repositorio).ejecutar(_indicadorId);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/unidades/$_indicadorId'));
			expect(unidad.tipo, TipoUnidad.indicador);
			expect(unidad.piezasInstaladas.single.indicadorActualId, _indicadorId);
		});

		test('historial: movimientos en el orden del backend, con campos parciales', () async {
			final escenario = _Escenario(
				(_) => _json({
					'unidad': {
						'id': _placaId,
						'tipo': 'placa',
						'nroSerie': 'PL-900',
						'estado': 'reacondicionada_disponible',
					},
					'movimientos': [
						{
							'tipo': 'alta',
							'fecha': '2026-10-01T10:00:00.000Z',
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
						{'tipo': 'instalacion', 'indicador': {'nroSerie': 'IND-2002'}, 'servicioId': _servicioId},
					],
				}),
			);

			final historial = await ObtenerHistorialUnidadUseCase(escenario.repositorio).ejecutar(_placaId);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/unidades/$_placaId/historial'));
			expect(historial.unidad.estado, EstadoUnidad.reacondicionadaDisponible);
			expect(historial.movimientos.map((movimiento) => movimiento.tipo).toList(), [
				TipoMovimiento.alta,
				TipoMovimiento.retiro,
				TipoMovimiento.ingresoFabrica,
				TipoMovimiento.derivacionDesarrollo,
				TipoMovimiento.reparada,
				TipoMovimiento.vueltaAServicioTecnico,
				TipoMovimiento.instalacion,
			]);
			final alta = historial.movimientos.first;
			expect(alta.usuario!.fullName, 'Juan Tecnico');
			expect(alta.usuario!.id, isNull);
			expect(alta.indicador, isNull);
			expect(alta.fecha, DateTime.utc(2026, 10, 1, 10));
			expect(historial.movimientos[1].indicador!.nroSerie, 'IND-1001');
			expect(historial.movimientos[1].recepcionId, _recepcionId);
			expect(historial.movimientos[1].fecha, isNull);
			expect(historial.movimientos.last.servicioId, _servicioId);
		});

		test('asignacion: manda la pieza que entra y la que sale, lee instalada y retiradas', () async {
			final escenario = _Escenario(
				(_) => _json({
					'indicador': {'id': _indicadorId, 'nroSerie': 'IND-1001'},
					'instalada': {
						'id': _placaNuevaId,
						'tipo': 'placa',
						'nroSerie': 'PL-2001',
						'estado': 'instalada',
						'indicadorActualId': _indicadorId,
					},
					'retiradas': [
						{'id': _placaId, 'tipo': 'placa', 'nroSerie': 'PL-900', 'estado': 'retirada'},
					],
				}, 201),
			);

			final resultado = await AsignarUnidadUseCase(escenario.repositorio).ejecutar(
				const SolicitudAsignacion(
					indicadorNroSerie: 'IND-1001',
					tipo: TipoUnidad.placa,
					nroSerie: 'PL-2001',
					productoId: _productoPlacaId,
					retiradaNroSerie: 'PL-900',
					recepcionId: _recepcionId,
					observacion: 'Cambio de placa por falla de fuente',
				),
			);
			await escenario.cerrar();

			expect(escenario.unico.method, 'POST');
			expect(escenario.unico.url.path, endsWith('/fabrica/unidades/asignaciones'));
			expect(escenario.body, {
				'indicadorNroSerie': 'IND-1001',
				'tipo': 'placa',
				'nroSerie': 'PL-2001',
				'productoId': _productoPlacaId,
				'retiradaNroSerie': 'PL-900',
				'recepcionId': _recepcionId,
				'observacion': 'Cambio de placa por falla de fuente',
			});
			expect(resultado.indicador.nroSerie, 'IND-1001');
			expect(resultado.instalada.id, _placaNuevaId);
			expect(resultado.instalada.indicadorActualId, _indicadorId);
			expect(resultado.retiradas.single.estado, EstadoUnidad.retirada);
		});
	});

	group('catalogos de desarrollo', () {
		test('componentes del modelo de la pieza', () async {
			final escenario = _Escenario(
				(_) => _json([
					{'id': _componenteId, 'nombre': 'Regulador de tension', 'productoId': _productoPlacaId, 'activo': true},
				]),
			);

			final componentes = await ObtenerComponentesUseCase(escenario.repositorio).ejecutar(
				productoId: _productoPlacaId,
			);
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/componentes'));
			expect(escenario.unico.url.queryParameters, {'productoId': _productoPlacaId});
			expect(componentes.single.nombre, 'Regulador de tension');
			expect(componentes.single.activo, isTrue);
		});

		test('causas', () async {
			final escenario = _Escenario(
				(_) => _json([
					{'id': _causaId, 'nombre': 'Sobretension', 'activo': true},
				]),
			);

			final causas = await ObtenerCausasUseCase(escenario.repositorio).ejecutar();
			await escenario.cerrar();

			expect(escenario.unico.url.path, endsWith('/fabrica/causas'));
			expect(escenario.unico.url.query, isEmpty);
			expect(causas.single.nombre, 'Sobretension');
		});
	});

	group('errores con codigo', () {
		test('recepcion abierta: conserva codigo, mensaje, status y extra', () async {
			final escenario = _Escenario(
				(_) => _regla(409, 'RECEPCION_ABIERTA', 'El indicador IND-1001 ya esta en fabrica (recepcion 154).', {
					'recepcionId': _recepcionId,
					'numero': 154,
				}),
			);

			final error = await CrearRecepcionUseCase(escenario.repositorio)
					.ejecutar(
						const NuevaRecepcion(
							clienteId: _clienteId,
							indicadorNroSerie: 'IND-1001',
							queLlego: 'Indicador',
							sintomaReportado: 'No enciende',
						),
					)
					.then<Object?>((_) => null, onError: (Object error) => error);
			await escenario.cerrar();

			expect(error, isA<ReglaFabricaException>());
			final regla = error! as ReglaFabricaException;
			expect(regla.codigo, CodigoReglaFabrica.recepcionAbierta);
			expect(regla.mensaje, 'El indicador IND-1001 ya esta en fabrica (recepcion 154).');
			expect(regla.statusCode, 409);
			expect(regla.extra, {'recepcionId': _recepcionId, 'numero': 154});
		});

		test('la excepcion de regla es un ServerException: el BLoC puede mostrar el mensaje sin distinguirla', () async {
			final escenario = _Escenario(
				(_) => _regla(409, 'SERVICIO_REQUERIDO', 'Para pasar a listo para devolver hay que vincular el servicio de fabrica.'),
			);

			await expectLater(
				CambiarEstadoRecepcionUseCase(escenario.repositorio).ejecutar(
					recepcionId: _recepcionId,
					estado: EstadoRecepcion.listoParaDevolver,
				),
				throwsA(
					isA<ServerException>().having(
						(error) => error.mensaje,
						'mensaje',
						'Para pasar a listo para devolver hay que vincular el servicio de fabrica.',
					),
				),
			);
			await escenario.cerrar();
		});

		test('transicion invalida: los permitidos quedan en extra', () async {
			final escenario = _Escenario(
				(_) => _regla(409, 'TRANSICION_INVALIDA', 'No se puede pasar de recibido a listo para devolver.', {
					'estadoActual': 'recibido',
					'permitidos': ['en_reparacion', 'esperando_presupuesto'],
				}),
			);

			await expectLater(
				CambiarEstadoRecepcionUseCase(escenario.repositorio).ejecutar(
					recepcionId: _recepcionId,
					estado: EstadoRecepcion.listoParaDevolver,
				),
				throwsA(
					isA<ReglaFabricaException>()
							.having((error) => error.codigo, 'codigo', CodigoReglaFabrica.transicionInvalida)
							.having((error) => error.extra['estadoActual'], 'estadoActual', 'recibido')
							.having(
								(error) => error.extra['permitidos'],
								'permitidos',
								['en_reparacion', 'esperando_presupuesto'],
							),
				),
			);
			await escenario.cerrar();
		});

		test('400 de regla: ingreso sin recepcion ni cliente de origen', () async {
			final escenario = _Escenario(
				(_) => _regla(400, 'CLIENTE_ORIGEN_REQUERIDO', 'Indica de que cliente o sucursal viene la pieza.'),
			);

			await expectLater(
				CrearIngresoUseCase(escenario.repositorio).ejecutar(
					const NuevoIngreso(tipo: TipoUnidad.placa, nroSerie: 'PL-900'),
				),
				throwsA(
					isA<ReglaFabricaException>()
							.having((error) => error.codigo, 'codigo', CodigoReglaFabrica.clienteOrigenRequerido)
							.having((error) => error.statusCode, 'statusCode', 400)
							.having((error) => error.extra, 'extra', isEmpty),
				),
			);
			await escenario.cerrar();
		});

		test('403 de regla: rol no habilitado', () async {
			final escenario = _Escenario(
				(_) => _regla(403, 'ROL_NO_HABILITADO', 'La falla de una placa la carga desarrollo.'),
			);

			await expectLater(
				CargarFallaIngresoUseCase(escenario.repositorio).ejecutar(
					ingresoId: _ingresoId,
					solicitud: const SolicitudFalla(componenteOtro: 'Fusible', causaId: _causaId),
				),
				throwsA(
					isA<ReglaFabricaException>()
							.having((error) => error.codigo, 'codigo', CodigoReglaFabrica.rolNoHabilitado)
							.having((error) => error.statusCode, 'statusCode', 403),
				),
			);
			await escenario.cerrar();
		});

		test('sin mensaje usa message', () async {
			final escenario = _Escenario(
				(_) => _json({
					'statusCode': 409,
					'codigo': 'CELDA_NO_SE_DERIVA',
					'message': 'Las celdas no se derivan a desarrollo',
				}, 409),
			);

			await expectLater(
				DerivarIngresoUseCase(escenario.repositorio).ejecutar(ingresoId: _ingresoId),
				throwsA(
					isA<ReglaFabricaException>()
							.having((error) => error.codigo, 'codigo', CodigoReglaFabrica.celdaNoSeDeriva)
							.having((error) => error.mensaje, 'mensaje', 'Las celdas no se derivan a desarrollo'),
				),
			);
			await escenario.cerrar();
		});
	});

	group('errores sin codigo', () {
		test('un error comun sigue siendo ServerException con el message del backend', () async {
			final escenario = _Escenario(
				(_) => _json({'statusCode': 404, 'error': 'Not Found', 'message': 'Recepcion no encontrada'}, 404),
			);

			final error = await ObtenerRecepcionUseCase(escenario.repositorio)
					.ejecutar(_recepcionId)
					.then<Object?>((_) => null, onError: (Object error) => error);
			await escenario.cerrar();

			expect(error, isA<ServerException>());
			expect(error, isNot(isA<ReglaFabricaException>()));
			final servidor = error! as ServerException;
			expect(servidor.mensaje, 'Recepcion no encontrada');
			expect(servidor.statusCode, 404);
		});

		test('400 de validacion: usa el primer mensaje de la lista', () async {
			final escenario = _Escenario(
				(_) => _json({
					'statusCode': 400,
					'error': 'Bad Request',
					'message': ['nroSerie should not be empty', 'tipo must be one of: placa, celda'],
				}, 400),
			);

			await expectLater(
				CrearIngresoUseCase(escenario.repositorio).ejecutar(
					const NuevoIngreso(tipo: TipoUnidad.placa, nroSerie: ''),
				),
				throwsA(
					isA<ServerException>().having(
						(error) => error.mensaje,
						'mensaje',
						'nroSerie should not be empty',
					),
				),
			);
			await escenario.cerrar();
		});

		test('500 sin JSON: mensaje propio de la operacion', () async {
			final escenario = _Escenario((_) => http.Response('Internal Server Error', 500));

			await expectLater(
				ObtenerIngresosUseCase(escenario.repositorio).ejecutar(pagina: 1),
				throwsA(
					isA<ServerException>()
							.having((error) => error.mensaje, 'mensaje', 'No se pudo obtener las piezas ingresadas.')
							.having((error) => error.statusCode, 'statusCode', 500),
				),
			);
			await escenario.cerrar();
		});

		test('200 con un body que no se entiende: respuesta invalida', () async {
			final escenario = _Escenario((_) => _json({'data': 'nada'}));

			await expectLater(
				ObtenerRecepcionesUseCase(escenario.repositorio).ejecutar(pagina: 1),
				throwsA(
					isA<ServerException>().having(
						(error) => error.mensaje,
						'mensaje',
						'Respuesta invalida al obtener los equipos en fabrica.',
					),
				),
			);
			await escenario.cerrar();
		});
	});
}
