import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/vinculacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerVinculacionesPendientesUseCase {
	final IFabricaRepository _repository;

	ObtenerVinculacionesPendientesUseCase(this._repository);

	Future<List<VinculacionPendiente>> ejecutar() {
		return _repository.obtenerVinculacionesPendientes();
	}
}
