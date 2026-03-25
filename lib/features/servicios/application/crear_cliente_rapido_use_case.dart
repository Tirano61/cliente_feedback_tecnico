import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class CrearClienteRapidoUseCase {
	final IServicioRepository _repository;

	CrearClienteRapidoUseCase(this._repository);

	Future<Cliente> ejecutar(Map<String, dynamic> payloadCliente) {
		return _repository.crearClienteRapido(payloadCliente);
	}
}
