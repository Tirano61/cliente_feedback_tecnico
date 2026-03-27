import 'package:equatable/equatable.dart';

class ProductoFalla extends Equatable {
	final String parteFallo;
	final String productoFallaId;

	const ProductoFalla({
		required this.parteFallo,
		required this.productoFallaId,
	});

	@override
	List<Object> get props => [parteFallo, productoFallaId];
}
