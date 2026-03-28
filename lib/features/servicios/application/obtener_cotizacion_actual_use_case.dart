import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cotizacion_actual.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerCotizacionActualUseCase {
	final IServicioRepository _repository;

	ObtenerCotizacionActualUseCase(this._repository);

	Future<CotizacionActual> ejecutar() {
		return _repository.obtenerCotizacionActual();
	}
}
