import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:equatable/equatable.dart';

/// El indicador ya tiene una recepcion sin devolver (`RECEPCION_ABIERTA`).
class RecepcionAbiertaExistente extends Equatable {
	final String recepcionId;
	final int? numero;
	final String mensaje;

	const RecepcionAbiertaExistente({
		required this.recepcionId,
		this.numero,
		required this.mensaje,
	});

	@override
	List<Object?> get props => [recepcionId, numero, mensaje];
}

class NuevaRecepcionState extends Equatable {
	final List<Cliente> clientesEncontrados;
	final bool buscandoClientes;
	final Cliente? clienteSeleccionado;
	final String indicadorNroSerie;
	final String? indicadorProductoId;
	final String queLlego;
	final String sintomaReportado;
	final String observaciones;
	final bool guardando;
	final bool creandoCliente;

	/// Por que no se pudo dar de alta el cliente. Lo muestra el dialogo del
	/// alta, que queda abierto con lo cargado; se limpia al reintentar.
	final String? errorAltaCliente;

	/// Efectos de un solo uso: no se arrastran al siguiente emit.
	final String? errorMensaje;
	final Recepcion? recepcionCreada;
	final RecepcionAbiertaExistente? recepcionAbierta;

	/// El alta rapida termino bien (el cliente ya quedo seleccionado).
	final Cliente? clienteCreado;

	const NuevaRecepcionState({
		this.clientesEncontrados = const [],
		this.buscandoClientes = false,
		this.clienteSeleccionado,
		this.indicadorNroSerie = '',
		this.indicadorProductoId,
		this.queLlego = '',
		this.sintomaReportado = '',
		this.observaciones = '',
		this.guardando = false,
		this.creandoCliente = false,
		this.errorAltaCliente,
		this.errorMensaje,
		this.recepcionCreada,
		this.recepcionAbierta,
		this.clienteCreado,
	});

	/// Hay algo cargado que se perderia al salir sin registrar.
	bool get tieneDatosCargados =>
			clienteSeleccionado != null ||
			indicadorProductoId != null ||
			indicadorNroSerie.trim().isNotEmpty ||
			queLlego.trim().isNotEmpty ||
			sintomaReportado.trim().isNotEmpty ||
			observaciones.trim().isNotEmpty;

	/// Al salir con Atras se pide confirmacion si hay datos y no se esta
	/// guardando (mientras guarda no se sale).
	bool get pideConfirmarSalida => tieneDatosCargados && !guardando;

	NuevaRecepcionState copyWith({
		List<Cliente>? clientesEncontrados,
		bool? buscandoClientes,
		Cliente? clienteSeleccionado,
		String? indicadorNroSerie,
		String? indicadorProductoId,
		bool limpiarProducto = false,
		String? queLlego,
		String? sintomaReportado,
		String? observaciones,
		bool? guardando,
		bool? creandoCliente,
		String? errorAltaCliente,
		bool limpiarErrorAltaCliente = false,
		String? errorMensaje,
		Recepcion? recepcionCreada,
		RecepcionAbiertaExistente? recepcionAbierta,
		Cliente? clienteCreado,
	}) {
		return NuevaRecepcionState(
			clientesEncontrados: clientesEncontrados ?? this.clientesEncontrados,
			buscandoClientes: buscandoClientes ?? this.buscandoClientes,
			clienteSeleccionado: clienteSeleccionado ?? this.clienteSeleccionado,
			indicadorNroSerie: indicadorNroSerie ?? this.indicadorNroSerie,
			indicadorProductoId:
					limpiarProducto ? null : (indicadorProductoId ?? this.indicadorProductoId),
			queLlego: queLlego ?? this.queLlego,
			sintomaReportado: sintomaReportado ?? this.sintomaReportado,
			observaciones: observaciones ?? this.observaciones,
			guardando: guardando ?? this.guardando,
			creandoCliente: creandoCliente ?? this.creandoCliente,
			errorAltaCliente:
					limpiarErrorAltaCliente ? null : (errorAltaCliente ?? this.errorAltaCliente),
			errorMensaje: errorMensaje,
			recepcionCreada: recepcionCreada,
			recepcionAbierta: recepcionAbierta,
			clienteCreado: clienteCreado,
		);
	}

	@override
	List<Object?> get props => [
				clientesEncontrados,
				buscandoClientes,
				clienteSeleccionado,
				indicadorNroSerie,
				indicadorProductoId,
				queLlego,
				sintomaReportado,
				observaciones,
				guardando,
				creandoCliente,
				errorAltaCliente,
				errorMensaje,
				recepcionCreada,
				recepcionAbierta,
				clienteCreado,
			];
}
