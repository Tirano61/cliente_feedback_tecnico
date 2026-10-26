import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/asignacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerAsignacionesPendientesUseCase {
	final IFabricaRepository _repository;

	ObtenerAsignacionesPendientesUseCase(this._repository);

	Future<List<AsignacionPendiente>> ejecutar() {
		return _repository.obtenerAsignacionesPendientes();
	}
}
