import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

class DescargarPdfDocumentoUseCase {
	final IServicioRepository _repository;

	DescargarPdfDocumentoUseCase(this._repository);

	Future<Uint8List?> ejecutar(String servicioId) {
		return _repository.descargarPdfDocumento(servicioId);
	}
}
