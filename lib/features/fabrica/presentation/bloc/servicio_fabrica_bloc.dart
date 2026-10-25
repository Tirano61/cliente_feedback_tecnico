import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';

/// Formulario de servicio que se abre desde una recepcion (canal fabrica).
///
/// Es el mismo `ServicioBloc` en una instancia aparte: el formulario de la
/// pantalla principal queda como lo dejo el tecnico. La pagina lo entrega como
/// `ServicioBloc` al `FormularioServicio`.
class ServicioFabricaBloc extends ServicioBloc {
	ServicioFabricaBloc(
		super.cargarServicioUseCase,
		super.obtenerMisServiciosUseCase,
		super.buscarClientesUseCase,
		super.crearClienteRapidoUseCase,
		super.obtenerCotizacionActualUseCase,
		super.buscarRepuestosUseCase,
		super.generarPdfOrdenServicioUseCase,
		super.subirDocumentoFirmadoUseCase,
		super.encolarDocumentoPendienteUseCase,
		super.obtenerDocumentosPendientesUseCase,
		super.quitarDocumentoPendienteUseCase,
		super.obtenerEnlacePdfDocumentoUseCase,
		super.descargarPdfDocumentoUseCase,
		super.obtenerClienteUseCase,
	);
}
