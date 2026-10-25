import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerClienteUseCase {
	final IServicioRepository _repository;

	ObtenerClienteUseCase(this._repository);

	Future<Cliente> ejecutar(String clienteId) {
		return _repository.obtenerCliente(clienteId);
	}
}
