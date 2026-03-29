import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

abstract class ServicioState extends Equatable {
	const ServicioState();

	@override
	List<Object?> get props => [];
}

class ServicioInitial extends ServicioState {
	const ServicioInitial();
}

class ServicioFormularioState extends ServicioState {
	final String idempotencyKey;
	final DateTime? fechaHoraServicio;
	final String timezoneIana;
	final int? utcOffsetMinutos;
	final Canal? canal;
	final String clienteId;
	final String lugarProvinciaId;
	final String lugarDetalle;
	final String equipoNroSerie;
	final String equipoModelo;
	final String equipoUbicacion;
	final String equipoAnio;
	final String partesFallaronTexto;
	final String km;
	final String sintoma;
	final List<String> diagnosticoCatIdsSeleccionados;
	final String diagnosticoDetalle;
	final String resolucionId;
	final String observaciones;
	final List<ProductoFalla> productosFallaSeleccionados;
	final bool cargandoFacturacion;
	final bool buscandoRepuestos;
	final double cotizacionDolarSnapshot;
	final double valorKmUsdSnapshot;
	final String ivaPorcentaje;
	final String descuentoPorcentaje;
	final List<Repuesto> repuestosDisponibles;
	final List<RepuestoSeleccionado> repuestosSeleccionados;
	final double subtotalKmUsd;
	final double subtotalKmArs;
	final double subtotalRepuestosUsd;
	final double subtotalRepuestosArs;
	final double subtotalGeneralUsd;
	final double subtotalGeneralArs;
	final double totalConIvaArs;
	final double totalFinalArs;
	final bool guardando;
	final bool buscandoClientes;
	final bool creandoCliente;
	final List<Cliente> clientesEncontrados;
	final Cliente? clienteSeleccionado;
	final OrdenServicioRespuesta? ordenActual;
	final Uint8List? pdfOrdenBytes;
	final String? pdfOrdenNombre;
	final bool subiendoDocumento;
	final int documentosPendientes;
	final String? errorMensaje;
	final String? exitoMensaje;

	const ServicioFormularioState({
		this.idempotencyKey = '',
		this.fechaHoraServicio,
		this.timezoneIana = '',
		this.utcOffsetMinutos,
		this.canal,
		this.clienteId = '',
		this.lugarProvinciaId = '',
		this.lugarDetalle = '',
		this.equipoNroSerie = '',
		this.equipoModelo = '',
		this.equipoUbicacion = '',
		this.equipoAnio = '',
		this.partesFallaronTexto = '',
		this.km = '',
		this.sintoma = '',
		this.diagnosticoCatIdsSeleccionados = const [],
		this.diagnosticoDetalle = '',
		this.resolucionId = '',
		this.observaciones = '',
		this.productosFallaSeleccionados = const [],
		this.cargandoFacturacion = false,
		this.buscandoRepuestos = false,
		this.cotizacionDolarSnapshot = 0,
		this.valorKmUsdSnapshot = 0,
		this.ivaPorcentaje = '21',
		this.descuentoPorcentaje = '',
		this.repuestosDisponibles = const [],
		this.repuestosSeleccionados = const [],
		this.subtotalKmUsd = 0,
		this.subtotalKmArs = 0,
		this.subtotalRepuestosUsd = 0,
		this.subtotalRepuestosArs = 0,
		this.subtotalGeneralUsd = 0,
		this.subtotalGeneralArs = 0,
		this.totalConIvaArs = 0,
		this.totalFinalArs = 0,
		this.guardando = false,
		this.buscandoClientes = false,
		this.creandoCliente = false,
		this.clientesEncontrados = const [],
		this.clienteSeleccionado,
		this.ordenActual,
		this.pdfOrdenBytes,
		this.pdfOrdenNombre,
		this.subiendoDocumento = false,
		this.documentosPendientes = 0,
		this.errorMensaje,
		this.exitoMensaje,
	});

