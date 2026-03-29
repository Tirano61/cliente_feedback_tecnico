import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class EncolarDocumentoPendienteUseCase {
	final IServicioRepository _repository;

	EncolarDocumentoPendienteUseCase(this._repository);

	Future<void> ejecutar(SolicitudDocumentoFirmado solicitud) {
		return _repository.encolarDocumentoPendiente(solicitud);
	}
}
