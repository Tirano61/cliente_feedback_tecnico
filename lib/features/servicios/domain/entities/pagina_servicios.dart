import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

/// Una pagina de GET /servicios/mios con su `meta`.
///
/// `total` y `totalPaginas` ya reflejan los filtros aplicados en el backend,
/// no el total historico del tecnico.
class PaginaServicios extends Equatable {
	final List<Servicio> servicios;
	final int pagina;
	final int limite;
	final int total;
	final int totalPaginas;

	const PaginaServicios({
		required this.servicios,
		required this.pagina,
		required this.limite,
		required this.total,
		required this.totalPaginas,
	});

	@override
	List<Object?> get props => [servicios, pagina, limite, total, totalPaginas];
}
