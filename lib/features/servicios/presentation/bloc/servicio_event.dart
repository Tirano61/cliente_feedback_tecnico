import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
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
	final String? equipoUbicacion;
	final String? equipoAnio;
	final String? partesFallaronTexto;
	final String? km;
	final String? sintoma;
	final List<String>? diagnosticoCatIdsSeleccionados;
	final String? diagnosticoDetalle;
	final String? resolucionId;
	final String? observaciones;

	const ServicioFormularioCambiado({
		this.canal,
		this.zonaId,
		this.productosFallaSeleccionados,
		this.clienteId,
		this.lugarDetalle,
		this.equipoNroSerie,
		this.equipoModelo,
		this.equipoUbicacion,
		this.equipoAnio,
		this.partesFallaronTexto,
		this.km,
		this.sintoma,
		this.diagnosticoCatIdsSeleccionados,
		this.diagnosticoDetalle,
		this.resolucionId,
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
				equipoUbicacion,
				equipoAnio,
				partesFallaronTexto,
				km,
				sintoma,
				diagnosticoCatIdsSeleccionados,
				diagnosticoDetalle,
				resolucionId,
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

class ServicioGuardarPressed extends ServicioEvent {
	const ServicioGuardarPressed();
}

class MisServiciosSolicitados extends ServicioEvent {
	const MisServiciosSolicitados();
}

class ServicioFormularioReiniciado extends ServicioEvent {
	const ServicioFormularioReiniciado();
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


