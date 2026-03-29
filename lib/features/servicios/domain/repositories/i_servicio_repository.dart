import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cotizacion_actual.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';

abstract class IServicioRepository {
	Future<OrdenServicioRespuesta> cargarServicio(Servicio servicio);

	Future<List<Servicio>> obtenerMisServicios();

	Future<List<Cliente>> buscarClientes(String query);

	Future<CotizacionActual> obtenerCotizacionActual();

	Future<List<Repuesto>> buscarRepuestos(String query);

	Future<Cliente> crearClienteRapido(Map<String, dynamic> payloadCliente);

	Future<OrdenServicioRespuesta> subirDocumentoFirmado(
		SolicitudDocumentoFirmado solicitud,
	);

	Future<void> encolarDocumentoPendiente(SolicitudDocumentoFirmado solicitud);

	Future<List<SolicitudDocumentoFirmado>> obtenerDocumentosPendientes();

	Future<void> quitarDocumentoPendiente(String servicioId);
}


