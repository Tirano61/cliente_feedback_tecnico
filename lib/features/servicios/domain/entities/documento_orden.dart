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

	@override
	List<Object?> get props => [
				pdfHashSha256,
				pdfUrl,
				firmaClienteNombre,
				firmaClienteDocumento,
				firmaFechaHora,
			];
}
