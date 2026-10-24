import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:equatable/equatable.dart';

/// Un paso del recorrido de una pieza.
class Movimiento extends Equatable {
	final TipoMovimiento tipo;
	final DateTime? fecha;
	final UsuarioFabrica? usuario;
	final IndicadorFabrica? indicador;
	final String? servicioId;
	final String? recepcionId;
	final String? ingresoId;
	final String? observacion;

	const Movimiento({
		required this.tipo,
		this.fecha,
		this.usuario,
		this.indicador,
		this.servicioId,
		this.recepcionId,
		this.ingresoId,
		this.observacion,
	});

	@override
	List<Object?> get props => [
				tipo,
				fecha,
				usuario,
				indicador,
				servicioId,
				recepcionId,
				ingresoId,
				observacion,
			];
}

/// `GET /fabrica/unidades/:id/historial`: movimientos del mas viejo al mas
/// nuevo, en el orden en que los manda el backend.
class HistorialUnidad extends Equatable {
	final Unidad unidad;
	final List<Movimiento> movimientos;

	const HistorialUnidad({
		required this.unidad,
		required this.movimientos,
	});

	@override
	List<Object?> get props => [unidad, movimientos];
}
