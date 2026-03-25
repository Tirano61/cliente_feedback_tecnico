import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class BuscarClientesUseCase {
	final IServicioRepository _repository;

	BuscarClientesUseCase(this._repository);

	Future<List<Cliente>> ejecutar(String query) {
		return _repository.buscarClientes(query);
	}
}
