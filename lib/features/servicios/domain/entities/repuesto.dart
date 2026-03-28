import 'package:equatable/equatable.dart';

class Repuesto extends Equatable {
	final String id;
	final String codigo;
	final String nombre;
	final double precioUsd;

	const Repuesto({
		required this.id,
		required this.codigo,
		required this.nombre,
		required this.precioUsd,
	});

	@override
	List<Object> get props => [id, codigo, nombre, precioUsd];
}
