import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class CargarServicioUseCase {
	final IServicioRepository _repository;

	CargarServicioUseCase(this._repository);

	Future<OrdenServicioRespuesta> ejecutar(Servicio servicio) {
		return _repository.cargarServicio(servicio);
	}
}


