import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerIngresosUseCase {
	static const int limitePorPagina = 20;

	final IFabricaRepository _repository;

	ObtenerIngresosUseCase(this._repository);

	Future<PaginaFabrica<Ingreso>> ejecutar({
		required int pagina,
		EstadoIngreso? estado,
		TipoUnidad? tipo,
		String busqueda = '',
	}) {
		return _repository.obtenerIngresos(
			estado: estado,
			tipo: tipo,
			busqueda: busqueda,
			pagina: pagina,
			limite: limitePorPagina,
		);
	}
}
