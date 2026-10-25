import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cambiar_estado_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/devolver_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_servicio_vinculado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_vinculaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/vincular_servicio_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/nueva_recepcion_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/recepcion_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_servicio_guardado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _recepcionId = '33333333-3333-4333-8333-333333333333';
const String _otraRecepcionId = '34343434-3434-4343-8343-343434343434';
const String _indicadorId = '44444444-4444-4444-8444-444444444444';

const Cliente _cliente = Cliente(id: _clienteId, nombre: 'Agro SRL', cuit: '20304050607');

// Respuesta de la seccion Fabrica de docs/endpoints.md.
Map<String, dynamic> _recepcionJson({String id = _recepcionId, int numero = 154}) => {
			'id': id,
			'numero': numero,
			'cliente': {'id': _clienteId, 'nombre': 'Agro SRL', 'cuit': '20304050607'},
			'indicadorId': _indicadorId,
			'indicador': {
				'id': _indicadorId,
				'tipo': 'indicador',
				'nroSerie': 'IND-1001',
				'estado': 'en_servicio_tecnico',
				'producto': null,
			},
			'queLlego': 'Indicador',
			'sintomaReportado': 'No enciende',
			'fechaRecepcion': '2026-10-24T13:00:00.000Z',
			'estado': 'recibido',
			'historialEstados': [],
			'servicioId': null,
			'ingresos': [],
			'piezasInstaladas': [],
		};

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

/// Backend simulado: el alta responde lo que diga `responderAlta`; el detalle
/// por id devuelve la recepcion pedida y el resto responde vacio.
class _Backend {
	http.Response Function() responderAlta = () => _json(_recepcionJson(), 201);
	late final SecureStorageEnMemoria storage;
	late final ApiClient apiClient;
	late final FabricaRepositoryImpl fabrica;
	late final ServicioRepositoryImpl servicios;

	_Backend() {
		storage = SecureStorageEnMemoria()..valores['jwt_token'] = 'token';
		apiClient = ApiClient(
			MockClient((request) async {
				final path = request.url.path;
				if (request.method == 'POST' && path.endsWith('/fabrica/recepciones')) {
					return responderAlta();
				}
				if (request.method == 'GET' && path.endsWith('/fabrica/recepciones/$_otraRecepcionId')) {
					return _json(_recepcionJson(id: _otraRecepcionId, numero: 120));
				}
				return _json(const []);
			}),
			storage,
		);
		fabrica = FabricaRepositoryImpl(apiClient, storage);
		servicios = ServicioRepositoryImpl(apiClient, storage);
	}
}

