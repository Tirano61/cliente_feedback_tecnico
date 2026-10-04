import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/repositories/i_liquidacion_repository.dart';

class ObtenerMisLiquidacionesUseCase {
  static const int limitePorPagina = 100;

  final ILiquidacionRepository _repository;

  ObtenerMisLiquidacionesUseCase(this._repository);

  /// Trae todas las paginas de GET /liquidaciones/mias. Son pocas por tecnico,
  /// y los contadores y el total a cobrar necesitan el conjunto completo.
  Future<List<Liquidacion>> ejecutar({
    EstadoLiquidacionFiltro estado = EstadoLiquidacionFiltro.todas,
  }) async {
    // El backend ordena solo por createdAt: si entra una liquidacion nueva
    // entre pagina y pagina, el offset se corre y una se repite. Se deduplica
    // por id para no sumarla dos veces.
    final porId = <String, Liquidacion>{};
    var page = 1;

    while (true) {
      final respuesta = await _repository.obtenerMisLiquidaciones(
        estado: estado,
        page: page,
        limit: limitePorPagina,
      );

      for (final liquidacion in respuesta.liquidaciones) {
        porId.putIfAbsent(liquidacion.id, () => liquidacion);
      }

      if (respuesta.liquidaciones.isEmpty || page >= respuesta.meta.totalPages) {
        break;
      }
      page++;
    }

    return porId.values.toList();
  }
}
