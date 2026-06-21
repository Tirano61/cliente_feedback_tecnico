import 'package:equatable/equatable.dart';

abstract class CatalogoEvent extends Equatable {
	const CatalogoEvent();

	@override
	List<Object?> get props => [];
}

class CargarCatalogos extends CatalogoEvent {
	const CargarCatalogos();
}

class CargarCatalogosBasicos extends CatalogoEvent {
	final bool forzar;

	const CargarCatalogosBasicos({this.forzar = false});

	@override
	List<Object?> get props => [forzar];
}

class CargarCatalogosProductos extends CatalogoEvent {
	final bool forzar;

	const CargarCatalogosProductos({this.forzar = false});

	@override
	List<Object?> get props => [forzar];
}
