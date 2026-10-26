import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/filtro_estado_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/precarga_formulario_servicio.dart';
import 'package:equatable/equatable.dart';

abstract class ServicioEvent extends Equatable {
	const ServicioEvent();

	@override
	List<Object?> get props => [];
}

class ServicioFormularioCambiado extends ServicioEvent {
	final Canal? canal;
	final String? zonaId;
	final List<ProductoFalla>? productosFallaSeleccionados;
	final String? clienteId;
	final String? lugarDetalle;
	final String? equipoNroSerie;
	final String? equipoModelo;
	final String? equipoModeloProductoId;
	final String? equipoUbicacion;
	final String? equipoAnio;
	final String? partesFallaronTexto;
	final String? km;
	final String? precioServicioUsd;
	final String? sintoma;
	final List<String>? diagnosticoCatIdsSeleccionados;
	final String? diagnosticoDetalle;
	final List<String>? resolucionIdsSeleccionados;
	final String? observaciones;

	const ServicioFormularioCambiado({
		this.canal,
		this.zonaId,
		this.productosFallaSeleccionados,
		this.clienteId,
		this.lugarDetalle,
		this.equipoNroSerie,
		this.equipoModelo,
		this.equipoModeloProductoId,
		this.equipoUbicacion,
		this.equipoAnio,
		this.partesFallaronTexto,
		this.km,
		this.precioServicioUsd,
		this.sintoma,
		this.diagnosticoCatIdsSeleccionados,
		this.diagnosticoDetalle,
		this.resolucionIdsSeleccionados,
		this.observaciones,
	});

	@override
	List<Object?> get props => [
				canal,
				zonaId,
				productosFallaSeleccionados,
				clienteId,
				lugarDetalle,
				equipoNroSerie,
				equipoModelo,
				equipoModeloProductoId,
				equipoUbicacion,
				equipoAnio,
				partesFallaronTexto,
				km,
				precioServicioUsd,
				sintoma,
				diagnosticoCatIdsSeleccionados,
				diagnosticoDetalle,
				resolucionIdsSeleccionados,
				observaciones,
			];
}

class ServicioBuscarClienteSolicitado extends ServicioEvent {
	final String query;

	const ServicioBuscarClienteSolicitado({required this.query});

	@override
	List<Object?> get props => [query];
}

class ServicioClienteSeleccionado extends ServicioEvent {
	final Cliente cliente;

	const ServicioClienteSeleccionado({required this.cliente});

	@override
	List<Object?> get props => [cliente];
}

class ServicioCrearClienteRapidoSolicitado extends ServicioEvent {
	final String payloadJson;

	const ServicioCrearClienteRapidoSolicitado({required this.payloadJson});

	@override
	List<Object?> get props => [payloadJson];
}

/// "Agregar placa" / "Agregar celda" en el cambio de placa/celda (canal
/// campo). Trae las reacondicionadas de ese tipo si todavia no estan.
class ServicioCambioPiezaAgregado extends ServicioEvent {
	final TipoUnidad tipo;

	const ServicioCambioPiezaAgregado({required this.tipo});

	@override
	List<Object?> get props => [tipo];
}

/// Solo cambian los campos que vienen; `limpiarProducto` quita el modelo.
/// Cambiar el tipo quita el modelo (es de otro tipo).
class ServicioCambioPiezaCambiado extends ServicioEvent {
	final int id;
	final TipoUnidad? tipo;
	final String? nroSerie;
	final String? productoId;
	final bool limpiarProducto;
	final String? retiradaNroSerie;

	const ServicioCambioPiezaCambiado({
		required this.id,
		this.tipo,
		this.nroSerie,
		this.productoId,
		this.limpiarProducto = false,
		this.retiradaNroSerie,
	});

	@override
	List<Object?> get props => [id, tipo, nroSerie, productoId, limpiarProducto, retiradaNroSerie];
}

/// Eligio una reacondicionada disponible: completa numero de serie y modelo.
class ServicioCambioPiezaReacondicionadaElegida extends ServicioEvent {
	final int id;
	final Unidad unidad;

	const ServicioCambioPiezaReacondicionadaElegida({required this.id, required this.unidad});

	@override
	List<Object?> get props => [id, unidad];
}

class ServicioCambioPiezaQuitado extends ServicioEvent {
	final int id;

	const ServicioCambioPiezaQuitado({required this.id});

	@override
	List<Object?> get props => [id];
}

/// "Reintentar" la lista de reacondicionadas de un tipo.
class ServicioReacondicionadasSolicitadas extends ServicioEvent {
	final TipoUnidad tipo;

	const ServicioReacondicionadasSolicitadas({required this.tipo});

	@override
	List<Object?> get props => [tipo];
}

/// Vuelve a registrar los cambios de placa/celda que quedaron pendientes: los
/// de `servicioId` (desde el aviso de exito) o todos (desde Mis servicios).
/// Nunca vuelve a crear el servicio.
class ServicioAsignacionesPendientesReintentadas extends ServicioEvent {
	final String? servicioId;

	const ServicioAsignacionesPendientesReintentadas({this.servicioId});

	@override
	List<Object?> get props => [servicioId];
}

/// El tecnico decide no registrar un cambio pendiente (por ejemplo porque el
/// backend lo rechaza siempre). `clave`: la de `AsignacionPendiente.clave`.
class ServicioAsignacionPendienteDescartada extends ServicioEvent {
	final String clave;

