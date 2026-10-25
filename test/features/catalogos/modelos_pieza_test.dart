import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _categoriaIndicadoresId = '11111111-1111-4111-8111-111111111111';
const String _categoriaCeldasId = '22222222-2222-4222-8222-222222222222';
const String _categoriaAppsId = '33333333-3333-4333-8333-333333333333';
const String _categoriaPlacasId = '44444444-4444-4444-8444-444444444444';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200);

/// Catalogo como el de Render: indicadores, celdas y apps; "Placas" solo si
/// `conPlacas`.
class _Backend {
	final bool conPlacas;
	late final ApiClient apiClient;
	late final CatalogoBloc bloc;

	_Backend({this.conPlacas = false}) {
		apiClient = ApiClient(
			MockClient((request) async {
				final path = request.url.path;
				if (path.endsWith('/categorias-producto')) {
					return _json([
						{'id': _categoriaIndicadoresId, 'nombre': 'Indicadores', 'activo': true},
						{'id': _categoriaCeldasId, 'nombre': 'Celdas', 'activo': true},
						{'id': _categoriaAppsId, 'nombre': 'App movil', 'activo': true},
						if (conPlacas) {'id': _categoriaPlacasId, 'nombre': 'Placas', 'activo': true},
					]);
				}
				if (path.endsWith('/productos')) {
					return _json(switch (request.url.queryParameters['categoriaId']) {
						_categoriaIndicadoresId => [
								{'id': 'p-st455', 'nombre': 'ST455', 'activo': true},
								{'id': 'p-st108', 'nombre': 'ST108', 'activo': true},
							],
						_categoriaCeldasId => [
								{'id': 'p-lc500', 'nombre': 'LC-500', 'activo': true},
								{'id': 'p-czap', 'nombre': 'CZAP 20000', 'activo': true},
								{'id': 'p-vieja', 'nombre': 'Celda vieja', 'activo': false},
							],
						_categoriaAppsId => [
								{'id': 'p-jaguar', 'nombre': 'Jaguar-BLE', 'activo': true},
							],
						_categoriaPlacasId => [
								{'id': 'p-placa455', 'nombre': 'Placa ST455 v3', 'activo': true},
							],
						_ => [],
					});
				}
				// Diagnosticos, resoluciones y zonas no hacen falta aca.
				return _json([]);
			}),
			SecureStorageEnMemoria(),
		);
		bloc = CatalogoBloc(ObtenerCatalogosUseCase(CatalogoRepositoryImpl(apiClient)));
	}

	Future<CatalogoLoaded> cargarProductos() async {
		final listo = bloc.stream.firstWhere(
			(s) => s is CatalogoLoaded && !s.cargandoBasicos && !s.cargandoProductos && s.productos.isNotEmpty,
		);
		bloc.add(const CargarCatalogosProductos());
		return await listo as CatalogoLoaded;
	}

	Future<void> cerrar() async {
		await bloc.close();
		await apiClient.dispose();
	}
}

void main() {
	group('modelos de placa y celda', () {
		test('sin categoria de placas no ofrece otros productos como modelo de placa', () async {
			final backend = _Backend();
			addTearDown(backend.cerrar);

			final catalogo = await backend.cargarProductos();

			expect(catalogo.modelosActivosDe('placa'), isEmpty);
			expect(catalogo.sinModelosDe('placa'), isTrue);
		});

		test('celdas: solo los modelos activos de la categoria de celdas', () async {
			final backend = _Backend();
			addTearDown(backend.cerrar);

			final catalogo = await backend.cargarProductos();

			expect(catalogo.modelosActivosDe('celda').map((p) => p.nombre), ['LC-500', 'CZAP 20000']);
			expect(catalogo.sinModelosDe('celda'), isFalse);
		});

		test('con la categoria "Placas" cargada, ofrece sus modelos', () async {
			final backend = _Backend(conPlacas: true);
			addTearDown(backend.cerrar);

			final catalogo = await backend.cargarProductos();

			expect(catalogo.modelosActivosDe('placa').map((p) => p.nombre), ['Placa ST455 v3']);
			expect(catalogo.sinModelosDe('placa'), isFalse);
		});

		test('mientras el catalogo no llego no avisa que faltan modelos', () async {
			final backend = _Backend();
			addTearDown(backend.cerrar);

			expect((backend.bloc.state as CatalogoLoaded).sinModelosDe('placa'), isFalse);

			final cargando = backend.bloc.stream.firstWhere(
				(s) => s is CatalogoLoaded && (s.cargandoBasicos || s.cargandoProductos),
			);
			backend.bloc.add(const CargarCatalogosProductos());
			expect((await cargando as CatalogoLoaded).sinModelosDe('placa'), isFalse);
		});
	});
}
