import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:equatable/equatable.dart';

abstract class NuevaRecepcionEvent extends Equatable {
	const NuevaRecepcionEvent();

	@override
	List<Object?> get props => [];
}

/// Al entrar al alta: formulario vacio.
class NuevaRecepcionIniciada extends NuevaRecepcionEvent {
	const NuevaRecepcionIniciada();
}

class NuevaRecepcionBuscarClienteSolicitado extends NuevaRecepcionEvent {
	final String query;

	const NuevaRecepcionBuscarClienteSolicitado({required this.query});

	@override
	List<Object?> get props => [query];
}

class NuevaRecepcionClienteSeleccionado extends NuevaRecepcionEvent {
	final Cliente cliente;

	const NuevaRecepcionClienteSeleccionado({required this.cliente});

	@override
	List<Object?> get props => [cliente];
}

/// Solo cambian los campos que vienen; `limpiarProducto` quita el modelo.
class NuevaRecepcionCambiada extends NuevaRecepcionEvent {
	final String? indicadorNroSerie;
	final String? indicadorProductoId;
	final bool limpiarProducto;
	final String? queLlego;
	final String? sintomaReportado;
	final String? observaciones;

	const NuevaRecepcionCambiada({
		this.indicadorNroSerie,
		this.indicadorProductoId,
		this.limpiarProducto = false,
		this.queLlego,
		this.sintomaReportado,
		this.observaciones,
	});

	@override
	List<Object?> get props => [
				indicadorNroSerie,
				indicadorProductoId,
				limpiarProducto,
				queLlego,
				sintomaReportado,
				observaciones,
			];
}

class NuevaRecepcionGuardada extends NuevaRecepcionEvent {
	const NuevaRecepcionGuardada();
}
