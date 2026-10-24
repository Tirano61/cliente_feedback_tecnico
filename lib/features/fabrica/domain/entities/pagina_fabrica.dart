import 'package:equatable/equatable.dart';

/// Una pagina de un listado de fabrica (`{ data, meta }`).
class PaginaFabrica<T> extends Equatable {
	final List<T> items;
	final int pagina;
	final int limite;
	final int total;
	final int totalPaginas;

	const PaginaFabrica({
		required this.items,
		required this.pagina,
		required this.limite,
		required this.total,
		required this.totalPaginas,
	});

	@override
	List<Object?> get props => [items, pagina, limite, total, totalPaginas];
}
