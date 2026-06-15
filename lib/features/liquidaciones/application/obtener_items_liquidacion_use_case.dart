import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/repositories/i_liquidacion_repository.dart';

class ObtenerItemsLiquidacionUseCase {
  final ILiquidacionRepository _repository;

  ObtenerItemsLiquidacionUseCase(this._repository);

  Future<RespuestaItemsLiquidacion> ejecutar(String liquidacionId) {
    return _repository.obtenerItemsLiquidacion(liquidacionId);
  }
}
