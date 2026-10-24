import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class CargarFallaIngresoUseCase {
	final IFabricaRepository _repository;

	CargarFallaIngresoUseCase(this._repository);

	Future<Ingreso> ejecutar({
		required String ingresoId,
		required SolicitudFalla solicitud,
	}) {
		return _repository.cargarFallaIngreso(
			ingresoId: ingresoId,
			solicitud: solicitud,
		);
	}
}
