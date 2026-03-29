import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class SubirDocumentoFirmadoUseCase {
	final IServicioRepository _repository;

	SubirDocumentoFirmadoUseCase(this._repository);

	Future<OrdenServicioRespuesta> ejecutar(SolicitudDocumentoFirmado solicitud) {
		return _repository.subirDocumentoFirmado(solicitud);
	}
}
