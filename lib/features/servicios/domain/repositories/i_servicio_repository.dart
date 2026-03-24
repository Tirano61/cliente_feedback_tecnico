import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';

abstract class IServicioRepository {
	Future<void> cargarServicio(Servicio servicio);

	Future<List<Servicio>> obtenerMisServicios();
}


