import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_falla_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_reparacion_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/derivar_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_causas_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_componentes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingresos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/recibir_de_desarrollo_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
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
const String _indicadorId = '44444444-4444-4444-8444-444444444444';
const String _placaId = '55555555-5555-4555-8555-555555555555';
const String _celdaId = '57575757-5757-4575-8575-575757575757';
const String _ingresoId = '66666666-6666-4666-8666-666666666666';
const String _otroIngresoId = '67676767-6767-4676-8676-676767676767';
const String _tecnicoId = '77777777-7777-4777-8777-777777777777';
const String _productoPlacaId = '99999999-9999-4999-8999-999999999999';
const String _productoCeldaId = '98989898-9898-4989-8989-989898989898';
const String _componenteId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _causaId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

// Respuestas de la seccion Fabrica de docs/endpoints.md.

Map<String, dynamic> _fallaJson({String? componenteOtro}) => {
			'id': 'falla-1',
			'componente': componenteOtro != null
					? null
					: {'id': _componenteId, 'nombre': 'Galga', 'productoId': _productoCeldaId},
			'componenteOtro': componenteOtro,
			'causa': {'id': _causaId, 'nombre': 'Sobrecarga'},
			'detalle': 'Galga despegada',
			'usuario': {'id': _tecnicoId, 'fullName': 'Juan Tecnico'},
			'fecha': '2026-10-25T12:00:00.000Z',
		};

Map<String, dynamic> _ingresoJson({
	String id = _ingresoId,
	int numero = 37,
	String tipo = 'placa',
	String estado = 'en_servicio_tecnico',
	bool conProducto = true,
	Map<String, dynamic>? falla,
	Map<String, dynamic>? reparacion,
}) {
	final esCelda = tipo == 'celda';
	return {
		'id': id,
		'numero': numero,
		'unidadId': esCelda ? _celdaId : _placaId,
		'unidad': {
			'id': esCelda ? _celdaId : _placaId,
			'tipo': tipo,
			'nroSerie': esCelda ? 'CE-77' : 'PL-900',
			'estado': 'en_servicio_tecnico',
			'producto': !conProducto
					? null
					: esCelda
							? {'id': _productoCeldaId, 'nombre': 'Celda CZAP 20000', 'version': null}
							: {'id': _productoPlacaId, 'nombre': 'Placa ST455', 'version': 'v3'},
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
}

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
				requests.add(request);
				return responder(request);
			}),
			storage,
		);
		fabrica = FabricaRepositoryImpl(apiClient, storage);
		servicios = ServicioRepositoryImpl(apiClient, storage);
	}

	List<http.Request> de(String metodo, String sufijo) => requests
			.where((r) => r.method == metodo && r.url.path.endsWith(sufijo))
			.toList();

	Map<String, dynamic> body(http.Request request) =>
			jsonDecode(request.body) as Map<String, dynamic>;

	Future<void> cerrar() => apiClient.dispose();
}

