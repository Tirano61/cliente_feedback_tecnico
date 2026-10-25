import 'package:equatable/equatable.dart';

abstract class PiezasEvent extends Equatable {
	const PiezasEvent();

	@override
	List<Object?> get props => [];
}

/// Entrar a la pestaña o "Reintentar": vuelve a consultar con la busqueda y
/// el atajo vigentes.
class PiezasSolicitadas extends PiezasEvent {
	const PiezasSolicitadas();
}

/// Volver del detalle o deslizar para actualizar: sin sacar el listado de
/// pantalla.
class PiezasRefrescadas extends PiezasEvent {
	const PiezasRefrescadas();
}

/// Busqueda por numero de serie.
class PiezasBusquedaCambiada extends PiezasEvent {
	final String texto;

	const PiezasBusquedaCambiada({required this.texto});

	@override
	List<Object?> get props => [texto];
}

/// Atajo "Placas reacondicionadas disponibles" (prendido o apagado).
class PiezasReacondicionadasAlternadas extends PiezasEvent {
	final bool activas;

	const PiezasReacondicionadasAlternadas({required this.activas});

	@override
	List<Object?> get props => [activas];
}

class PiezasSiguientePaginaSolicitada extends PiezasEvent {
	/// Despues de un error de paginacion solo se vuelve a pedir si el tecnico
	/// toca "Reintentar" (no por el scroll).
	final bool reintento;

	const PiezasSiguientePaginaSolicitada({this.reintento = false});

	@override
	List<Object?> get props => [reintento];
}
