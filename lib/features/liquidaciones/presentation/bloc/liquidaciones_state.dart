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
  /// Listas por estado y total, calculados por el BLoC sobre todas las paginas.
  final List<Liquidacion> pendientes;
  final List<Liquidacion> aprobadas;
  final List<Liquidacion> reabiertas;
  final double totalAprobadasUsd;
  final Map<String, List<ItemLiquidacion>> detallesItemsPorLiquidacion;
  final Set<String> detallesCargandoIds;
  final String? mensajeAviso;

  const LiquidacionesLoaded({
    required this.pendientes,
    required this.aprobadas,
    required this.reabiertas,
    required this.totalAprobadasUsd,
    this.detallesItemsPorLiquidacion = const {},
    this.detallesCargandoIds = const {},
    this.mensajeAviso,
  });

  LiquidacionesLoaded copyWith({
    Map<String, List<ItemLiquidacion>>? detallesItemsPorLiquidacion,
    Set<String>? detallesCargandoIds,
    String? mensajeAviso,
    bool limpiarMensajeAviso = false,
  }) {
    return LiquidacionesLoaded(
      pendientes: pendientes,
      aprobadas: aprobadas,
      reabiertas: reabiertas,
      totalAprobadasUsd: totalAprobadasUsd,
      detallesItemsPorLiquidacion:
          detallesItemsPorLiquidacion ?? this.detallesItemsPorLiquidacion,
      detallesCargandoIds: detallesCargandoIds ?? this.detallesCargandoIds,
      mensajeAviso: limpiarMensajeAviso ? null : mensajeAviso,
    );
  }

  @override
  List<Object?> get props => [
        pendientes,
        aprobadas,
        reabiertas,
        totalAprobadasUsd,
        detallesItemsPorLiquidacion,
        detallesCargandoIds,
        mensajeAviso,
      ];
}
