import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class VincularServicioRecepcionUseCase {
	final IFabricaRepository _repository;

	VincularServicioRecepcionUseCase(this._repository);

	Future<Recepcion> ejecutar({
		required String recepcionId,
		required String servicioId,
	}) {
		return _repository.vincularServicioRecepcion(
			recepcionId: recepcionId,
			servicioId: servicioId,
		);
	}
}
