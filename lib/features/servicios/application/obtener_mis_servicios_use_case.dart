import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_mis_servicios.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/pagina_servicios.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerMisServiciosUseCase {
	static const int limitePorPagina = 20;

	final IServicioRepository _repository;

	ObtenerMisServiciosUseCase(this._repository);

	/// Trae una sola pagina: la busqueda, el filtro y el orden los resuelve el
	/// backend. Por defecto ordena por fecha de realizacion: el tecnico piensa
	/// sus servicios por cuando los hizo, no por cuando los cargo.
	Future<PaginaServicios> ejecutar({
		required int pagina,
		String busqueda = '',
		bool? aprobado,
		OrdenMisServicios orden = OrdenMisServicios.fechaServicio,
	}) {
		return _repository.obtenerMisServicios(
			pagina: pagina,
			limite: limitePorPagina,
			busqueda: busqueda,
			aprobado: aprobado,
			orden: orden,
		);
	}
}
