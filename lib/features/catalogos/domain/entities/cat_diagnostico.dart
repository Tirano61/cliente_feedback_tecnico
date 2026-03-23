import 'package:equatable/equatable.dart';

class CatDiagnostico extends Equatable {
	final String id;
	final String nombre;
	final bool activo;

	const CatDiagnostico({
		required this.id,
		required this.nombre,
		required this.activo,
	});

	@override
	List<Object> get props => [id, nombre, activo];
}
