import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerEnlacePdfDocumentoUseCase {
	final IServicioRepository _repository;

	ObtenerEnlacePdfDocumentoUseCase(this._repository);

	Future<String?> ejecutar(String servicioId) {
		return _repository.obtenerEnlacePdfDocumento(servicioId);
	}
}
