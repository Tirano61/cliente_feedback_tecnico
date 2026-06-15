import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/repositories/i_liquidacion_repository.dart';

class ObtenerMisLiquidacionesUseCase {
  final ILiquidacionRepository _repository;

  ObtenerMisLiquidacionesUseCase(this._repository);

  Future<RespuestaLiquidaciones> ejecutar({
    EstadoLiquidacionFiltro estado = EstadoLiquidacionFiltro.todas,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.obtenerMisLiquidaciones(
      estado: estado,
      page: page,
      limit: limit,
    );
  }
}
