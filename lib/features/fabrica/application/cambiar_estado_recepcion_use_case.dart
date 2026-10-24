import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class CambiarEstadoRecepcionUseCase {
	final IFabricaRepository _repository;

	CambiarEstadoRecepcionUseCase(this._repository);

	Future<Recepcion> ejecutar({
		required String recepcionId,
		required EstadoRecepcion estado,
		String? observacion,
	}) {
		return _repository.cambiarEstadoRecepcion(
			recepcionId: recepcionId,
			estado: estado,
			observacion: observacion,
		);
	}
}
