import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:equatable/equatable.dart';

abstract class RecepcionesEvent extends Equatable {
	const RecepcionesEvent();

	@override
	List<Object?> get props => [];
}

/// Entrar a la pestaña o "Reintentar": primera pagina con la busqueda y los
/// filtros vigentes, con la pantalla de carga.
class RecepcionesSolicitadas extends RecepcionesEvent {
	const RecepcionesSolicitadas();
}

/// Volver del detalle o deslizar para actualizar: sin sacar el listado de
/// pantalla.
class RecepcionesRefrescadas extends RecepcionesEvent {
	const RecepcionesRefrescadas();
}

class RecepcionesBusquedaCambiada extends RecepcionesEvent {
	final String texto;

	const RecepcionesBusquedaCambiada({required this.texto});

	@override
	List<Object?> get props => [texto];
}

/// `estado` null: todos los estados.
class RecepcionesFiltroEstadoCambiado extends RecepcionesEvent {
	final EstadoRecepcion? estado;

	const RecepcionesFiltroEstadoCambiado({required this.estado});

	@override
	List<Object?> get props => [estado];
}

class RecepcionesVerDevueltasCambiado extends RecepcionesEvent {
	final bool verDevueltas;

	const RecepcionesVerDevueltasCambiado({required this.verDevueltas});

	@override
	List<Object?> get props => [verDevueltas];
}

class RecepcionesSiguientePaginaSolicitada extends RecepcionesEvent {
	/// Despues de un error de paginacion solo se vuelve a pedir si el tecnico
	/// toca "Reintentar" (no por el scroll).
	final bool reintento;

	const RecepcionesSiguientePaginaSolicitada({this.reintento = false});

	@override
	List<Object?> get props => [reintento];
}