	ServicioFormularioState copyWith({
		String? idempotencyKey,
		DateTime? fechaHoraServicio,
		String? timezoneIana,
		int? utcOffsetMinutos,
		bool limpiarFechaHoraServicio = false,
		bool limpiarUtcOffsetMinutos = false,
		Canal? canal,
		String? clienteId,
		String? lugarProvinciaId,
		String? lugarDetalle,
		String? equipoNroSerie,
		String? equipoModelo,
		String? equipoUbicacion,
		String? equipoAnio,
		String? partesFallaronTexto,
		String? km,
		String? sintoma,
		List<String>? diagnosticoCatIdsSeleccionados,
		String? diagnosticoDetalle,
		String? resolucionId,
		String? observaciones,
		List<ProductoFalla>? productosFallaSeleccionados,
		bool? cargandoFacturacion,
		bool? buscandoRepuestos,
		double? cotizacionDolarSnapshot,
		double? valorKmUsdSnapshot,
		String? ivaPorcentaje,
		String? descuentoPorcentaje,
		List<Repuesto>? repuestosDisponibles,
		List<RepuestoSeleccionado>? repuestosSeleccionados,
		double? subtotalKmUsd,
		double? subtotalKmArs,
		double? subtotalRepuestosUsd,
		double? subtotalRepuestosArs,
		double? subtotalGeneralUsd,
		double? subtotalGeneralArs,
		double? totalConIvaArs,
		double? totalFinalArs,
		bool? guardando,
		bool? buscandoClientes,
		bool? creandoCliente,
		List<Cliente>? clientesEncontrados,
		Cliente? clienteSeleccionado,
		OrdenServicioRespuesta? ordenActual,
		bool limpiarOrdenActual = false,
		Uint8List? pdfOrdenBytes,
		String? pdfOrdenNombre,
		bool? subiendoDocumento,
		int? documentosPendientes,
		String? errorMensaje,
		String? exitoMensaje,
		bool limpiarMensajes = false,
		bool limpiarClienteSeleccionado = false,
		bool limpiarPdfOrden = false,
	}) {
		return ServicioFormularioState(
			idempotencyKey: idempotencyKey ?? this.idempotencyKey,
			fechaHoraServicio: limpiarFechaHoraServicio
					? null
					: (fechaHoraServicio ?? this.fechaHoraServicio),
			timezoneIana: timezoneIana ?? this.timezoneIana,
			utcOffsetMinutos: limpiarUtcOffsetMinutos
					? null
					: (utcOffsetMinutos ?? this.utcOffsetMinutos),
			canal: canal ?? this.canal,
			clienteId: clienteId ?? this.clienteId,
			lugarProvinciaId: lugarProvinciaId ?? this.lugarProvinciaId,
			lugarDetalle: lugarDetalle ?? this.lugarDetalle,
			equipoNroSerie: equipoNroSerie ?? this.equipoNroSerie,
			equipoModelo: equipoModelo ?? this.equipoModelo,
			equipoUbicacion: equipoUbicacion ?? this.equipoUbicacion,
			equipoAnio: equipoAnio ?? this.equipoAnio,
			partesFallaronTexto: partesFallaronTexto ?? this.partesFallaronTexto,
			km: km ?? this.km,
			sintoma: sintoma ?? this.sintoma,
			diagnosticoCatIdsSeleccionados:
					diagnosticoCatIdsSeleccionados ?? this.diagnosticoCatIdsSeleccionados,
			diagnosticoDetalle: diagnosticoDetalle ?? this.diagnosticoDetalle,
			resolucionId: resolucionId ?? this.resolucionId,
			observaciones: observaciones ?? this.observaciones,
			productosFallaSeleccionados:
					productosFallaSeleccionados ?? this.productosFallaSeleccionados,
			cargandoFacturacion: cargandoFacturacion ?? this.cargandoFacturacion,
			buscandoRepuestos: buscandoRepuestos ?? this.buscandoRepuestos,
			cotizacionDolarSnapshot:
					cotizacionDolarSnapshot ?? this.cotizacionDolarSnapshot,
			valorKmUsdSnapshot: valorKmUsdSnapshot ?? this.valorKmUsdSnapshot,
			ivaPorcentaje: ivaPorcentaje ?? this.ivaPorcentaje,
			descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
			repuestosDisponibles: repuestosDisponibles ?? this.repuestosDisponibles,
			repuestosSeleccionados:
					repuestosSeleccionados ?? this.repuestosSeleccionados,
			subtotalKmUsd: subtotalKmUsd ?? this.subtotalKmUsd,
			subtotalKmArs: subtotalKmArs ?? this.subtotalKmArs,
			subtotalRepuestosUsd:
					subtotalRepuestosUsd ?? this.subtotalRepuestosUsd,
			subtotalRepuestosArs:
					subtotalRepuestosArs ?? this.subtotalRepuestosArs,
			subtotalGeneralUsd: subtotalGeneralUsd ?? this.subtotalGeneralUsd,
			subtotalGeneralArs: subtotalGeneralArs ?? this.subtotalGeneralArs,
			totalConIvaArs: totalConIvaArs ?? this.totalConIvaArs,
			totalFinalArs: totalFinalArs ?? this.totalFinalArs,
			guardando: guardando ?? this.guardando,
			buscandoClientes: buscandoClientes ?? this.buscandoClientes,
			creandoCliente: creandoCliente ?? this.creandoCliente,
			clientesEncontrados: clientesEncontrados ?? this.clientesEncontrados,
			clienteSeleccionado: limpiarClienteSeleccionado
					? null
					: (clienteSeleccionado ?? this.clienteSeleccionado),
			ordenActual: limpiarOrdenActual ? null : (ordenActual ?? this.ordenActual),
			pdfOrdenBytes: limpiarPdfOrden ? null : (pdfOrdenBytes ?? this.pdfOrdenBytes),
			pdfOrdenNombre: limpiarPdfOrden ? null : (pdfOrdenNombre ?? this.pdfOrdenNombre),
			subiendoDocumento: subiendoDocumento ?? this.subiendoDocumento,
			documentosPendientes: documentosPendientes ?? this.documentosPendientes,
			errorMensaje: limpiarMensajes ? null : errorMensaje,
			exitoMensaje: limpiarMensajes ? null : exitoMensaje,
		);
	}

