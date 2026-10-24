import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerRecepcionUseCase {
	final IFabricaRepository _repository;

	ObtenerRecepcionUseCase(this._repository);

	Future<Recepcion> ejecutar(String recepcionId) {
		return _repository.obtenerRecepcion(recepcionId);
	}
}
