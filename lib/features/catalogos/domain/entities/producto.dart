import 'package:equatable/equatable.dart';

class Producto extends Equatable {
	final String id;
	final String nombre;
	final bool activo;
	final String categoriaId;

	const Producto({
		required this.id,
		required this.nombre,
		required this.activo,
		required this.categoriaId,
	});

	@override
	List<Object> get props => [id, nombre, activo, categoriaId];
}