void main() {
	late _Backend backend;
	late NuevaRecepcionBloc nuevaRecepcionBloc;
	late bool cerrado;

	/// La pantalla que abre el alta (como "Equipos en fabrica"): marca
	/// `cerrado` recien cuando [NuevaRecepcionPage.abrir] termina.
	///
	/// El backend y el bloc se crean dentro del test: asi sus respuestas
	/// avanzan con los `pump` del tester.
	Future<void> montar(WidgetTester tester, {http.Response Function()? responderAlta}) async {
		backend = _Backend();
		if (responderAlta != null) {
			backend.responderAlta = responderAlta;
		}
		nuevaRecepcionBloc = NuevaRecepcionBloc(
			CrearRecepcionUseCase(backend.fabrica),
			BuscarClientesUseCase(backend.servicios),
			CrearClienteRapidoUseCase(backend.servicios),
		);
		cerrado = false;
		addTearDown(() async {
			await nuevaRecepcionBloc.close();
			await backend.apiClient.dispose();
		});

		await tester.pumpWidget(
			MultiBlocProvider(
				providers: [
					BlocProvider(
						create: (_) => CatalogoBloc(
							ObtenerCatalogosUseCase(CatalogoRepositoryImpl(backend.apiClient)),
						),
					),
					BlocProvider.value(value: nuevaRecepcionBloc),
					BlocProvider(
						create: (_) => RecepcionDetalleBloc(
							ObtenerRecepcionUseCase(backend.fabrica),
							CambiarEstadoRecepcionUseCase(backend.fabrica),
							DevolverRecepcionUseCase(backend.fabrica),
							VincularServicioRecepcionUseCase(backend.fabrica),
							ObtenerServicioVinculadoUseCase(backend.fabrica),
							GuardarVinculacionPendienteUseCase(backend.fabrica),
							ObtenerVinculacionesPendientesUseCase(backend.fabrica),
							QuitarVinculacionPendienteUseCase(backend.fabrica),
							GenerarPdfServicioGuardadoUseCase(backend.servicios, GenerarPdfOrdenServicioUseCase()),
						),
					),
				],
				child: MaterialApp(
					home: Builder(
						builder: (context) => Scaffold(
							body: TextButton(
								onPressed: () async {
									await NuevaRecepcionPage.abrir(context);
									cerrado = true;
								},
								child: const Text('Nueva recepción'),
							),
						),
					),
				),
			),
		);
		await tester.tap(find.text('Nueva recepción'));
		await tester.pumpAndSettle();
		expect(find.byType(NuevaRecepcionPage), findsOneWidget);
	}

	void completar() {
		nuevaRecepcionBloc
			..add(const NuevaRecepcionClienteSeleccionado(cliente: _cliente))
			..add(
				const NuevaRecepcionCambiada(
					indicadorNroSerie: 'IND-1001',
					queLlego: 'Indicador',
					sintomaReportado: 'No enciende',
				),
			);
	}

	group('quien abre la nueva recepcion refresca al volver del detalle', () {
		testWidgets('recepcion creada: espera hasta que se cierra su detalle', (tester) async {
			await montar(tester);
			completar();
			nuevaRecepcionBloc.add(const NuevaRecepcionGuardada());
			await tester.pumpAndSettle();

			// El alta quedo reemplazada por el detalle, pero todavia no se volvio.
			expect(find.byType(RecepcionDetallePage), findsOneWidget);
			expect(find.byType(NuevaRecepcionPage), findsNothing);
			expect(cerrado, isFalse);

			tester.state<NavigatorState>(find.byType(Navigator)).pop();
			await tester.pumpAndSettle();

			expect(find.byType(RecepcionDetallePage), findsNothing);
			expect(cerrado, isTrue);
		});

		testWidgets('recepcion ya abierta: espera hasta que se cierra la existente', (tester) async {
			http.Response yaAbierta() => _json({
						'statusCode': 409,
						'error': 'Conflict',
						'codigo': 'RECEPCION_ABIERTA',
						'mensaje': 'El indicador IND-1001 ya tiene la recepción 120 abierta.',
						'message': 'El indicador IND-1001 ya tiene la recepción 120 abierta.',
						'recepcionId': _otraRecepcionId,
						'numero': 120,
					}, 409);
			await montar(tester, responderAlta: yaAbierta);
			completar();
			nuevaRecepcionBloc.add(const NuevaRecepcionGuardada());
			await tester.pumpAndSettle();

			await tester.tap(find.text('Ver recepción N° 120'));
			await tester.pumpAndSettle();

			expect(find.byType(RecepcionDetallePage), findsOneWidget);
			expect(find.text('Recepción N° 120'), findsOneWidget);
			expect(cerrado, isFalse);

			tester.state<NavigatorState>(find.byType(Navigator)).pop();
			await tester.pumpAndSettle();

			expect(cerrado, isTrue);
		});
	});

	group('salir de la nueva recepcion con Atras', () {
		testWidgets('sin datos cargados sale directo', (tester) async {
			await montar(tester);

			await tester.tap(find.byType(BackButton));
			await tester.pumpAndSettle();

			expect(find.byType(NuevaRecepcionPage), findsNothing);
			expect(cerrado, isTrue);
		});

		testWidgets('con datos cargados pide confirmar y se puede seguir cargando', (tester) async {
			await montar(tester);
			nuevaRecepcionBloc.add(const NuevaRecepcionCambiada(queLlego: 'Indicador'));
			await tester.pumpAndSettle();

			await tester.tap(find.byType(BackButton));
			await tester.pumpAndSettle();
			expect(find.text('¿Salir sin registrar?'), findsOneWidget);

			await tester.tap(find.text('Seguir cargando'));
			await tester.pumpAndSettle();
			expect(find.byType(NuevaRecepcionPage), findsOneWidget);
			expect(nuevaRecepcionBloc.state.queLlego, 'Indicador', reason: 'no se pierde lo cargado');
			expect(cerrado, isFalse);

			await tester.tap(find.byType(BackButton));
			await tester.pumpAndSettle();
			await tester.tap(find.text('Salir'));
			await tester.pumpAndSettle();

			expect(find.byType(NuevaRecepcionPage), findsNothing);
			expect(cerrado, isTrue);
		});
	});
}
