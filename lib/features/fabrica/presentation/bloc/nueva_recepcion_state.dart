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

	/// Efectos de un solo uso: no se arrastran al siguiente emit.
	final String? errorMensaje;
	final Recepcion? recepcionCreada;
	final RecepcionAbiertaExistente? recepcionAbierta;

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
		this.errorMensaje,
		this.recepcionCreada,
		this.recepcionAbierta,
	});

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
		String? errorMensaje,
		Recepcion? recepcionCreada,
		RecepcionAbiertaExistente? recepcionAbierta,
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
			errorMensaje: errorMensaje,
			recepcionCreada: recepcionCreada,
			recepcionAbierta: recepcionAbierta,
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
				errorMensaje,
				recepcionCreada,
				recepcionAbierta,
			];
}
