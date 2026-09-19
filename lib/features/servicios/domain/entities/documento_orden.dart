import 'package:equatable/equatable.dart';

class DocumentoOrden extends Equatable {
	final String? pdfHashSha256;
	final String? pdfUrl;
	final String? firmaClienteNombre;
	final String? firmaClienteDocumento;
	final DateTime? firmaFechaHora;

	const DocumentoOrden({
		this.pdfHashSha256,
		this.pdfUrl,
		this.firmaClienteNombre,
		this.firmaClienteDocumento,
		this.firmaFechaHora,
	});

	/// El backend puede devolver el documento con la url, con el hash o solo con
	/// los datos de firma: cualquiera de los tres alcanza para saber que la
	/// orden ya tiene el PDF cargado y no hace falta volver a preguntarselo.
	bool get tieneContenidoCargado {
		if ((pdfUrl ?? '').trim().isNotEmpty) {
			return true;
		}

		if ((pdfHashSha256 ?? '').trim().isNotEmpty) {
			return true;
		}

		return (firmaClienteNombre ?? '').trim().isNotEmpty ||
				(firmaClienteDocumento ?? '').trim().isNotEmpty ||
				firmaFechaHora != null;
	}

	@override
	List<Object?> get props => [
				pdfHashSha256,
				pdfUrl,
				firmaClienteNombre,
				firmaClienteDocumento,
				firmaFechaHora,
			];
}
