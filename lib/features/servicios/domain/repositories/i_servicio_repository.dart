import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cotizacion_actual.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/pagina_servicios.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';

abstract class IServicioRepository {
	Future<OrdenServicioRespuesta> cargarServicio(Servicio servicio);

	/// GET /servicios/mios. `busqueda` vacia y `aprobado` null no filtran.
	Future<PaginaServicios> obtenerMisServicios({
		required int pagina,
		required int limite,
		String busqueda = '',
		bool? aprobado,
	});

	Future<List<Cliente>> buscarClientes(String query);

	Future<CotizacionActual> obtenerCotizacionActual();

	Future<List<Repuesto>> buscarRepuestos(String query);

	Future<Cliente> crearClienteRapido(Map<String, dynamic> payloadCliente);

	Future<OrdenServicioRespuesta> subirDocumentoFirmado(
		SolicitudDocumentoFirmado solicitud,
	);

	/// Enlace publico del PDF de la orden, ya absoluto y listo para compartir.
	/// Devuelve null cuando la orden todavia no tiene documento cargado.
	Future<String?> obtenerEnlacePdfDocumento(String servicioId);

	/// Bytes del PDF de la orden para abrirlo o guardarlo.
	/// Devuelve null cuando la orden todavia no tiene PDF disponible.
	Future<Uint8List?> descargarPdfDocumento(String servicioId);

	Future<void> encolarDocumentoPendiente(SolicitudDocumentoFirmado solicitud);

	Future<List<SolicitudDocumentoFirmado>> obtenerDocumentosPendientes();

	Future<void> quitarDocumentoPendiente(String servicioId);
}
