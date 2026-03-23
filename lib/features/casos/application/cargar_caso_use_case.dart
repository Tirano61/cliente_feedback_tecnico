import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/repositories/i_caso_repository.dart';

class CargarCasoUseCase {
	final ICasoRepository _repository;

	CargarCasoUseCase(this._repository);

	Future<void> ejecutar(Caso caso) {
		return _repository.cargarCaso(caso);
	}
}
