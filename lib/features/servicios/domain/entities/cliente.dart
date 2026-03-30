import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
	final String id;
	final String nombre;
	final String? cuit;
	final String? contacto;
	final String? telefono;
	final String? localidad;

	const Cliente({
		required this.id,
		required this.nombre,
		this.cuit,
		this.contacto,
		this.telefono,
		this.localidad,
	});

	@override
	List<Object?> get props => [id, nombre, cuit, contacto, telefono, localidad];
}
