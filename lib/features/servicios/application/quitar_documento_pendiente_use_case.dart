import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class QuitarDocumentoPendienteUseCase {
	final IServicioRepository _repository;

	QuitarDocumentoPendienteUseCase(this._repository);

	Future<void> ejecutar(String servicioId) {
		return _repository.quitarDocumentoPendiente(servicioId);
	}
}
