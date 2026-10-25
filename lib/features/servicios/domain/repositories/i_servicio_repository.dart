import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cotizacion_actual.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_mis_servicios.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/pagina_servicios.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';

abstract class IServicioRepository {
	/// Da de alta la orden (POST /servicios).
	///
	/// Lanza `ValoresOrdenRechazadosException` si el backend la rechaza porque
	/// la cotizacion, el valor del km o el precio de algun repuesto ya no es el
	/// vigente, y `ServerException` ante cualquier otro error.
	Future<OrdenServicioRespuesta> cargarServicio(Servicio servicio);

	/// GET /servicios/mios. `busqueda` vacia y `aprobado` null no filtran;
	/// `orden` null deja el orden por defecto del backend.
	Future<PaginaServicios> obtenerMisServicios({
		required int pagina,
		required int limite,
		String busqueda = '',
		bool? aprobado,
		OrdenMisServicios? orden,
	});

	Future<List<Cliente>> buscarClientes(String query);

	/// GET /clientes/:id: el cliente con todos sus datos (contacto, telefono,
	/// localidad).
	Future<Cliente> obtenerCliente(String clienteId);

	/// GET /servicios/:id: la orden guardada, con lo necesario para el PDF.
	Future<Servicio> obtenerServicio(String servicioId);

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