void main() {
	group('listado de piezas ingresadas', () {
		late _Backend backend;
		late IngresosBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_pagina([_ingresoJson()])));
			bloc = IngresosBloc(
				ObtenerIngresosUseCase(backend.fabrica),
				esperaBusqueda: const Duration(milliseconds: 30),
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		bool quieto(IngresosState s) => !s.cargando && !s.actualizando && !s.cargandoMas;

		Future<IngresosState> esperarQuieto() {
			return bloc.stream.skipWhile(quieto).firstWhere(quieto);
		}

		Future<IngresosState> despachar(IngresosEvent evento) {
			final listo = esperarQuieto();
			bloc.add(evento);
			return listo;
		}

		test('al entrar pide la primera pagina sin filtros', () async {
			final estado = await despachar(const IngresosSolicitados());

			final request = backend.requests.single;
			expect(request.url.path, endsWith('/fabrica/ingresos'));
			expect(request.url.queryParameters, {'page': '1', 'limit': '20'});
			expect(estado.ingresos.single.numero, 37);
			expect(estado.total, 1);
		});

		test('filtro por tipo y por estado van con sus codigos', () async {
			await despachar(const IngresosSolicitados());

			await despachar(const IngresosFiltroTipoCambiado(tipo: TipoUnidad.placa));
			expect(backend.requests.last.url.queryParameters['tipo'], 'placa');

			final conEstado = await despachar(
				const IngresosFiltroEstadoCambiado(estado: EstadoIngreso.derivadoDesarrollo),
			);
			var query = backend.requests.last.url.queryParameters;
			expect(query['tipo'], 'placa');
			expect(query['estado'], 'derivado_desarrollo');
			expect(conEstado.estadosFiltrables, contains(EstadoIngreso.derivadoDesarrollo));

			// Las celdas no van a desarrollo: ese filtro se quita al pasar a celdas.
			final celdas = await despachar(const IngresosFiltroTipoCambiado(tipo: TipoUnidad.celda));
			query = backend.requests.last.url.queryParameters;
			expect(query['tipo'], 'celda');
			expect(query.containsKey('estado'), isFalse);
			expect(celdas.filtroEstado, isNull);
			expect(celdas.estadosFiltrables, [
				EstadoIngreso.enServicioTecnico,
				EstadoIngreso.reparado,
				EstadoIngreso.descartado,
			]);

			// Un estado que las celdas si tienen se conserva al volver a todos.
			await despachar(const IngresosFiltroEstadoCambiado(estado: EstadoIngreso.reparado));
			final todos = await despachar(const IngresosFiltroTipoCambiado(tipo: null));
			query = backend.requests.last.url.queryParameters;
			expect(query.containsKey('tipo'), isFalse);
			expect(query['estado'], 'reparado');
			expect(todos.filtroEstado, EstadoIngreso.reparado);
		});

		test('la busqueda espera a que se deje de tipear y manda un solo pedido', () async {
			await despachar(const IngresosSolicitados());
			final antes = backend.requests.length;

			final listo = esperarQuieto();
			bloc
				..add(const IngresosBusquedaCambiada(texto: 'P'))
				..add(const IngresosBusquedaCambiada(texto: 'PL'))
				..add(const IngresosBusquedaCambiada(texto: ' PL-900 '));
			final estado = await listo;

			expect(backend.requests.length, antes + 1);
			expect(backend.requests.last.url.queryParameters['q'], 'PL-900');
			expect(estado.busqueda, ' PL-900 ', reason: 'el campo conserva lo tipeado');
			expect(estado.hayFiltrosActivos, isTrue);
		});

		test('pagina siguiente: agrega sin repetir y un error no borra lo cargado', () async {
			backend.responder = (request) {
				if (request.url.queryParameters['page'] == '1') {
					return _json(_pagina([_ingresoJson()], total: 2, totalPages: 2));
				}
				return _json(
					_pagina(
						[_ingresoJson(), _ingresoJson(id: _otroIngresoId, numero: 38, tipo: 'celda')],
						page: 2,
						total: 2,
						totalPages: 2,
					),
				);
			};
			final primera = await despachar(const IngresosSolicitados());
			expect(primera.hayMasPaginas, isTrue);

			final segunda = await despachar(const IngresosSiguientePaginaSolicitada());
			expect(segunda.ingresos.map((i) => i.numero), [37, 38]);
			expect(segunda.hayMasPaginas, isFalse);

			backend.responder = (request) => request.url.queryParameters['page'] == '1'
					? _json(_pagina([_ingresoJson()], total: 2, totalPages: 2))
					: _json({'message': 'Fallo interno'}, 500);
			await despachar(const IngresosRefrescados());
			final conError = await despachar(const IngresosSiguientePaginaSolicitada());
			expect(conError.ingresos.map((i) => i.numero), [37]);
			expect(conError.errorPaginacion, 'Fallo interno');
		});

		test('si falla el listado muestra el mensaje del backend', () async {
			backend.responder = (_) => _json({'message': 'Base de datos no disponible'}, 503);

			final estado = await despachar(const IngresosSolicitados());

			expect(estado.ingresos, isEmpty);
			expect(estado.errorListado, 'Base de datos no disponible');
		});
	});

	group('nuevo ingreso', () {
		late _Backend backend;
		late NuevoIngresoBloc bloc;

		const cliente = Cliente(id: _clienteId, nombre: 'Sucursal Rosario', cuit: '30712345678');
		const recepcion = PrecargaIngresoRecepcion(
			recepcionId: _recepcionId,
			numero: 154,
			clienteNombre: 'Agro SRL',
			indicadorNroSerie: 'IND-1001',
			piezasInstaladas: [
				Unidad(id: _indicadorId, tipo: TipoUnidad.indicador, nroSerie: 'IND-1001', estado: EstadoUnidad.instalada),
				Unidad(
					id: _placaId,
					tipo: TipoUnidad.placa,
					nroSerie: 'PL-900',
					estado: EstadoUnidad.instalada,
					producto: ProductoFabrica(id: _productoPlacaId, nombre: 'Placa ST455'),
				),
			],
		);

		setUp(() {
			backend = _Backend((_) => _json(_ingresoJson(), 201));
			bloc = NuevoIngresoBloc(
				CrearIngresoUseCase(backend.fabrica),
				BuscarClientesUseCase(backend.servicios),
				CrearClienteRapidoUseCase(backend.servicios),
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<NuevoIngresoState> guardar() {
			final listo = bloc.stream.firstWhere(
				(s) =>
						!s.guardando &&
						(s.errorMensaje != null || s.ingresoCreado != null || s.ingresoAbierto != null),
			);
			bloc.add(const NuevoIngresoGuardado());
			return listo;
		}

		void completarSinRecepcion() {
			bloc
				..add(const NuevoIngresoIniciado())
				..add(const NuevoIngresoClienteSeleccionado(cliente: cliente))
				..add(
					const NuevoIngresoCambiado(
						tipo: TipoUnidad.placa,
						nroSerie: ' PL-900 ',
						productoId: _productoPlacaId,
						indicadorNroSerie: ' IND-1001 ',
						observacionTecnico: ' No da tension en la salida de 5 V ',
					),
				);
		}

		test('valida en el BLoC al guardar y vuelve a avisar si se insiste', () async {
			bloc.add(const NuevoIngresoIniciado());

			final primero = await guardar();
			expect(
				primero.errorMensaje,
				'Falta completar: tipo de pieza, número de serie, cliente o sucursal de origen, '
				'qué observó el técnico.',
			);

			final segundo = await guardar();
			expect(segundo.errorMensaje, primero.errorMensaje);
			expect(backend.requests, isEmpty);
		});

		test('sin recepcion: manda tipo, serie, modelo, cliente de origen, indicador y observacion', () async {
			completarSinRecepcion();

			final estado = await guardar();

			final request = backend.requests.single;
			expect(request.method, 'POST');
			expect(request.url.path, endsWith('/fabrica/ingresos'));
			expect(backend.body(request), {
				'tipo': 'placa',
				'nroSerie': 'PL-900',
				'productoId': _productoPlacaId,
				'clienteOrigenId': _clienteId,
				'indicadorNroSerie': 'IND-1001',
				'observacionTecnico': 'No da tension en la salida de 5 V',
			});
			expect(estado.ingresoCreado!.id, _ingresoId);
		});

		test('sin recepcion, sin modelo ni indicador: no se mandan', () async {
			bloc
				..add(const NuevoIngresoIniciado())
				..add(const NuevoIngresoClienteSeleccionado(cliente: cliente))
				..add(
					const NuevoIngresoCambiado(
						tipo: TipoUnidad.celda,
						nroSerie: 'CE-77',
						observacionTecnico: 'Lectura inestable',
					),
				);

			await guardar();

			expect(backend.body(backend.requests.single), {
				'tipo': 'celda',
				'nroSerie': 'CE-77',
				'clienteOrigenId': _clienteId,
				'observacionTecnico': 'Lectura inestable',
			});
		});

		test('desde la recepcion: manda recepcionId y no pide cliente', () async {
			bloc
				..add(const NuevoIngresoIniciado(recepcion: recepcion))
				// Lo que se haya escrito de indicador no aplica: sale de la recepcion.
				..add(
					const NuevoIngresoCambiado(
						tipo: TipoUnidad.celda,
						nroSerie: 'CE-77',
						indicadorNroSerie: 'OTRO',
						observacionTecnico: 'Lectura inestable',
					),
				);

			final estado = await guardar();

			expect(backend.body(backend.requests.single), {
				'tipo': 'celda',
				'nroSerie': 'CE-77',
				'recepcionId': _recepcionId,
				'observacionTecnico': 'Lectura inestable',
			});
			expect(estado.ingresoCreado, isNotNull);
		});

		test('desde la recepcion: elegir una pieza instalada completa tipo, serie y modelo', () async {
			bloc.add(const NuevoIngresoIniciado(recepcion: recepcion));
			final iniciado = await bloc.stream.first;
			// El indicador no se ingresa: solo placas y celdas.
			expect(iniciado.piezasInstaladas.map((p) => p.nroSerie), ['PL-900']);

			final elegida = bloc.stream.first;
			bloc.add(NuevoIngresoPiezaInstaladaElegida(pieza: iniciado.piezasInstaladas.single));
			final estado = await elegida;

			expect(estado.tipo, TipoUnidad.placa);
			expect(estado.nroSerie, 'PL-900');
			expect(estado.productoId, _productoPlacaId);
		});

		test('cambiar el tipo quita el modelo elegido', () async {
			bloc
				..add(const NuevoIngresoIniciado())
				..add(const NuevoIngresoCambiado(tipo: TipoUnidad.placa, productoId: _productoPlacaId));
			final conModelo = await bloc.stream.firstWhere((s) => s.productoId != null);
			expect(conModelo.palabraModelo, 'placa');

			final cambiado = bloc.stream.first;
			bloc.add(const NuevoIngresoCambiado(tipo: TipoUnidad.celda));
			final estado = await cambiado;

			expect(estado.productoId, isNull);
			expect(estado.palabraModelo, 'celda');
		});

		test('pieza que ya esta en fabrica: ofrece abrir el ingreso existente y conserva lo cargado', () async {
			backend.responder = (_) => _regla(
						409,
						'INGRESO_ABIERTO',
						'La pieza PL-900 ya esta en fabrica (ingreso 36).',
						{'ingresoId': _otroIngresoId, 'numero': 36},
					);
			completarSinRecepcion();

			final estado = await guardar();

			expect(estado.ingresoAbierto, const IngresoAbiertoExistente(
				ingresoId: _otroIngresoId,
				numero: 36,
				mensaje: 'La pieza PL-900 ya esta en fabrica (ingreso 36).',
			));
			expect(estado.nroSerie, ' PL-900 ');
			expect(estado.clienteOrigen, cliente);
			expect(estado.observacionTecnico, ' No da tension en la salida de 5 V ');
		});

		test('otra regla del backend: mensaje tal cual sin perder el formulario', () async {
			backend.responder = (_) => _regla(
						400,
						'CLIENTE_ORIGEN_REQUERIDO',
						'Sin recepcion hay que indicar de que cliente o sucursal viene la pieza.',
					);
			completarSinRecepcion();

			final estado = await guardar();

			expect(estado.errorMensaje, 'Sin recepcion hay que indicar de que cliente o sucursal viene la pieza.');
			expect(estado.ingresoCreado, isNull);
			expect(estado.tipo, TipoUnidad.placa);
			expect(estado.productoId, _productoPlacaId);
			expect(estado.indicadorNroSerie, ' IND-1001 ');
		});

		test('alta rapida de la sucursal: queda como cliente de origen', () async {
			backend.responder = (request) {
				if (request.url.path.endsWith('/clientes')) {
					return _json({'id': _clienteId, 'cuit': '30712345678', 'nombre': 'Sucursal Rosario'}, 201);
				}
				return _json(_ingresoJson(), 201);
			};
			bloc.add(const NuevoIngresoIniciado());

			final creado = bloc.stream.firstWhere((s) => !s.creandoCliente && s.clienteCreado != null);
			bloc.add(
				const NuevoIngresoClienteRapidoSolicitado(cuit: ' 30712345678 ', nombre: 'Sucursal Rosario'),
			);
			final estado = await creado;

			expect(backend.body(backend.de('POST', '/clientes').single), {
				'cuit': '30712345678',
				'nombre': 'Sucursal Rosario',
			});
			expect(estado.clienteOrigen?.id, _clienteId);
		});
	});

	group('detalle del ingreso', () {
		late _Backend backend;
		late IngresoDetalleBloc bloc;

		setUp(() {
			backend = _Backend((_) => _json(_ingresoJson()));
			bloc = IngresoDetalleBloc(
				ObtenerIngresoUseCase(backend.fabrica),
				DerivarIngresoUseCase(backend.fabrica),
				CargarFallaIngresoUseCase(backend.fabrica),
				CargarReparacionIngresoUseCase(backend.fabrica),
				RecibirDeDesarrolloUseCase(backend.fabrica),
				ObtenerComponentesUseCase(backend.fabrica),
				ObtenerCausasUseCase(backend.fabrica),
			);
		});

		tearDown(() async {
			await bloc.close();
			await backend.cerrar();
		});

		Future<IngresoDetalleState> abrir(Map<String, dynamic> json) async {
			backend.responder = (_) => _json(json);
			final listo = bloc.stream.firstWhere((s) => !s.cargando && s.ingreso != null);
			bloc.add(const IngresoDetalleAbierto(ingresoId: _ingresoId));
			final estado = await listo;
			backend.requests.clear();
			return estado;
		}

		/// Espera a que la accion termine (bien o con error).
		Future<IngresoDetalleState> accion(IngresoDetalleEvent evento) {
			final listo = bloc.stream.firstWhere(
				(s) => !s.procesandoAccion && (s.errorAccion != null || s.exitoMensaje != null),
			);
			bloc.add(evento);
			return listo;
		}

		List<AccionIngreso> acciones(IngresoDetalleState s) => s.acciones.map((a) => a.accion).toList();

		test('abre con GET por id: datos, estado, falla y reparacion', () async {
			final estado = await abrir(
				_ingresoJson(
					tipo: 'celda',
					estado: 'reparado',
					falla: _fallaJson(),
					reparacion: {
						'id': 'rep-1',
						'resultado': 'reparada',
						'trabajoRealizado': 'Cambio de galga',
						'componentesReemplazados': 'Galga 350 ohm',
					},
				),
			);

			final ingreso = estado.ingreso!;
			expect(ingreso.numero, 37);
			expect(ingreso.estado, EstadoIngreso.reparado);
			expect(ingreso.falla!.componente!.nombre, 'Galga');
			expect(ingreso.reparacion!.trabajoRealizado, 'Cambio de galga');
			expect(estado.acciones, isEmpty);
			expect(estado.aviso, 'Quedó reacondicionada, disponible para recambio.');
		});

		test('con la respuesta del alta se muestra sin volver a pedirlo', () async {
			final listo = bloc.stream.first;
			bloc.add(
				IngresoDetalleAbierto(
					ingresoId: _ingresoId,
					ingreso: (await backend.fabrica.obtenerIngreso(_ingresoId)),
				),
			);
			backend.requests.clear();
			final estado = await listo;

			expect(estado.ingreso!.id, _ingresoId);
			expect(backend.requests, isEmpty);
		});

		group('acciones segun tipo y estado', () {
			test('placa en servicio tecnico: solo derivar', () async {
				expect(acciones(await abrir(_ingresoJson())), [AccionIngreso.derivar]);
			});

			test('placa en desarrollo: nada, la carga desarrollo', () async {
				final estado = await abrir(_ingresoJson(estado: 'derivado_desarrollo'));
				expect(estado.acciones, isEmpty);
				expect(estado.aviso, contains('desarrollo'));
			});

			test('placa reparada por desarrollo: recibir de desarrollo', () async {
				expect(acciones(await abrir(_ingresoJson(estado: 'reparado'))), [AccionIngreso.recibirDeDesarrollo]);
			});

			test('celda en servicio tecnico sin falla: cargar falla; la reparacion espera la falla', () async {
				final estado = await abrir(_ingresoJson(tipo: 'celda'));

				expect(acciones(estado), [AccionIngreso.cargarFalla, AccionIngreso.cargarReparacion]);
				final reparacion = estado.acciones.last;
				expect(reparacion.habilitada, isFalse);
				expect(reparacion.motivoBloqueo, ReglasIngreso.motivoFaltaFalla);
			});

			test('celda con falla: se puede corregir y cargar la reparacion', () async {
				final estado = await abrir(_ingresoJson(tipo: 'celda', falla: _fallaJson()));

				expect(estado.acciones.first.etiqueta, 'Corregir falla');
				expect(estado.acciones.every((a) => a.habilitada), isTrue);
			});

			test('celda descartada: nada', () async {
				final estado = await abrir(_ingresoJson(tipo: 'celda', estado: 'descartado'));
				expect(estado.acciones, isEmpty);
				expect(estado.aviso, 'Irreparable: la pieza quedó descartada.');
			});
		});

		test('derivar: PATCH con la observacion y queda derivada', () async {
			await abrir(_ingresoJson());
			backend.responder = (_) => _json(_ingresoJson(estado: 'derivado_desarrollo'));

			final estado = await accion(const IngresoDerivacionSolicitada(observacion: ' Sin 5 V '));

			final request = backend.requests.single;
			expect(request.method, 'PATCH');
			expect(request.url.path, endsWith('/fabrica/ingresos/$_ingresoId/derivar'));
			expect(backend.body(request), {'observacion': 'Sin 5 V'});
			expect(estado.ingreso!.estado, EstadoIngreso.derivadoDesarrollo);
			expect(estado.exitoMensaje, 'Placa derivada a desarrollo.');
			expect(estado.acciones, isEmpty);
		});

		test('una celda no se deriva: no llega al backend', () async {
			await abrir(_ingresoJson(tipo: 'celda'));

			final estado = await accion(const IngresoDerivacionSolicitada());

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, 'No se puede hacer esto con una celda en "En servicio técnico".');
		});

		test('recibir de desarrollo: PATCH a vuelta-servicio-tecnico', () async {
			await abrir(_ingresoJson(estado: 'reparado'));
			backend.responder = (_) => _json(_ingresoJson(estado: 'devuelto_a_servicio_tecnico'));

			final estado = await accion(const IngresoVueltaDesarrolloSolicitada());

			final request = backend.requests.single;
			expect(request.method, 'PATCH');
			expect(request.url.path, endsWith('/fabrica/ingresos/$_ingresoId/vuelta-servicio-tecnico'));
			expect(backend.body(request), isEmpty);
			expect(estado.ingreso!.estado, EstadoIngreso.devueltoAServicioTecnico);
			expect(estado.exitoMensaje, 'Placa recibida de desarrollo: quedó reacondicionada disponible.');
		});

		test('catalogos de la falla: componentes del modelo de la pieza y causas', () async {
			await abrir(_ingresoJson(tipo: 'celda'));
			backend.responder = (request) => request.url.path.endsWith('/fabrica/componentes')
					? _json([
							{'id': _componenteId, 'nombre': 'Galga', 'productoId': _productoCeldaId},
						])
					: _json([
							{'id': _causaId, 'nombre': 'Sobrecarga'},
						]);

			final listo = bloc.stream.firstWhere((s) => s.catalogosFallaCargados);
			bloc.add(const IngresoCatalogosFallaSolicitados());
			final estado = await listo;

			final componentes = backend.de('GET', '/fabrica/componentes').single;
			expect(componentes.url.queryParameters, {'productoId': _productoCeldaId});
			expect(backend.de('GET', '/fabrica/causas'), hasLength(1));
			expect(estado.componentes.single.nombre, 'Galga');
			expect(estado.causas.single.nombre, 'Sobrecarga');

			// Ya estan: no se vuelven a pedir al reabrir el dialogo.
			bloc.add(const IngresoCatalogosFallaSolicitados());
			await pumpEventQueue();
			expect(backend.requests, hasLength(2));
		});

		test('pieza sin modelo: no pide componentes, solo causas', () async {
			await abrir(_ingresoJson(tipo: 'celda', conProducto: false));
			backend.responder = (_) => _json([
						{'id': _causaId, 'nombre': 'Sobrecarga'},
					]);

			final listo = bloc.stream.firstWhere((s) => s.catalogosFallaCargados);
			bloc.add(const IngresoCatalogosFallaSolicitados());
			final estado = await listo;

			expect(backend.de('GET', '/fabrica/componentes'), isEmpty);
			expect(estado.tieneModelo, isFalse);
			expect(estado.componentes, isEmpty);
			expect(estado.causas, hasLength(1));
		});

		test('falla: sin componente ni causa no llega al backend', () async {
			await abrir(_ingresoJson(tipo: 'celda'));

			final estado = await accion(const IngresoFallaSolicitada(componenteOtro: '  '));

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, 'Falta completar: componente que falló, causa.');
		});

		test('falla con "Otro" marcado y sin escribir: pide escribir el componente', () async {
			await abrir(_ingresoJson(tipo: 'celda'));

			final estado = await accion(
				const IngresoFallaSolicitada(usaOtro: true, componenteOtro: '  ', causaId: _causaId),
			);

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, 'Falta completar: escribir qué componente (marcaste "Otro").');
		});

		test('al corregir la falla el aviso anterior se borra', () async {
			await abrir(_ingresoJson(tipo: 'celda'));
			final conAviso = await accion(const IngresoFallaSolicitada(usaOtro: true));
			expect(conAviso.errorAccion, isNotNull);

			// Lo que manda el dialogo cuando el tecnico escribe o elige algo.
			final corregido = bloc.stream.firstWhere((s) => s.errorAccion == null);
			bloc.add(const IngresoErrorAccionDescartado());

			expect((await corregido).errorAccion, isNull);
			expect(backend.requests, isEmpty);
		});

		test('falla con componente del catalogo: PUT con todas las claves', () async {
			await abrir(_ingresoJson(tipo: 'celda'));
			backend.responder = (_) => _json(_ingresoJson(tipo: 'celda', falla: _fallaJson()));

			final estado = await accion(
				const IngresoFallaSolicitada(
					componenteId: _componenteId,
					causaId: _causaId,
					detalle: ' Galga despegada ',
				),
			);

			final request = backend.requests.single;
			expect(request.method, 'PUT');
			expect(request.url.path, endsWith('/fabrica/ingresos/$_ingresoId/falla'));
			expect(backend.body(request), {
				'componenteId': _componenteId,
				'componenteOtro': null,
				'causaId': _causaId,
				'detalle': 'Galga despegada',
			});
			expect(estado.exitoMensaje, 'Falla cargada.');
			expect(estado.ingreso!.falla, isNotNull);
			// Con la falla cargada ya se puede cargar la reparacion.
			expect(estado.acciones.last.habilitada, isTrue);
		});

		test('falla con un componente que no esta en el catalogo: va como otro', () async {
			await abrir(_ingresoJson(tipo: 'celda'));
			backend.responder = (_) => _json(_ingresoJson(tipo: 'celda', falla: _fallaJson(componenteOtro: 'Cable')));

			await accion(const IngresoFallaSolicitada(componenteOtro: ' Cable ', causaId: _causaId));

			expect(backend.body(backend.requests.single), {
				'componenteId': null,
				'componenteOtro': 'Cable',
				'causaId': _causaId,
				'detalle': null,
			});
		});

		test('reparacion sin falla cargada no llega al backend', () async {
			await abrir(_ingresoJson(tipo: 'celda'));

			final estado = await accion(
				const IngresoReparacionSolicitada(
					resultado: ResultadoReparacion.reparada,
					trabajoRealizado: 'Cambio de galga',
				),
			);

			expect(backend.requests, isEmpty);
			expect(estado.errorAccion, ReglasIngreso.motivoFaltaFalla);
		});

		test('reparacion: exige resultado y trabajo realizado', () async {
			await abrir(_ingresoJson(tipo: 'celda', falla: _fallaJson()));

			final estado = await accion(const IngresoReparacionSolicitada(resultado: null));

			expect(backend.requests, isEmpty);
			expect(
				estado.errorAccion,
				'Falta completar: resultado (reparada o irreparable), trabajo realizado.',
			);
		});

		test('reparacion: POST con el resultado y la celda queda descartada', () async {
			await abrir(_ingresoJson(tipo: 'celda', falla: _fallaJson()));
			backend.responder = (_) => _json(
						_ingresoJson(
							tipo: 'celda',
							estado: 'descartado',
							falla: _fallaJson(),
							reparacion: {'resultado': 'irreparable', 'trabajoRealizado': 'Galga cortada'},
						),
						201,
					);

			final estado = await accion(
				const IngresoReparacionSolicitada(
					resultado: ResultadoReparacion.irreparable,
					trabajoRealizado: ' Galga cortada ',
					componentesReemplazados: '  ',
				),
			);

			final request = backend.requests.single;
			expect(request.method, 'POST');
			expect(request.url.path, endsWith('/fabrica/ingresos/$_ingresoId/reparacion'));
			expect(backend.body(request), {'resultado': 'irreparable', 'trabajoRealizado': 'Galga cortada'});
			expect(estado.ingreso!.estado, EstadoIngreso.descartado);
			expect(estado.exitoMensaje, 'Reparación cargada: la celda quedó descartada.');
			expect(estado.acciones, isEmpty);
		});

		test('regla rechazada: mensaje tal cual, conserva el ingreso y lo vuelve a pedir', () async {
			await abrir(_ingresoJson(tipo: 'celda', falla: _fallaJson()));
			backend.responder = (request) => request.method == 'POST'
					? _regla(409, 'REPARACION_YA_REGISTRADA', 'La reparacion ya esta cargada: la falla no se puede cambiar.')
					: _json(_ingresoJson(tipo: 'celda', estado: 'reparado', falla: _fallaJson()));

			final recargado = bloc.stream.firstWhere(
				(s) => !s.cargando && s.ingreso?.estado == EstadoIngreso.reparado,
			);
			final estado = await accion(
				const IngresoReparacionSolicitada(
					resultado: ResultadoReparacion.reparada,
					trabajoRealizado: 'Cambio de galga',
				),
			);

			expect(estado.errorAccion, 'La reparacion ya esta cargada: la falla no se puede cambiar.');
			expect(estado.ingreso!.estado, EstadoIngreso.enServicioTecnico);

			final actualizado = await recargado;
			expect(backend.de('GET', '/fabrica/ingresos/$_ingresoId'), hasLength(1));
			expect(actualizado.acciones, isEmpty);
		});

		test('rol no habilitado: mensaje tal cual y no vuelve a pedir el ingreso', () async {
			await abrir(_ingresoJson(tipo: 'celda'));
			backend.responder = (_) => _regla(
						403,
						'ROL_NO_HABILITADO',
						'La falla de las celdas la carga servicio tecnico.',
					);

			final estado = await accion(
				const IngresoFallaSolicitada(componenteId: _componenteId, causaId: _causaId),
			);
			await pumpEventQueue();

			expect(estado.errorAccion, 'La falla de las celdas la carga servicio tecnico.');
			expect(backend.de('GET', '/fabrica/ingresos/$_ingresoId'), isEmpty);
		});
	});

	group('ingresar pieza retirada desde la recepcion', () {
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
					],
				);

		test('precarga la recepcion y las piezas del indicador', () {
			final state = RecepcionDetalleState(
				recepcionId: _recepcionId,
				recepcion: recepcion(EstadoRecepcion.enReparacion),
			);

			expect(state.puedeIngresarPieza, isTrue);
			expect(
				state.precargaIngreso,
				const PrecargaIngresoRecepcion(
					recepcionId: _recepcionId,
					numero: 154,
					clienteNombre: 'Agro SRL',
					indicadorNroSerie: 'IND-1001',
					piezasInstaladas: [
						Unidad(id: _placaId, tipo: TipoUnidad.placa, nroSerie: 'PL-900', estado: EstadoUnidad.instalada),
					],
				),
			);
		});

		test('una recepcion devuelta ya no ingresa piezas', () {
			final state = RecepcionDetalleState(
				recepcionId: _recepcionId,
				recepcion: recepcion(EstadoRecepcion.devuelto),
			);

			expect(state.puedeIngresarPieza, isFalse);
		});
	});
}
