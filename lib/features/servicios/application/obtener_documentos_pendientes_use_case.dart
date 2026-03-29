import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class ObtenerDocumentosPendientesUseCase {
	final IServicioRepository _repository;

	ObtenerDocumentosPendientesUseCase(this._repository);

	Future<List<SolicitudDocumentoFirmado>> ejecutar() {
		return _repository.obtenerDocumentosPendientes();
	}
}
