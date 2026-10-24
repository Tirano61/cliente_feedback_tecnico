import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class CrearRecepcionUseCase {
	final IFabricaRepository _repository;

	CrearRecepcionUseCase(this._repository);

	Future<Recepcion> ejecutar(NuevaRecepcion recepcion) {
		return _repository.crearRecepcion(recepcion);
	}
}
