import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogoBloc extends Bloc<CatalogoEvent, CatalogoState> {
	final ObtenerCatalogosUseCase _obtenerCatalogosUseCase;

	CatalogoBloc(this._obtenerCatalogosUseCase) : super(const CatalogoInitial()) {
		on<CargarCatalogos>(_onCargarCatalogos);
	}

	Future<void> _onCargarCatalogos(
		CargarCatalogos event,
		Emitter<CatalogoState> emit,
	) async {
		emit(const CatalogoLoading());
		try {
			final data = await _obtenerCatalogosUseCase.ejecutar();
			emit(
				CatalogoLoaded(
					diagnosticos: data.diagnosticos,
					resoluciones: data.resoluciones,
					zonas: data.zonas,
					categorias: data.categorias,
					productos: data.productos,
				),
			);
		} catch (_) {
			emit(const CatalogoError(mensaje: 'No se pudieron cargar los catalogos.'));
		}
	}
}
