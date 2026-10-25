import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_state.dart';
import 'package:equatable/equatable.dart';

abstract class AsignacionUnidadEvent extends Equatable {
	const AsignacionUnidadEvent();

	@override
	List<Object?> get props => [];
}

/// Al entrar a "Poner placa/celda" desde la recepcion: formulario vacio con
/// el indicador y la recepcion precargados.
class AsignacionIniciada extends AsignacionUnidadEvent {
	final PrecargaAsignacionRecepcion precarga;

	const AsignacionIniciada({required this.precarga});

	@override
	List<Object?> get props => [precarga];
}

/// Solo cambian los campos que vienen; `limpiarProducto` quita el modelo.
/// Cambiar el tipo trae las reacondicionadas de ese tipo.
class AsignacionCambiada extends AsignacionUnidadEvent {
	final TipoUnidad? tipo;
	final String? nroSerie;
	final String? productoId;
	final bool limpiarProducto;
	final String? retiradaNroSerie;
	final String? observacion;

	const AsignacionCambiada({
		this.tipo,
		this.nroSerie,
		this.productoId,
		this.limpiarProducto = false,
		this.retiradaNroSerie,
		this.observacion,
	});

	@override
	List<Object?> get props => [
				tipo,
				nroSerie,
				productoId,
				limpiarProducto,
				retiradaNroSerie,
				observacion,
			];
}

/// Eligio una reacondicionada disponible: completa numero de serie y modelo.
class AsignacionReacondicionadaElegida extends AsignacionUnidadEvent {
	final Unidad unidad;

	const AsignacionReacondicionadaElegida({required this.unidad});

	@override
	List<Object?> get props => [unidad];
}

/// Eligio la pieza que sale de las instaladas (o la vuelve a tocar para no
/// elegir ninguna).
class AsignacionRetiradaElegida extends AsignacionUnidadEvent {
	final Unidad pieza;

	const AsignacionRetiradaElegida({required this.pieza});

	@override
	List<Object?> get props => [pieza];
}

/// "Reintentar" la lista de reacondicionadas.
class AsignacionReacondicionadasSolicitadas extends AsignacionUnidadEvent {
	const AsignacionReacondicionadasSolicitadas();
}

class AsignacionGuardada extends AsignacionUnidadEvent {
	const AsignacionGuardada();
}
