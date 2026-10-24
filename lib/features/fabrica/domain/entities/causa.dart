import 'package:equatable/equatable.dart';

/// Causa de falla (catalogo de desarrollo).
class Causa extends Equatable {
	final String id;
	final String nombre;
	final bool activo;

	const Causa({
		required this.id,
		required this.nombre,
		this.activo = true,
	});

	@override
	List<Object?> get props => [id, nombre, activo];
}
