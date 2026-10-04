import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/application/obtener_items_liquidacion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/application/obtener_mis_liquidaciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/infrastructure/datasources/liquidacion_remote_data_source.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/infrastructure/repositories/liquidacion_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_event.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

/// Liquidacion con el shape de GET /liquidaciones/mias (endpoints.md).
Map<String, dynamic> liquidacionJson(int i, String estado, double totalUsd) => {
			'id': 'liq-$i',
			'estado': estado,
			'aprobado': estado == 'aprobada',
			'fechaAprobacion': null,
			'servicio': {
				'id': 'srv-$i',
				'canal': 'campo',
				'fechaHoraServicio': '2026-09-01T10:00:00-03:00',
				'clienteId': 'cli-$i',
				'clienteNombre': 'Cliente $i',
				'lugarProvinciaId': 'zona-1',
				'lugarProvinciaNombre': 'Cordoba',
				'lugarDetalle': 'Campo $i',
			},
			'tipoSalida': {'id': 'ts-1', 'nombre': 'Salida', 'precioUsd': 50},
			'km': 100,
			'precioKmUsdSnapshotLegacy': null,
			'items': <Map<String, dynamic>>[],
			'resumen': {
				'subtotalSalidaUsd': totalUsd,
				'subtotalItemsUsd': 0,
				'totalLiquidacionUsd': totalUsd,
				'cantidadItems': 0,
			},
		};

/// Backend falso que pagina como el real: `{ data, meta }` con page/limit.
MockClient backendPaginado(
	List<Map<String, dynamic>> todas,
	List<Uri> pedidos,
) {
	return MockClient((request) async {
		pedidos.add(request.url);
		final page = int.parse(request.url.queryParameters['page']!);
		final limit = int.parse(request.url.queryParameters['limit']!);
		final inicio = (page - 1) * limit;
		final pagina = todas.skip(inicio).take(limit).toList();
		return http.Response(
			jsonEncode({
				'data': pagina,
				'meta': {
					'page': page,
					'limit': limit,
					'total': todas.length,
					'totalPages': (todas.length / limit).ceil(),
					'estado': 'todas',
				},
			}),
			200,
		);
	});
}

LiquidacionesBloc crearBloc(http.Client client) {
	final storage = SecureStorageEnMemoria()..valores['jwt_token'] = 'token';
	final repo = LiquidacionRepositoryImpl(
		LiquidacionRemoteDataSource(ApiClient(client, storage)),
	);
	return LiquidacionesBloc(
		ObtenerMisLiquidacionesUseCase(repo),
		ObtenerItemsLiquidacionUseCase(repo),
	);
}

Future<LiquidacionesState> cargar(LiquidacionesBloc bloc) async {
	bloc.add(const LiquidacionesSolicitadas());
	return bloc.stream.firstWhere(
		(s) => s is! LiquidacionesLoading && s is! LiquidacionesInitial,
	);
}

void main() {
	test('con mas de 20 liquidaciones, contadores y total salen del conjunto completo',
			() async {
		// 47 liquidaciones: el viejo bug calculaba con las 20 primeras.
		const estados = ['aprobada', 'pendiente', 'aprobada', 'reabierta'];
		final todas = List.generate(
			47,
			(i) => liquidacionJson(i, estados[i % estados.length], 10.0 + i),
		);
		final sumaRealAprobadas = todas
				.where((l) => l['estado'] == 'aprobada')
				.fold<double>(0, (acum, l) => acum + (l['resumen'] as Map)['totalLiquidacionUsd']);
		final sumaPrimeras20 = todas
				.take(20)
				.where((l) => l['estado'] == 'aprobada')
				.fold<double>(0, (acum, l) => acum + (l['resumen'] as Map)['totalLiquidacionUsd']);

		final pedidos = <Uri>[];
		final bloc = crearBloc(backendPaginado(todas, pedidos));

		final state = await cargar(bloc) as LiquidacionesLoaded;

		expect(state.totalAprobadasUsd, sumaRealAprobadas);
		expect(state.totalAprobadasUsd, greaterThan(sumaPrimeras20));
		expect(state.aprobadas, hasLength(24));
		expect(state.pendientes, hasLength(12));
		expect(state.reabiertas, hasLength(11));
		await bloc.close();
	});

	test('itera todas las paginas hasta agotar totalPages', () async {
		final total = ObtenerMisLiquidacionesUseCase.limitePorPagina * 2 + 5;
		final todas = List.generate(total, (i) => liquidacionJson(i, 'aprobada', 1));
		final pedidos = <Uri>[];
		final bloc = crearBloc(backendPaginado(todas, pedidos));

		final state = await cargar(bloc) as LiquidacionesLoaded;

		expect(pedidos.map((u) => u.queryParameters['page']), ['1', '2', '3']);
		expect(state.aprobadas, hasLength(total));
		expect(state.totalAprobadasUsd, total.toDouble());
		await bloc.close();
	});

	test('una liquidacion repetida entre paginas se cuenta una sola vez', () async {
		final limite = ObtenerMisLiquidacionesUseCase.limitePorPagina;
		final todas = List.generate(limite + 1, (i) => liquidacionJson(i, 'aprobada', 1));
		// Simula el corrimiento del offset: la ultima de la pagina 1 reaparece en la 2.
		final conRepetida = [...todas.take(limite), todas[limite - 1], todas[limite]];
		final pedidos = <Uri>[];
		final bloc = crearBloc(backendPaginado(conRepetida, pedidos));

		final state = await cargar(bloc) as LiquidacionesLoaded;

		expect(state.aprobadas, hasLength(limite + 1));
		await bloc.close();
	});

	test('sin liquidaciones hace un solo pedido y queda en cero', () async {
		final pedidos = <Uri>[];
		final bloc = crearBloc(backendPaginado([], pedidos));

		final state = await cargar(bloc) as LiquidacionesLoaded;

		expect(pedidos, hasLength(1));
		expect(state.totalAprobadasUsd, 0);
		expect(state.pendientes, isEmpty);
		await bloc.close();
	});

	test('un 400 ya no se reintenta sin paginacion: termina en error', () async {
		final pedidos = <Uri>[];
		final client = MockClient((request) async {
			pedidos.add(request.url);
			return http.Response(
				jsonEncode({'message': ['property page should not exist']}),
				400,
			);
		});
		final bloc = crearBloc(client);

		final state = await cargar(bloc);

		expect(state, isA<LiquidacionesError>());
		expect(pedidos, hasLength(1));
		expect(pedidos.single.queryParameters, contains('page'));
		await bloc.close();
	});
}
