import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class BuscarRepuestosUseCase {
	final IServicioRepository _repository;

	BuscarRepuestosUseCase(this._repository);

	Future<List<Repuesto>> ejecutar(String query) {
		return _repository.buscarRepuestos(query);
	}
}
