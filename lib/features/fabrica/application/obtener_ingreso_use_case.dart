import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerIngresoUseCase {
	final IFabricaRepository _repository;

	ObtenerIngresoUseCase(this._repository);

	Future<Ingreso> ejecutar(String ingresoId) {
		return _repository.obtenerIngreso(ingresoId);
	}
}
