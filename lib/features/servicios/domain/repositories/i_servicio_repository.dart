import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';

abstract class IServicioRepository {
	Future<void> cargarServicio(Servicio servicio);

	Future<List<Servicio>> obtenerMisServicios();

	Future<List<Cliente>> buscarClientes(String query);

	Future<Cliente> crearClienteRapido(Map<String, dynamic> payloadCliente);
}


