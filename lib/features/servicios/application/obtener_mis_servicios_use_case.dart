import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/pagina_servicios.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerMisServiciosUseCase {
	static const int limitePorPagina = 20;

	final IServicioRepository _repository;

	ObtenerMisServiciosUseCase(this._repository);

	/// Trae una sola pagina: la busqueda y el filtro los resuelve el backend.
	Future<PaginaServicios> ejecutar({
		required int pagina,
		String busqueda = '',
		bool? aprobado,
	}) {
		return _repository.obtenerMisServicios(
			pagina: pagina,
			limite: limitePorPagina,
			busqueda: busqueda,
			aprobado: aprobado,
		);
	}
}
