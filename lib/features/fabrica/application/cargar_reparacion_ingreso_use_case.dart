import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class CargarReparacionIngresoUseCase {
	final IFabricaRepository _repository;

	CargarReparacionIngresoUseCase(this._repository);

	Future<Ingreso> ejecutar({
		required String ingresoId,
		required SolicitudReparacion solicitud,
	}) {
		return _repository.cargarReparacionIngreso(
			ingresoId: ingresoId,
			solicitud: solicitud,
		);
	}
}
