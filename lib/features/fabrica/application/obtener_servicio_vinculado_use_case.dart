import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/servicio_vinculado.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerServicioVinculadoUseCase {
	final IFabricaRepository _repository;

	ObtenerServicioVinculadoUseCase(this._repository);

	Future<ServicioVinculado> ejecutar(String servicioId) {
		return _repository.obtenerServicioVinculado(servicioId);
	}
}
