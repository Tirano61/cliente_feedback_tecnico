import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogoBloc extends Bloc<CatalogoEvent, CatalogoState> {
	final ObtenerCatalogosUseCase _obtenerCatalogosUseCase;

	CatalogoBloc(this._obtenerCatalogosUseCase) : super(const CatalogoLoaded.vacio()) {
		on<CargarCatalogos>(_onCargarCatalogos);
		on<CargarCatalogosBasicos>(_onCargarCatalogosBasicos);
		on<CargarCatalogosProductos>(_onCargarCatalogosProductos);
	}

	Future<void> _onCargarCatalogos(
		CargarCatalogos event,
		Emitter<CatalogoState> emit,
	) async {
		await _onCargarCatalogosBasicos(const CargarCatalogosBasicos(), emit);
		await _onCargarCatalogosProductos(const CargarCatalogosProductos(), emit);
	}

	Future<void> _onCargarCatalogosBasicos(
		CargarCatalogosBasicos event,
		Emitter<CatalogoState> emit,
	) async {
		final actual = state is CatalogoLoaded ? state as CatalogoLoaded : const CatalogoLoaded.vacio();
		if (!event.forzar && actual.tieneBasicos) {
			return;
		}

		emit(actual.copyWith(cargandoBasicos: true));
		try {
			final basicos = await _obtenerCatalogosUseCase.ejecutarBasicos();
			emit(
				actual.copyWith(
					diagnosticos: basicos.diagnosticos,
					resoluciones: basicos.resoluciones,
					zonas: basicos.zonas,
					categorias: basicos.categorias,
					cargandoBasicos: false,
				),
			);
		} catch (_) {
			emit(const CatalogoError(mensaje: 'No se pudieron cargar los catalogos basicos.'));
		}
	}

	Future<void> _onCargarCatalogosProductos(
		CargarCatalogosProductos event,
		Emitter<CatalogoState> emit,
	) async {
		var actual = state is CatalogoLoaded ? state as CatalogoLoaded : const CatalogoLoaded.vacio();
		if (actual.categorias.isEmpty) {
			await _onCargarCatalogosBasicos(const CargarCatalogosBasicos(), emit);
			if (state is! CatalogoLoaded) {
				return;
			}
			actual = state as CatalogoLoaded;
		}

		if (!event.forzar && actual.productos.isNotEmpty) {
			return;
		}

		emit(actual.copyWith(cargandoProductos: true));
		try {
			final productos = await _obtenerCatalogosUseCase.ejecutarProductosPorCategorias(
				actual.categorias,
			);
			emit(
				actual.copyWith(
					productos: productos,
					cargandoProductos: false,
				),
			);
		} catch (_) {
			emit(const CatalogoError(mensaje: 'No se pudieron cargar los productos.'));
		}
	}
}
