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
	final bool cargandoBasicos;
	final bool cargandoProductos;

	const CatalogoLoaded({
		required this.diagnosticos,
		required this.resoluciones,
		required this.zonas,
		required this.categorias,
		required this.productos,
		this.cargandoBasicos = false,
		this.cargandoProductos = false,
	});

	const CatalogoLoaded.vacio()
			: diagnosticos = const [],
				resoluciones = const [],
				zonas = const [],
				categorias = const [],
				productos = const [],
				cargandoBasicos = false,
				cargandoProductos = false;

	CatalogoLoaded copyWith({
		List<CatDiagnostico>? diagnosticos,
		List<CatResolucion>? resoluciones,
		List<Zona>? zonas,
		List<CategoriaProducto>? categorias,
		List<Producto>? productos,
		bool? cargandoBasicos,
		bool? cargandoProductos,
	}) {
		return CatalogoLoaded(
			diagnosticos: diagnosticos ?? this.diagnosticos,
			resoluciones: resoluciones ?? this.resoluciones,
			zonas: zonas ?? this.zonas,
			categorias: categorias ?? this.categorias,
			productos: productos ?? this.productos,
			cargandoBasicos: cargandoBasicos ?? this.cargandoBasicos,
			cargandoProductos: cargandoProductos ?? this.cargandoProductos,
		);
	}

	bool get tieneBasicos =>
			diagnosticos.isNotEmpty || resoluciones.isNotEmpty || zonas.isNotEmpty || categorias.isNotEmpty;

	@override
	List<Object> get props => [
		diagnosticos,
		resoluciones,
		zonas,
		categorias,
		productos,
		cargandoBasicos,
		cargandoProductos,
	];
}

class CatalogoError extends CatalogoState {
	final String mensaje;

	const CatalogoError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}
