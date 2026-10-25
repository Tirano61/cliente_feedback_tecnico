import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:equatable/equatable.dart';

abstract class IngresoDetalleEvent extends Equatable {
	const IngresoDetalleEvent();

	@override
	List<Object?> get props => [];
}

/// Abre el detalle. Con `ingreso` (la respuesta del alta) se muestra sin
/// volver a pedirlo.
class IngresoDetalleAbierto extends IngresoDetalleEvent {
	final String ingresoId;
	final Ingreso? ingreso;

	const IngresoDetalleAbierto({required this.ingresoId, this.ingreso});

	@override
	List<Object?> get props => [ingresoId, ingreso];
}

class IngresoDetalleRefrescado extends IngresoDetalleEvent {
	const IngresoDetalleRefrescado();
}

/// "Derivar a desarrollo" (solo placas en servicio tecnico).
class IngresoDerivacionSolicitada extends IngresoDetalleEvent {
	final String observacion;

	const IngresoDerivacionSolicitada({this.observacion = ''});

	@override
	List<Object?> get props => [observacion];
}

/// "Recibir de desarrollo" (placas reparadas por desarrollo).
class IngresoVueltaDesarrolloSolicitada extends IngresoDetalleEvent {
	final String observacion;

	const IngresoVueltaDesarrolloSolicitada({this.observacion = ''});

	@override
	List<Object?> get props => [observacion];
}

/// Al abrir "Cargar falla": componentes del modelo de la pieza y causas.
class IngresoCatalogosFallaSolicitados extends IngresoDetalleEvent {
	const IngresoCatalogosFallaSolicitados();
}

/// Falla de una celda. Va `componenteId` (del catalogo del modelo) o, si no
/// esta en el catalogo, `componenteOtro` escrito por el tecnico.
class IngresoFallaSolicitada extends IngresoDetalleEvent {
	/// El tecnico marco "Otro": falta escribir el componente, no elegirlo.
	final bool usaOtro;
	final String? componenteId;
	final String componenteOtro;
	final String? causaId;
	final String detalle;

	const IngresoFallaSolicitada({
		this.usaOtro = false,
		this.componenteId,
		this.componenteOtro = '',
		this.causaId,
		this.detalle = '',
	});

	@override
	List<Object?> get props => [usaOtro, componenteId, componenteOtro, causaId, detalle];
}

/// Reparacion de una celda. `resultado` null: el tecnico todavia no eligio
/// (lo rechaza el BLoC).
class IngresoReparacionSolicitada extends IngresoDetalleEvent {
	final ResultadoReparacion? resultado;
	final String trabajoRealizado;
	final String componentesReemplazados;

	const IngresoReparacionSolicitada({
		required this.resultado,
		this.trabajoRealizado = '',
		this.componentesReemplazados = '',
	});

	@override
	List<Object?> get props => [resultado, trabajoRealizado, componentesReemplazados];
}

/// Al abrir el dialogo de una accion: el error de un intento anterior ya no
/// corresponde.
class IngresoErrorAccionDescartado extends IngresoDetalleEvent {
	const IngresoErrorAccionDescartado();
}
