import 'package:equatable/equatable.dart';

class CatResolucion extends Equatable {
	final String id;
	final String nombre;
	final bool activo;

	const CatResolucion({
		required this.id,
		required this.nombre,
		required this.activo,
	});

	@override
	List<Object> get props => [id, nombre, activo];
}
