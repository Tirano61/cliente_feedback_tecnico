import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:equatable/equatable.dart';

// Datos que la app manda en las escrituras de fabrica. En los POST/PATCH los
// opcionales en null no se envian; la falla (PUT) manda todas las claves.

/// `POST /fabrica/recepciones`.
class NuevaRecepcion extends Equatable {
	final String clienteId;
	final String indicadorNroSerie;
	final String? indicadorProductoId;
	final String queLlego;
	final String sintomaReportado;
	final String? observaciones;

	const NuevaRecepcion({
		required this.clienteId,
		required this.indicadorNroSerie,
		this.indicadorProductoId,
		required this.queLlego,
		required this.sintomaReportado,
		this.observaciones,
	});

	@override
	List<Object?> get props => [
				clienteId,
				indicadorNroSerie,
				indicadorProductoId,
				queLlego,
				sintomaReportado,
				observaciones,
			];
}

/// `PATCH /fabrica/recepciones/:id/devolucion`. Sin `fechaDevolucion` el
/// backend usa la hora actual.
class SolicitudDevolucion extends Equatable {
	final FormaDevolucion formaDevolucion;
	final DateTime? fechaDevolucion;
	final String? observacion;

	const SolicitudDevolucion({
		required this.formaDevolucion,
		this.fechaDevolucion,
		this.observacion,
	});

	@override
	List<Object?> get props => [formaDevolucion, fechaDevolucion, observacion];
}

/// `POST /fabrica/ingresos`. Con `recepcionId` el cliente, el indicador y el
/// servicio salen de la recepcion; sin recepcion `clienteOrigenId` es
/// obligatorio (lo valida el backend con `CLIENTE_ORIGEN_REQUERIDO`).
class NuevoIngreso extends Equatable {
	final TipoUnidad tipo;
	final String nroSerie;
	final String? productoId;
	final String? recepcionId;
	final String? clienteOrigenId;
	final String? servicioId;
	final String? indicadorNroSerie;
	final String? observacionTecnico;

	const NuevoIngreso({
		required this.tipo,
		required this.nroSerie,
		this.productoId,
		this.recepcionId,
		this.clienteOrigenId,
		this.servicioId,
		this.indicadorNroSerie,
		this.observacionTecnico,
	});

	@override
	List<Object?> get props => [
				tipo,
				nroSerie,
				productoId,
				recepcionId,
				clienteOrigenId,
				servicioId,
				indicadorNroSerie,
				observacionTecnico,
			];
}

/// `POST /fabrica/unidades/asignaciones`: poner una placa o celda en un
/// indicador. En placas, sin `retiradaNroSerie` sale la que tenia el
/// indicador.
class SolicitudAsignacion extends Equatable {
	final String indicadorNroSerie;
	final TipoUnidad tipo;
	final String nroSerie;
	final String? productoId;
	final String? indicadorProductoId;
	final String? retiradaNroSerie;
	final String? recepcionId;
	final String? servicioId;
	final String? observacion;

	const SolicitudAsignacion({
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

	@override
	List<Object?> get props => [
				indicadorNroSerie,
				tipo,
				nroSerie,
				productoId,
				indicadorProductoId,
				retiradaNroSerie,
				recepcionId,
				servicioId,
				observacion,
			];
}

/// `PUT /fabrica/ingresos/:id/falla`. Va `componenteId` (del catalogo del
/// modelo) o `componenteOtro` si no esta en el catalogo.
class SolicitudFalla extends Equatable {
	final String? componenteId;
	final String? componenteOtro;
	final String causaId;
	final String? detalle;

	const SolicitudFalla({
		this.componenteId,
		this.componenteOtro,
		required this.causaId,
		this.detalle,
	});

	@override
	List<Object?> get props => [componenteId, componenteOtro, causaId, detalle];
}

/// `POST /fabrica/ingresos/:id/reparacion`.
class SolicitudReparacion extends Equatable {
	final ResultadoReparacion resultado;
	final String? trabajoRealizado;
	final String? componentesReemplazados;

	const SolicitudReparacion({
		required this.resultado,
		this.trabajoRealizado,
		this.componentesReemplazados,
	});

	@override
	List<Object?> get props => [resultado, trabajoRealizado, componentesReemplazados];
}
