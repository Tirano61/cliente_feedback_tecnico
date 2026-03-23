import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_diagnostico.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_resolucion.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/categoria_producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/zona.dart';
import 'package:equatable/equatable.dart';

abstract class CatalogoState extends Equatable {
	const CatalogoState();

	@override
	List<Object?> get props => [];
}

class CatalogoInitial extends CatalogoState {
	const CatalogoInitial();
}

class CatalogoLoading extends CatalogoState {
	const CatalogoLoading();
}

class CatalogoLoaded extends CatalogoState {
	final List<CatDiagnostico> diagnosticos;
	final List<CatResolucion> resoluciones;
	final List<Zona> zonas;
	final List<CategoriaProducto> categorias;
	final List<Producto> productos;

	const CatalogoLoaded({
		required this.diagnosticos,
		required this.resoluciones,
		required this.zonas,
		required this.categorias,
		required this.productos,
	});

	@override
	List<Object> get props => [diagnosticos, resoluciones, zonas, categorias, productos];
}

class CatalogoError extends CatalogoState {
	final String mensaje;

	const CatalogoError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}
