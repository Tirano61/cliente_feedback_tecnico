import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerMisServiciosUseCase {
	final IServicioRepository _repository;

	ObtenerMisServiciosUseCase(this._repository);

	Future<List<Servicio>> ejecutar() {
		return _repository.obtenerMisServicios();
	}
}


