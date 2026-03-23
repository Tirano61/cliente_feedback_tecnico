import 'package:equatable/equatable.dart';

class Zona extends Equatable {
	final String id;
	final String nombre;
	final String provincia;
	final bool activo;

	const Zona({
		required this.id,
		required this.nombre,
		required this.provincia,
		required this.activo,
	});

	@override
	List<Object> get props => [id, nombre, provincia, activo];
}