	@override
	List<Object?> get props => [
				idempotencyKey,
				fechaHoraServicio,
				timezoneIana,
				utcOffsetMinutos,
				canal,
				clienteId,
				lugarProvinciaId,
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
				productosFallaSeleccionados,
				cargandoFacturacion,
				buscandoRepuestos,
				cotizacionDolarSnapshot,
				valorKmUsdSnapshot,
				ivaPorcentaje,
				descuentoPorcentaje,
				repuestosDisponibles,
				repuestosSeleccionados,
				subtotalKmUsd,
				subtotalKmArs,
				subtotalRepuestosUsd,
				subtotalRepuestosArs,
				subtotalGeneralUsd,
				subtotalGeneralArs,
				totalConIvaArs,
				totalFinalArs,
				guardando,
				buscandoClientes,
				creandoCliente,
				clientesEncontrados,
				clienteSeleccionado,
				ordenActual,
				pdfOrdenBytes,
				pdfOrdenNombre,
				subiendoDocumento,
				documentosPendientes,
				errorMensaje,
				exitoMensaje,
			];
}

class ServicioGuardando extends ServicioState {
	const ServicioGuardando();
}

class ServicioGuardadoExito extends ServicioState {
	const ServicioGuardadoExito();
}

class ServicioError extends ServicioState {
	final String mensaje;

	const ServicioError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}

class MisServiciosLoading extends ServicioState {
	const MisServiciosLoading();
}

class MisServiciosLoaded extends ServicioState {
	static const Object _sinCambioMensajePendientes = Object();

	final List<Servicio> servicios;
	final int documentosPendientes;
	final bool reintentandoPendientes;
	final String? servicioIdSubiendoPdf;
	final String? mensajePendientes;

	const MisServiciosLoaded({
		required this.servicios,
		this.documentosPendientes = 0,
		this.reintentandoPendientes = false,
		this.servicioIdSubiendoPdf,
		this.mensajePendientes,
	});

	MisServiciosLoaded copyWith({
		List<Servicio>? servicios,
		int? documentosPendientes,
		bool? reintentandoPendientes,
		String? servicioIdSubiendoPdf,
		bool limpiarServicioIdSubiendoPdf = false,
		Object? mensajePendientes = _sinCambioMensajePendientes,
		bool limpiarMensajePendientes = false,
	}) {
		return MisServiciosLoaded(
			servicios: servicios ?? this.servicios,
			documentosPendientes: documentosPendientes ?? this.documentosPendientes,
			reintentandoPendientes:
					reintentandoPendientes ?? this.reintentandoPendientes,
			servicioIdSubiendoPdf: limpiarServicioIdSubiendoPdf
					? null
					: (servicioIdSubiendoPdf ?? this.servicioIdSubiendoPdf),
			mensajePendientes: limpiarMensajePendientes
					? null
					: (mensajePendientes == _sinCambioMensajePendientes
							? this.mensajePendientes
							: mensajePendientes as String?),
		);
	}

	@override
	List<Object?> get props => [
				servicios,
				documentosPendientes,
				reintentandoPendientes,
				servicioIdSubiendoPdf,
				mensajePendientes,
			];
}

class RepuestoSeleccionado extends Equatable {
	final Repuesto repuesto;
	final double cantidad;

	const RepuestoSeleccionado({
		required this.repuesto,
		required this.cantidad,
	});

	RepuestoSeleccionado copyWith({
		Repuesto? repuesto,
		double? cantidad,
	}) {
		return RepuestoSeleccionado(
			repuesto: repuesto ?? this.repuesto,
			cantidad: cantidad ?? this.cantidad,
		);
	}

	@override
	List<Object> get props => [repuesto, cantidad];
}


