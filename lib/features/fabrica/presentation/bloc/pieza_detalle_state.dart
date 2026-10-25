import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_unidad.dart';
import 'package:equatable/equatable.dart';

class PiezaDetalleState extends Equatable {
	final String? unidadId;
	final Unidad? unidad;

	/// Movimientos del mas viejo al mas nuevo, como los manda el backend.
	final List<Movimiento> movimientos;

	/// Ya llegaron la pieza y su historial (con la del listado solo hay datos).
	final bool completo;
	final bool cargando;

	/// No se pudo cargar y no hay nada que mostrar.
	final String? errorCarga;

	/// Mensaje de un solo uso para el snackbar.
	final String? errorMensaje;

	const PiezaDetalleState({
		this.unidadId,
		this.unidad,
		this.movimientos = const [],
		this.completo = false,
		this.cargando = false,
		this.errorCarga,
		this.errorMensaje,
	});

	bool get esIndicador => unidad?.tipo == TipoUnidad.indicador;

	/// Solo los indicadores tienen piezas instaladas.
	List<Unidad> get piezasInstaladas => esIndicador ? unidad!.piezasInstaladas : const [];

	/// El recorrido de la pieza con textos legibles, del mas viejo al mas nuevo.
	List<PasoHistorial> get pasos {
		final actual = unidad;
		return actual == null ? const [] : pasosHistorial(actual.tipo, movimientos);
	}

	/// `errorMensaje` no se arrastra: vale para un emit.
	PiezaDetalleState copyWith({
		Unidad? unidad,
		List<Movimiento>? movimientos,
		bool? completo,
		bool? cargando,
		String? errorCarga,
		bool limpiarErrorCarga = false,
		String? errorMensaje,
	}) {
		return PiezaDetalleState(
			unidadId: unidadId,
			unidad: unidad ?? this.unidad,
			movimientos: movimientos ?? this.movimientos,
			completo: completo ?? this.completo,
			cargando: cargando ?? this.cargando,
			errorCarga: limpiarErrorCarga ? null : (errorCarga ?? this.errorCarga),
			errorMensaje: errorMensaje,
		);
	}

	@override
	List<Object?> get props => [
				unidadId,
				unidad,
				movimientos,
				completo,
				cargando,
				errorCarga,
				errorMensaje,
			];
}
