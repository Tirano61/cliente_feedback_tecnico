import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class CrearIngresoUseCase {
	final IFabricaRepository _repository;

	CrearIngresoUseCase(this._repository);

	Future<Ingreso> ejecutar(NuevoIngreso ingreso) {
		return _repository.crearIngreso(ingreso);
	}
}
