import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/repositories/i_caso_repository.dart';

class ObtenerMisCasosUseCase {
	final ICasoRepository _repository;

	ObtenerMisCasosUseCase(this._repository);

	Future<List<Caso>> ejecutar() {
		return _repository.obtenerMisCasos();
	}
}
