import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/vinculacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class GuardarVinculacionPendienteUseCase {
	final IFabricaRepository _repository;

	GuardarVinculacionPendienteUseCase(this._repository);

	Future<void> ejecutar(VinculacionPendiente vinculacion) {
		return _repository.guardarVinculacionPendiente(vinculacion);
	}
}
