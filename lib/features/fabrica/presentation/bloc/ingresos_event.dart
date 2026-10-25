import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:equatable/equatable.dart';

abstract class IngresosEvent extends Equatable {
	const IngresosEvent();

	@override
	List<Object?> get props => [];
}

/// Entrar a la pestaña o "Reintentar": primera pagina con la busqueda y los
/// filtros vigentes, con la pantalla de carga.
class IngresosSolicitados extends IngresosEvent {
	const IngresosSolicitados();
}

/// Volver del detalle o deslizar para actualizar: sin sacar el listado de
/// pantalla.
class IngresosRefrescados extends IngresosEvent {
	const IngresosRefrescados();
}

class IngresosBusquedaCambiada extends IngresosEvent {
	final String texto;

	const IngresosBusquedaCambiada({required this.texto});

	@override
	List<Object?> get props => [texto];
}

/// `tipo` null: placas y celdas.
class IngresosFiltroTipoCambiado extends IngresosEvent {
	final TipoUnidad? tipo;

	const IngresosFiltroTipoCambiado({required this.tipo});

	@override
	List<Object?> get props => [tipo];
}

/// `estado` null: todos los estados.
class IngresosFiltroEstadoCambiado extends IngresosEvent {
	final EstadoIngreso? estado;

	const IngresosFiltroEstadoCambiado({required this.estado});

	@override
	List<Object?> get props => [estado];
}

class IngresosSiguientePaginaSolicitada extends IngresosEvent {
	/// Despues de un error de paginacion solo se vuelve a pedir si el tecnico
	/// toca "Reintentar" (no por el scroll).
	final bool reintento;

	const IngresosSiguientePaginaSolicitada({this.reintento = false});

	@override
	List<Object?> get props => [reintento];
}
