import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerUnidadUseCase {
	final IFabricaRepository _repository;

	ObtenerUnidadUseCase(this._repository);

	Future<Unidad> ejecutar(String unidadId) {
		return _repository.obtenerUnidad(unidadId);
	}
}
