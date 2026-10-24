import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class BuscarUnidadesUseCase {
	static const int limitePorPagina = 20;

	final IFabricaRepository _repository;

	BuscarUnidadesUseCase(this._repository);

	/// Placas reacondicionadas disponibles para recambio:
	/// `tipo: TipoUnidad.placa, estado: EstadoUnidad.reacondicionadaDisponible`.
	Future<PaginaFabrica<Unidad>> ejecutar({
		required int pagina,
		TipoUnidad? tipo,
		EstadoUnidad? estado,
		String nroSerie = '',
		String busqueda = '',
	}) {
		return _repository.buscarUnidades(
			tipo: tipo,
			estado: estado,
			nroSerie: nroSerie,
			busqueda: busqueda,
			pagina: pagina,
			limite: limitePorPagina,
		);
	}
}
