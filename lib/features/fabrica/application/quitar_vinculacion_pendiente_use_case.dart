import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class QuitarVinculacionPendienteUseCase {
	final IFabricaRepository _repository;

	QuitarVinculacionPendienteUseCase(this._repository);

	Future<void> ejecutar(String recepcionId) {
		return _repository.quitarVinculacionPendiente(recepcionId);
	}
}
