import 'package:equatable/equatable.dart';

/// Componente de un modelo de pieza (catalogo de desarrollo). Se elige al
/// cargar la falla de una celda.
class Componente extends Equatable {
	final String id;
	final String nombre;
	final String productoId;
	final bool activo;

	const Componente({
		required this.id,
		required this.nombre,
		required this.productoId,
		this.activo = true,
	});

	@override
	List<Object?> get props => [id, nombre, productoId, activo];
}
