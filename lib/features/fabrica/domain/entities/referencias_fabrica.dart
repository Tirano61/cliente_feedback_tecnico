import 'package:equatable/equatable.dart';

// Datos resumidos de otras entidades que vienen embebidos en las respuestas
// de fabrica (no son el recurso completo).

class ProductoFabrica extends Equatable {
	final String id;
	final String nombre;
	final String? version;

	const ProductoFabrica({
		required this.id,
		required this.nombre,
		this.version,
	});

	@override
	List<Object?> get props => [id, nombre, version];
}

/// Cliente de una recepcion o de origen de un ingreso. Las sucursales tambien
/// son clientes.
class ClienteFabrica extends Equatable {
	final String id;
	final String nombre;
	final String? cuit;

	const ClienteFabrica({
		required this.id,
		required this.nombre,
		this.cuit,
	});

	@override
	List<Object?> get props => [id, nombre, cuit];
}

/// En el historial de una pieza el usuario llega solo con `fullName`.
class UsuarioFabrica extends Equatable {
	final String? id;
	final String fullName;

	const UsuarioFabrica({
		this.id,
		required this.fullName,
	});

	@override
	List<Object?> get props => [id, fullName];
}

/// En el historial el indicador llega solo con `nroSerie`.
class IndicadorFabrica extends Equatable {
	final String? id;
	final String nroSerie;

	const IndicadorFabrica({
		this.id,
		required this.nroSerie,
	});

	@override
	List<Object?> get props => [id, nroSerie];
}
