import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:equatable/equatable.dart';

abstract class LiquidacionesState extends Equatable {
  const LiquidacionesState();

  @override
  List<Object?> get props => [];
}

class LiquidacionesInitial extends LiquidacionesState {
  const LiquidacionesInitial();
}

class LiquidacionesLoading extends LiquidacionesState {
  const LiquidacionesLoading();
}

class LiquidacionesError extends LiquidacionesState {
  final String mensaje;

  const LiquidacionesError({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

class LiquidacionesSesionExpirada extends LiquidacionesState {
  final String mensaje;

  const LiquidacionesSesionExpirada({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

class LiquidacionesLoaded extends LiquidacionesState {
  final List<Liquidacion> liquidaciones;
  final MetaLiquidaciones meta;
  final Map<String, List<ItemLiquidacion>> detallesItemsPorLiquidacion;
  final Set<String> detallesCargandoIds;
  final String? mensajeAviso;

  const LiquidacionesLoaded({
    required this.liquidaciones,
    required this.meta,
    this.detallesItemsPorLiquidacion = const {},
    this.detallesCargandoIds = const {},
    this.mensajeAviso,
  });

  LiquidacionesLoaded copyWith({
    List<Liquidacion>? liquidaciones,
    MetaLiquidaciones? meta,
    Map<String, List<ItemLiquidacion>>? detallesItemsPorLiquidacion,
    Set<String>? detallesCargandoIds,
    String? mensajeAviso,
    bool limpiarMensajeAviso = false,
  }) {
    return LiquidacionesLoaded(
      liquidaciones: liquidaciones ?? this.liquidaciones,
      meta: meta ?? this.meta,
      detallesItemsPorLiquidacion:
          detallesItemsPorLiquidacion ?? this.detallesItemsPorLiquidacion,
      detallesCargandoIds: detallesCargandoIds ?? this.detallesCargandoIds,
      mensajeAviso: limpiarMensajeAviso ? null : mensajeAviso,
    );
  }

  @override
  List<Object?> get props => [
        liquidaciones,
        meta,
        detallesItemsPorLiquidacion,
        detallesCargandoIds,
        mensajeAviso,
      ];
}
