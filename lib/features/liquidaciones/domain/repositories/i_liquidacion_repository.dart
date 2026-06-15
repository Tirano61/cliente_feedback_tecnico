import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';

abstract class ILiquidacionRepository {
  Future<RespuestaLiquidaciones> obtenerMisLiquidaciones({
    required EstadoLiquidacionFiltro estado,
    required int page,
    required int limit,
  });

  Future<RespuestaItemsLiquidacion> obtenerItemsLiquidacion(String liquidacionId);
}
