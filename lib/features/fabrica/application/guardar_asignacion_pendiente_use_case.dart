import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/asignacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class GuardarAsignacionPendienteUseCase {
	final IFabricaRepository _repository;

	GuardarAsignacionPendienteUseCase(this._repository);

	Future<void> ejecutar(AsignacionPendiente asignacion) {
		return _repository.guardarAsignacionPendiente(asignacion);
	}
}
