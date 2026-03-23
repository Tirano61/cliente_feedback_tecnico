import 'package:equatable/equatable.dart';

abstract class CatalogoEvent extends Equatable {
	const CatalogoEvent();

	@override
	List<Object?> get props => [];
}

class CargarCatalogos extends CatalogoEvent {
	const CargarCatalogos();
}
