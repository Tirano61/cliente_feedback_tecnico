import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_historial_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PiezaDetalleBloc extends Bloc<PiezaDetalleEvent, PiezaDetalleState> {
	final ObtenerUnidadUseCase _obtenerUnidadUseCase;
	final ObtenerHistorialUnidadUseCase _obtenerHistorialUnidadUseCase;

	/// Cada apertura deja sin efecto las respuestas de la pieza anterior.
	int _secuencia = 0;

	PiezaDetalleBloc(
		this._obtenerUnidadUseCase,
		this._obtenerHistorialUnidadUseCase,
	) : super(const PiezaDetalleState()) {
		on<PiezaDetalleAbierta>(_onAbierta);
		on<PiezaDetalleRefrescada>(_onRefrescada);
	}

	Future<void> _onAbierta(
		PiezaDetalleAbierta event,
		Emitter<PiezaDetalleState> emit,
	) async {
		final consulta = ++_secuencia;
		emit(PiezaDetalleState(unidadId: event.unidadId, unidad: event.unidad, cargando: true));
		await _cargar(emit, consulta);
	}

	Future<void> _onRefrescada(
		PiezaDetalleRefrescada event,
		Emitter<PiezaDetalleState> emit,
	) async {
		if (state.unidadId == null || state.cargando) {
			return;
		}
		emit(state.copyWith(cargando: true, limpiarErrorCarga: true));
		await _cargar(emit, _secuencia);
	}

	/// La pieza (con sus piezas instaladas si es un indicador) y el historial
	/// se piden juntos.
	Future<void> _cargar(Emitter<PiezaDetalleState> emit, int consulta) async {
		final unidadId = state.unidadId;
		if (unidadId == null) {
			return;
		}

		String error;
		try {
			final respuestas = await Future.wait<Object>([
				_obtenerUnidadUseCase.ejecutar(unidadId),
				_obtenerHistorialUnidadUseCase.ejecutar(unidadId),
			]);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			emit(
				state.copyWith(
					unidad: respuestas[0] as Unidad,
					movimientos: (respuestas[1] as HistorialUnidad).movimientos,
					completo: true,
					cargando: false,
					limpiarErrorCarga: true,
				),
			);
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudo cargar la pieza.';
		}

		if (consulta != _secuencia || emit.isDone) {
			return;
		}
		// Con el historial a la vista, el error de un refresco va al snackbar.
		emit(
			state.completo
					? state.copyWith(cargando: false, errorMensaje: error)
					: state.copyWith(cargando: false, errorCarga: error),
		);
	}
}