	const ServicioAsignacionPendienteDescartada({required this.clave});

	@override
	List<Object?> get props => [clave];
}

class ServicioGuardarPressed extends ServicioEvent {
	const ServicioGuardarPressed();
}

class MisServiciosSolicitados extends ServicioEvent {
	const MisServiciosSolicitados();
}

/// Formulario vacio, o con `precarga` (canal fijo y datos del equipo).
class ServicioFormularioReiniciado extends ServicioEvent {
	final PrecargaFormularioServicio? precarga;

	const ServicioFormularioReiniciado({this.precarga});

	@override
	List<Object?> get props => [precarga];
}

class ServicioFacturacionInicializada extends ServicioEvent {
	const ServicioFacturacionInicializada();
}

class ServicioBuscarRepuestosSolicitado extends ServicioEvent {
	final String query;

	const ServicioBuscarRepuestosSolicitado({required this.query});

	@override
	List<Object?> get props => [query];
}

class ServicioRepuestoAgregado extends ServicioEvent {
	final Repuesto repuesto;

	const ServicioRepuestoAgregado({required this.repuesto});

	@override
	List<Object?> get props => [repuesto];
}

class ServicioRepuestoCantidadCambiada extends ServicioEvent {
	final String repuestoId;
	final String cantidad;

	const ServicioRepuestoCantidadCambiada({
		required this.repuestoId,
		required this.cantidad,
	});

	@override
	List<Object?> get props => [repuestoId, cantidad];
}

class ServicioRepuestoEliminado extends ServicioEvent {
	final String repuestoId;

	const ServicioRepuestoEliminado({required this.repuestoId});

	@override
	List<Object?> get props => [repuestoId];
}

class ServicioFacturacionParametrosCambiados extends ServicioEvent {
	final String? ivaPorcentaje;
	final String? descuentoPorcentaje;

	const ServicioFacturacionParametrosCambiados({
		this.ivaPorcentaje,
		this.descuentoPorcentaje,
	});

	@override
	List<Object?> get props => [ivaPorcentaje, descuentoPorcentaje];
}

class ServicioDocumentoSubidaSolicitada extends ServicioEvent {
	final String servicioId;
	final OrdenServicioRespuesta? orden;
	final Canal canal;
	final Uint8List pdfBytes;
	final Uint8List? firmaClienteTrazoPng;
	final String nombreArchivoPdf;
	final String rutaPdfLocal;
	final String? firmaClienteNombre;
	final String? firmaClienteDocumento;
	final DateTime? firmaFechaHora;

	const ServicioDocumentoSubidaSolicitada({
		required this.servicioId,
		this.orden,
		required this.canal,
		required this.pdfBytes,
		this.firmaClienteTrazoPng,
		required this.nombreArchivoPdf,
		required this.rutaPdfLocal,
		this.firmaClienteNombre,
		this.firmaClienteDocumento,
		this.firmaFechaHora,
	});

	@override
	List<Object?> get props => [
				servicioId,
				orden,
				canal,
				pdfBytes,
				firmaClienteTrazoPng,
				nombreArchivoPdf,
				rutaPdfLocal,
				firmaClienteNombre,
				firmaClienteDocumento,
				firmaFechaHora,
			];
}

class ServicioDocumentoPendientesReintentarSolicitado extends ServicioEvent {
	const ServicioDocumentoPendientesReintentarSolicitado();
}

class ServicioDocumentoSubirAhoraSolicitado extends ServicioEvent {
	final Servicio servicio;

	const ServicioDocumentoSubirAhoraSolicitado({required this.servicio});

	@override
	List<Object?> get props => [servicio];
}



/// Pregunta al backend, orden por orden, si ya existe el PDF del documento.
/// Lo dispara el propio bloc despues de cargar el listado.
class MisServiciosDisponibilidadPdfSolicitada extends ServicioEvent {
	const MisServiciosDisponibilidadPdfSolicitada();
}

class MisServiciosFiltroEstadoCambiado extends ServicioEvent {
	final FiltroEstadoServicio filtro;

	const MisServiciosFiltroEstadoCambiado({required this.filtro});

	@override
	List<Object?> get props => [filtro];
}

class MisServiciosBusquedaCambiada extends ServicioEvent {
	final String texto;

	const MisServiciosBusquedaCambiada({required this.texto});

	@override
	List<Object?> get props => [texto];
}

/// El tecnico llego al final del listado (o toco "Cargar mas"). El bloc
/// ignora el pedido si ya esta cargando o si no quedan paginas.
///
/// Si la pagina anterior fallo, solo se vuelve a pedir con `reintento`: el
/// scroll no tiene que martillar al backend mientras siga caido.
class MisServiciosSiguientePaginaSolicitada extends ServicioEvent {
	final bool reintento;

	const MisServiciosSiguientePaginaSolicitada({this.reintento = false});

	@override
	List<Object?> get props => [reintento];
}

class ServicioDocumentoPdfVerSolicitado extends ServicioEvent {
	final Servicio servicio;

	const ServicioDocumentoPdfVerSolicitado({required this.servicio});

	@override
	List<Object?> get props => [servicio];
}

class ServicioDocumentoEnlacePdfCopiarSolicitado extends ServicioEvent {
	final Servicio servicio;

	const ServicioDocumentoEnlacePdfCopiarSolicitado({required this.servicio});

	@override
	List<Object?> get props => [servicio];
}
