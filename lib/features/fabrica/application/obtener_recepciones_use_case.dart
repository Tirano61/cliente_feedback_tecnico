import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerRecepcionesUseCase {
	static const int limitePorPagina = 20;

	final IFabricaRepository _repository;

	ObtenerRecepcionesUseCase(this._repository);

	/// Por defecto solo las abiertas (sin devolver); `abiertas: null` trae
	/// todas, incluidas las devueltas.
	Future<PaginaFabrica<Recepcion>> ejecutar({
		required int pagina,
		EstadoRecepcion? estado,
		bool? abiertas = true,
		String? clienteId,
		String busqueda = '',
	}) {
		return _repository.obtenerRecepciones(
			estado: estado,
			abiertas: abiertas,
			clienteId: clienteId,
			busqueda: busqueda,
			pagina: pagina,
			limite: limitePorPagina,
		);
	}
}
