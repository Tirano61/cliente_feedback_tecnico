import 'package:cliente_feedback_tecnico/core/fecha/fecha_iso8601.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';

// Bodies de las escrituras de fabrica, con las claves de endpoints.md.
//
// En los POST/PATCH los opcionales en null se omiten. La falla es un PUT que
// reemplaza la anterior: manda todas las claves, en null si no aplican, para
// que al corregir no quede un `componenteId` viejo.

class NuevaRecepcionDto {
	final String clienteId;
	final String indicadorNroSerie;
	final String? indicadorProductoId;
	final String queLlego;
	final String sintomaReportado;
	final String? observaciones;

	const NuevaRecepcionDto({
		required this.clienteId,
		required this.indicadorNroSerie,
		this.indicadorProductoId,
		required this.queLlego,
		required this.sintomaReportado,
		this.observaciones,
	});

	factory NuevaRecepcionDto.desdeEntidad(NuevaRecepcion recepcion) {
		return NuevaRecepcionDto(
			clienteId: recepcion.clienteId,
			indicadorNroSerie: recepcion.indicadorNroSerie,
			indicadorProductoId: recepcion.indicadorProductoId,
			queLlego: recepcion.queLlego,
			sintomaReportado: recepcion.sintomaReportado,
			observaciones: recepcion.observaciones,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'clienteId': clienteId,
			'indicadorNroSerie': indicadorNroSerie,
			if (indicadorProductoId != null) 'indicadorProductoId': indicadorProductoId,
			'queLlego': queLlego,
			'sintomaReportado': sintomaReportado,
			if (observaciones != null) 'observaciones': observaciones,
		};
	}
}

/// Body de `PATCH /fabrica/recepciones/:id/estado`.
class CambioEstadoRecepcionBodyDto {
	final EstadoRecepcion estado;
	final String? observacion;

	const CambioEstadoRecepcionBodyDto({required this.estado, this.observacion});

	Map<String, dynamic> toJson() {
		return {
			'estado': CodigosFabrica.codigoEstadoRecepcion(estado),
			if (observacion != null) 'observacion': observacion,
		};
	}
}

class SolicitudDevolucionDto {
	final FormaDevolucion formaDevolucion;
	final DateTime? fechaDevolucion;
	final String? observacion;

	const SolicitudDevolucionDto({
		required this.formaDevolucion,
		this.fechaDevolucion,
		this.observacion,
	});

	factory SolicitudDevolucionDto.desdeEntidad(SolicitudDevolucion solicitud) {
		return SolicitudDevolucionDto(
			formaDevolucion: solicitud.formaDevolucion,
			fechaDevolucion: solicitud.fechaDevolucion,
			observacion: solicitud.observacion,
		);
	}

	Map<String, dynamic> toJson() {
		final fecha = fechaDevolucion;
		return {
			'formaDevolucion': CodigosFabrica.codigoFormaDevolucion(formaDevolucion),
			if (fecha != null) 'fechaDevolucion': fechaIso8601ConOffset(fecha),
			if (observacion != null) 'observacion': observacion,
		};
	}
}

class NuevoIngresoDto {
	final TipoUnidad tipo;
	final String nroSerie;
	final String? productoId;
	final String? recepcionId;
	final String? clienteOrigenId;
	final String? servicioId;
	final String? indicadorNroSerie;
	final String? observacionTecnico;

	const NuevoIngresoDto({
		required this.tipo,
		required this.nroSerie,
		this.productoId,
		this.recepcionId,
		this.clienteOrigenId,
		this.servicioId,
		this.indicadorNroSerie,
		this.observacionTecnico,
	});

