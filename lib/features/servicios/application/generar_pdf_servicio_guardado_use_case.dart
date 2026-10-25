import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';

/// PDF de una orden ya guardada (por ejemplo el servicio de fabrica de una
/// recepcion): se trae la orden con `GET /servicios/:id` y se genera con el
/// mismo PDF que al crearla.
class GenerarPdfServicioGuardadoUseCase {
	final IServicioRepository _repository;
	final GenerarPdfOrdenServicioUseCase _generarPdfOrdenServicioUseCase;

	GenerarPdfServicioGuardadoUseCase(this._repository, this._generarPdfOrdenServicioUseCase);

	Future<Uint8List> ejecutar(String servicioId) async {
		final servicio = await _repository.obtenerServicio(servicioId);
		return _generarPdfOrdenServicioUseCase.ejecutar(
			OrdenServicioRespuesta.desdeServicio(servicio),
		);
	}
}
