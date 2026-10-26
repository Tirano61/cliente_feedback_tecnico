import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class QuitarAsignacionPendienteUseCase {
	final IFabricaRepository _repository;

	QuitarAsignacionPendienteUseCase(this._repository);

	/// `clave`: la de `AsignacionPendiente.clave`.
	Future<void> ejecutar(String clave) {
		return _repository.quitarAsignacionPendiente(clave);
	}
}