	factory NuevoIngresoDto.desdeEntidad(NuevoIngreso ingreso) {
		return NuevoIngresoDto(
			tipo: ingreso.tipo,
			nroSerie: ingreso.nroSerie,
			productoId: ingreso.productoId,
			recepcionId: ingreso.recepcionId,
			clienteOrigenId: ingreso.clienteOrigenId,
			servicioId: ingreso.servicioId,
			indicadorNroSerie: ingreso.indicadorNroSerie,
			observacionTecnico: ingreso.observacionTecnico,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'tipo': CodigosFabrica.codigoTipoUnidad(tipo),
			'nroSerie': nroSerie,
			if (productoId != null) 'productoId': productoId,
			if (recepcionId != null) 'recepcionId': recepcionId,
			if (clienteOrigenId != null) 'clienteOrigenId': clienteOrigenId,
			if (servicioId != null) 'servicioId': servicioId,
			if (indicadorNroSerie != null) 'indicadorNroSerie': indicadorNroSerie,
			if (observacionTecnico != null) 'observacionTecnico': observacionTecnico,
		};
	}
}

class SolicitudAsignacionDto {
	final String indicadorNroSerie;
	final TipoUnidad tipo;
	final String nroSerie;
	final String? productoId;
	final String? indicadorProductoId;
	final String? retiradaNroSerie;
	final String? recepcionId;
	final String? servicioId;
	final String? observacion;

	const SolicitudAsignacionDto({
		required this.indicadorNroSerie,
		required this.tipo,
		required this.nroSerie,
		this.productoId,
		this.indicadorProductoId,
		this.retiradaNroSerie,
		this.recepcionId,
		this.servicioId,
		this.observacion,
	});

	factory SolicitudAsignacionDto.desdeEntidad(SolicitudAsignacion solicitud) {
		return SolicitudAsignacionDto(
			indicadorNroSerie: solicitud.indicadorNroSerie,
			tipo: solicitud.tipo,
			nroSerie: solicitud.nroSerie,
			productoId: solicitud.productoId,
			indicadorProductoId: solicitud.indicadorProductoId,
			retiradaNroSerie: solicitud.retiradaNroSerie,
			recepcionId: solicitud.recepcionId,
			servicioId: solicitud.servicioId,
			observacion: solicitud.observacion,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'indicadorNroSerie': indicadorNroSerie,
			'tipo': CodigosFabrica.codigoTipoUnidad(tipo),
			'nroSerie': nroSerie,
			if (productoId != null) 'productoId': productoId,
			if (indicadorProductoId != null) 'indicadorProductoId': indicadorProductoId,
			if (retiradaNroSerie != null) 'retiradaNroSerie': retiradaNroSerie,
			if (recepcionId != null) 'recepcionId': recepcionId,
			if (servicioId != null) 'servicioId': servicioId,
			if (observacion != null) 'observacion': observacion,
		};
	}
}

class SolicitudFallaDto {
	final String? componenteId;
	final String? componenteOtro;
	final String causaId;
	final String? detalle;

	const SolicitudFallaDto({
		this.componenteId,
		this.componenteOtro,
		required this.causaId,
		this.detalle,
	});

	factory SolicitudFallaDto.desdeEntidad(SolicitudFalla solicitud) {
		return SolicitudFallaDto(
			componenteId: solicitud.componenteId,
			componenteOtro: solicitud.componenteOtro,
			causaId: solicitud.causaId,
			detalle: solicitud.detalle,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'componenteId': componenteId,
			'componenteOtro': componenteOtro,
			'causaId': causaId,
			'detalle': detalle,
		};
	}
}

class SolicitudReparacionDto {
	final ResultadoReparacion resultado;
	final String? trabajoRealizado;
	final String? componentesReemplazados;

	const SolicitudReparacionDto({
		required this.resultado,
		this.trabajoRealizado,
		this.componentesReemplazados,
	});

	factory SolicitudReparacionDto.desdeEntidad(SolicitudReparacion solicitud) {
		return SolicitudReparacionDto(
			resultado: solicitud.resultado,
			trabajoRealizado: solicitud.trabajoRealizado,
			componentesReemplazados: solicitud.componentesReemplazados,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'resultado': CodigosFabrica.codigoResultadoReparacion(resultado),
			if (trabajoRealizado != null) 'trabajoRealizado': trabajoRealizado,
			if (componentesReemplazados != null) 'componentesReemplazados': componentesReemplazados,
		};
	}
}
