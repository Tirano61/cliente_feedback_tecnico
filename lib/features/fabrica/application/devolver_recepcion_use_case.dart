import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class DevolverRecepcionUseCase {
	final IFabricaRepository _repository;

	DevolverRecepcionUseCase(this._repository);

	Future<Recepcion> ejecutar({
		required String recepcionId,
		required SolicitudDevolucion solicitud,
	}) {
		return _repository.devolverRecepcion(
			recepcionId: recepcionId,
			solicitud: solicitud,
		);
	}
}
