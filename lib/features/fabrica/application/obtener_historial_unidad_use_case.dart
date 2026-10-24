import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerHistorialUnidadUseCase {
	final IFabricaRepository _repository;

	ObtenerHistorialUnidadUseCase(this._repository);

	Future<HistorialUnidad> ejecutar(String unidadId) {
		return _repository.obtenerHistorialUnidad(unidadId);
	}
}
