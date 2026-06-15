import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/application/obtener_items_liquidacion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/application/obtener_mis_liquidaciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_event.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiquidacionesBloc extends Bloc<LiquidacionesEvent, LiquidacionesState> {
  final ObtenerMisLiquidacionesUseCase _obtenerMisLiquidacionesUseCase;
  final ObtenerItemsLiquidacionUseCase _obtenerItemsLiquidacionUseCase;

  LiquidacionesBloc(
    this._obtenerMisLiquidacionesUseCase,
    this._obtenerItemsLiquidacionUseCase,
  ) : super(const LiquidacionesInitial()) {
    on<LiquidacionesSolicitadas>(_onLiquidacionesSolicitadas);
    on<LiquidacionesRefrescadas>(_onLiquidacionesRefrescadas);
    on<LiquidacionDetalleSolicitado>(_onLiquidacionDetalleSolicitado);
  }

  Future<void> _onLiquidacionesSolicitadas(
    LiquidacionesSolicitadas event,
    Emitter<LiquidacionesState> emit,
  ) async {
    emit(const LiquidacionesLoading());
    await _cargarLiquidaciones(emit);
  }

  Future<void> _onLiquidacionesRefrescadas(
    LiquidacionesRefrescadas event,
    Emitter<LiquidacionesState> emit,
  ) async {
    await _cargarLiquidaciones(emit);
  }

  Future<void> _cargarLiquidaciones(Emitter<LiquidacionesState> emit) async {
    try {
      final respuesta = await _obtenerMisLiquidacionesUseCase.ejecutar();

      emit(
        LiquidacionesLoaded(
          liquidaciones: respuesta.liquidaciones,
          meta: respuesta.meta,
        ),
      );
    } on AuthException catch (error) {
      emit(LiquidacionesSesionExpirada(mensaje: error.mensaje));
    } on ServerException catch (error) {
      emit(LiquidacionesError(mensaje: error.mensaje));
    } catch (_) {
      emit(
        const LiquidacionesError(
          mensaje: 'No se pudieron cargar tus liquidaciones. Intenta nuevamente.',
        ),
      );
    }
  }

  Future<void> _onLiquidacionDetalleSolicitado(
    LiquidacionDetalleSolicitado event,
    Emitter<LiquidacionesState> emit,
  ) async {
    if (state is! LiquidacionesLoaded) {
      return;
    }

    final actual = state as LiquidacionesLoaded;
    if (actual.detallesCargandoIds.contains(event.liquidacionId)) {
      return;
    }

    emit(
      actual.copyWith(
        detallesCargandoIds: {...actual.detallesCargandoIds, event.liquidacionId},
        limpiarMensajeAviso: true,
      ),
    );

    try {
      final respuesta =
          await _obtenerItemsLiquidacionUseCase.ejecutar(event.liquidacionId);

      final detallesActualizados =
          Map<String, List<ItemLiquidacion>>.from(actual.detallesItemsPorLiquidacion)
            ..[event.liquidacionId] = respuesta.items;
      final idsCargando = Set<String>.from(actual.detallesCargandoIds)
        ..remove(event.liquidacionId);

      emit(
        actual.copyWith(
          detallesItemsPorLiquidacion: detallesActualizados,
          detallesCargandoIds: idsCargando,
        ),
      );
    } on AuthException catch (error) {
      emit(LiquidacionesSesionExpirada(mensaje: error.mensaje));
    } on ServerException catch (error) {
      final idsCargando = Set<String>.from(actual.detallesCargandoIds)
        ..remove(event.liquidacionId);
      emit(
        actual.copyWith(
          detallesCargandoIds: idsCargando,
          mensajeAviso: error.mensaje,
        ),
      );
    } catch (_) {
      final idsCargando = Set<String>.from(actual.detallesCargandoIds)
        ..remove(event.liquidacionId);
      emit(
        actual.copyWith(
          detallesCargandoIds: idsCargando,
          mensajeAviso: 'No se pudieron actualizar los items de la liquidacion.',
        ),
      );
    }
  }
}
