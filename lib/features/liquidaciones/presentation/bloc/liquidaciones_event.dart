import 'package:equatable/equatable.dart';

abstract class LiquidacionesEvent extends Equatable {
  const LiquidacionesEvent();

  @override
  List<Object?> get props => [];
}

class LiquidacionesSolicitadas extends LiquidacionesEvent {
  const LiquidacionesSolicitadas();
}

class LiquidacionesRefrescadas extends LiquidacionesEvent {
  const LiquidacionesRefrescadas();
}

class LiquidacionDetalleSolicitado extends LiquidacionesEvent {
  final String liquidacionId;

  const LiquidacionDetalleSolicitado({required this.liquidacionId});

  @override
  List<Object?> get props => [liquidacionId];
}
