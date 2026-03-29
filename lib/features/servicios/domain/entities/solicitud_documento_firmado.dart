import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

class SolicitudDocumentoFirmado extends Equatable {
	final String servicioId;
	final Canal canal;
	final Uint8List pdfBytes;
	final String nombreArchivoPdf;
	final String rutaPdfLocal;
	final String? firmaClienteNombre;
	final String? firmaClienteDocumento;
	final DateTime? firmaFechaHora;

	const SolicitudDocumentoFirmado({
		required this.servicioId,
		required this.canal,
		required this.pdfBytes,
		required this.nombreArchivoPdf,
		required this.rutaPdfLocal,
		this.firmaClienteNombre,
		this.firmaClienteDocumento,
		this.firmaFechaHora,
	});

	bool get tieneFirma {
		return (firmaClienteNombre ?? '').trim().isNotEmpty && firmaFechaHora != null;
	}

	@override
	List<Object?> get props => [
				servicioId,
				canal,
				pdfBytes,
				nombreArchivoPdf,
				rutaPdfLocal,
				firmaClienteNombre,
				firmaClienteDocumento,
				firmaFechaHora,
			];
}
