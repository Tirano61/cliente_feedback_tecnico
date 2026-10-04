import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/filtro_estado_servicio.dart';
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
	final String precioServicioUsd;
	final String sintoma;
	final List<String> diagnosticoCatIdsSeleccionados;
	final String diagnosticoDetalle;
	final List<String> resolucionIdsSeleccionados;
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
	final double subtotalServicioUsd;
	final double subtotalServicioArs;
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
		this.precioServicioUsd = '',
		this.sintoma = '',
		this.diagnosticoCatIdsSeleccionados = const [],
		this.diagnosticoDetalle = '',
		this.resolucionIdsSeleccionados = const [],
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
		this.subtotalServicioUsd = 0,
		this.subtotalServicioArs = 0,
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

	/// Provincia, lugar de atencion y km solo aplican en `canal = campo`: en
	/// remoto y fabrica el backend completa el lugar y esos campos viajan null.
	bool get requiereDatosDeCampo => canal == Canal.campo;

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
		String? precioServicioUsd,
		String? sintoma,
		List<String>? diagnosticoCatIdsSeleccionados,
		String? diagnosticoDetalle,
		List<String>? resolucionIdsSeleccionados,
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
		double? subtotalServicioUsd,
		double? subtotalServicioArs,
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
			precioServicioUsd: precioServicioUsd ?? this.precioServicioUsd,
			sintoma: sintoma ?? this.sintoma,
			diagnosticoCatIdsSeleccionados:
					diagnosticoCatIdsSeleccionados ?? this.diagnosticoCatIdsSeleccionados,
			diagnosticoDetalle: diagnosticoDetalle ?? this.diagnosticoDetalle,
			resolucionIdsSeleccionados:
					resolucionIdsSeleccionados ?? this.resolucionIdsSeleccionados,
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
			subtotalServicioUsd: subtotalServicioUsd ?? this.subtotalServicioUsd,
			subtotalServicioArs: subtotalServicioArs ?? this.subtotalServicioArs,
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
				precioServicioUsd,
				sintoma,
				diagnosticoCatIdsSeleccionados,
				diagnosticoDetalle,
				resolucionIdsSeleccionados,
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
				subtotalServicioUsd,
				subtotalServicioArs,
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

	/// Paginas ya traidas, en el orden del backend (createdAt DESC). La
	/// busqueda y el filtro los aplica el backend: se renderiza tal cual.
	final List<Servicio> servicios;

	/// Ordenes que el backend confirmo que ya tienen PDF aunque el listado de
	/// GET /servicios/mios no lo traiga.
	final Set<String> serviciosConPdfConfirmado;
	final FiltroEstadoServicio filtroEstado;
	final String busqueda;

	/// `meta.total` del backend: cuenta lo que matchea la busqueda y el filtro.
	final int total;
	final int pagina;
	final int totalPaginas;

	/// Se esta trayendo de nuevo la primera pagina por un cambio de busqueda o
	/// filtro. El listado anterior sigue visible hasta que llegue la respuesta.
	final bool actualizando;
	final bool cargandoMas;

	/// Fallo la consulta de la primera pagina con la busqueda/filtro vigentes.
	final String? errorListado;

	/// Fallo la carga de la pagina siguiente; lo ya traido sigue valiendo.
	final String? errorPaginacion;
	final int documentosPendientes;
	final bool reintentandoPendientes;
	final String? servicioIdSubiendoPdf;
	final String? servicioIdDescargandoPdf;
	final String? servicioIdCopiandoEnlacePdf;

	/// Efecto puntual: la vista abre o guarda estos bytes con el visor del SO.
	final PdfOrdenParaAbrir? pdfParaAbrir;

	/// Efecto puntual: la vista copia este enlace al portapapeles.
	final EnlacePdfParaCopiar? enlacePdfParaCopiar;
	final String? mensajePendientes;

	const MisServiciosLoaded({
		required this.servicios,
		this.serviciosConPdfConfirmado = const <String>{},
		this.filtroEstado = FiltroEstadoServicio.todos,
		this.busqueda = '',
		this.total = 0,
		this.pagina = 0,
		this.totalPaginas = 0,
		this.actualizando = false,
		this.cargandoMas = false,
		this.errorListado,
		this.errorPaginacion,
		this.documentosPendientes = 0,
		this.reintentandoPendientes = false,
		this.servicioIdSubiendoPdf,
		this.servicioIdDescargandoPdf,
		this.servicioIdCopiandoEnlacePdf,
		this.pdfParaAbrir,
		this.enlacePdfParaCopiar,
		this.mensajePendientes,
	});

	bool get hayMasPaginas => pagina < totalPaginas;

	/// Distingue "el tecnico no tiene servicios" de "nada matchea el filtro".
	bool get hayFiltrosActivos =>
			busqueda.trim().isNotEmpty || filtroEstado != FiltroEstadoServicio.todos;

	/// La orden tiene PDF si el listado ya lo trae o si el backend lo confirmo.
	bool tienePdfDisponible(Servicio servicio) {
		return servicio.tieneDocumentoCargado ||
				serviciosConPdfConfirmado.contains(servicio.id.trim());
	}

	MisServiciosLoaded copyWith({
		List<Servicio>? servicios,
		Set<String>? serviciosConPdfConfirmado,
		FiltroEstadoServicio? filtroEstado,
		String? busqueda,
		int? total,
		int? pagina,
		int? totalPaginas,
		bool? actualizando,
		bool? cargandoMas,
		String? errorListado,
		bool limpiarErrorListado = false,
		String? errorPaginacion,
		bool limpiarErrorPaginacion = false,
		int? documentosPendientes,
		bool? reintentandoPendientes,
		String? servicioIdSubiendoPdf,
		bool limpiarServicioIdSubiendoPdf = false,
		String? servicioIdDescargandoPdf,
		bool limpiarServicioIdDescargandoPdf = false,
		String? servicioIdCopiandoEnlacePdf,
		bool limpiarServicioIdCopiandoEnlacePdf = false,
		PdfOrdenParaAbrir? pdfParaAbrir,
		bool limpiarPdfParaAbrir = false,
		EnlacePdfParaCopiar? enlacePdfParaCopiar,
		bool limpiarEnlacePdfParaCopiar = false,
		Object? mensajePendientes = _sinCambioMensajePendientes,
		bool limpiarMensajePendientes = false,
	}) {
		return MisServiciosLoaded(
			servicios: servicios ?? this.servicios,
			serviciosConPdfConfirmado:
					serviciosConPdfConfirmado ?? this.serviciosConPdfConfirmado,
			filtroEstado: filtroEstado ?? this.filtroEstado,
			busqueda: busqueda ?? this.busqueda,
			total: total ?? this.total,
			pagina: pagina ?? this.pagina,
			totalPaginas: totalPaginas ?? this.totalPaginas,
			actualizando: actualizando ?? this.actualizando,
			cargandoMas: cargandoMas ?? this.cargandoMas,
			errorListado:
					limpiarErrorListado ? null : (errorListado ?? this.errorListado),
			errorPaginacion: limpiarErrorPaginacion
					? null
					: (errorPaginacion ?? this.errorPaginacion),
			documentosPendientes: documentosPendientes ?? this.documentosPendientes,
			reintentandoPendientes:
					reintentandoPendientes ?? this.reintentandoPendientes,
			servicioIdSubiendoPdf: limpiarServicioIdSubiendoPdf
					? null
					: (servicioIdSubiendoPdf ?? this.servicioIdSubiendoPdf),
			servicioIdDescargandoPdf: limpiarServicioIdDescargandoPdf
					? null
					: (servicioIdDescargandoPdf ?? this.servicioIdDescargandoPdf),
			servicioIdCopiandoEnlacePdf: limpiarServicioIdCopiandoEnlacePdf
					? null
					: (servicioIdCopiandoEnlacePdf ?? this.servicioIdCopiandoEnlacePdf),
			pdfParaAbrir:
					limpiarPdfParaAbrir ? null : (pdfParaAbrir ?? this.pdfParaAbrir),
			enlacePdfParaCopiar: limpiarEnlacePdfParaCopiar
					? null
					: (enlacePdfParaCopiar ?? this.enlacePdfParaCopiar),
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
				serviciosConPdfConfirmado,
				filtroEstado,
				busqueda,
				total,
				pagina,
				totalPaginas,
				actualizando,
				cargandoMas,
				errorListado,
				errorPaginacion,
				documentosPendientes,
				reintentandoPendientes,
				servicioIdSubiendoPdf,
				servicioIdDescargandoPdf,
				servicioIdCopiandoEnlacePdf,
				pdfParaAbrir,
				enlacePdfParaCopiar,
				mensajePendientes,
			];
}

/// Pedido de apertura del PDF de una orden.
///
/// El `token` cambia en cada pedido para que el BlocListener de la vista sepa
/// distinguir un pedido nuevo de un estado que cambio por otro motivo.
class PdfOrdenParaAbrir extends Equatable {
	final int token;
	final String servicioId;
	final String nombreArchivo;
	final Uint8List bytes;

	const PdfOrdenParaAbrir({
		required this.token,
		required this.servicioId,
		required this.nombreArchivo,
		required this.bytes,
	});

	@override
	List<Object?> get props => [token, servicioId, nombreArchivo, bytes];
}

/// Pedido de copia al portapapeles del enlace del PDF de una orden.
class EnlacePdfParaCopiar extends Equatable {
	final int token;
	final String servicioId;
	final String enlace;

	const EnlacePdfParaCopiar({
		required this.token,
		required this.servicioId,
		required this.enlace,
	});

	@override
	List<Object?> get props => [token, servicioId, enlace];
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


