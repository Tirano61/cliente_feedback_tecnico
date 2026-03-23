import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
	final String id;
	final String nombre;
	final String email;
	final String rol;

	const Usuario({
		required this.id,
		required this.nombre,
		required this.email,
		required this.rol,
	});

	@override
	List<Object> get props => [id, nombre, email, rol];
}
