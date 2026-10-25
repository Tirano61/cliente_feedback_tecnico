import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:equatable/equatable.dart';

abstract class PiezaDetalleEvent extends Equatable {
	const PiezaDetalleEvent();

	@override
	List<Object?> get props => [];
}

/// Abre el detalle de una pieza: la pieza (`GET /fabrica/unidades/:id`) y su
/// historial. Con `unidad` (la del listado) se muestran sus datos mientras
/// llega el resto.
class PiezaDetalleAbierta extends PiezaDetalleEvent {
	final String unidadId;
	final Unidad? unidad;

	const PiezaDetalleAbierta({required this.unidadId, this.unidad});

	@override
	List<Object?> get props => [unidadId, unidad];
}

class PiezaDetalleRefrescada extends PiezaDetalleEvent {
	const PiezaDetalleRefrescada();
}
