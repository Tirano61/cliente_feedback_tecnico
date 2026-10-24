import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerComponentesUseCase {
	final IFabricaRepository _repository;

	ObtenerComponentesUseCase(this._repository);

	/// Componentes del modelo de la pieza (`productoId` de su producto).
	Future<List<Componente>> ejecutar({
		required String productoId,
	}) {
		return _repository.obtenerComponentes(
			productoId: productoId,
		);
	}
}
