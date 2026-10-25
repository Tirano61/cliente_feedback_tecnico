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

	/// Modelos de indicador activos: productos de una categoria "indicador" o
	/// con "indicador" en el nombre.
	List<Producto> get indicadoresActivos {
		final categoriasIndicadorIds = categorias
				.where(
					(categoria) =>
							categoria.activo && categoria.nombre.toLowerCase().contains('indicador'),
				)
				.map((categoria) => categoria.id)
				.toSet();

		return productos
				.where(
					(producto) =>
							producto.activo &&
							(categoriasIndicadorIds.contains(producto.categoriaId) ||
									producto.nombre.toLowerCase().contains('indicador')),
				)
				.toList();
	}

	/// Modelos activos de una pieza (`palabra`: "placa", "celda"): productos de
	/// una categoria con esa palabra o con la palabra en el nombre. Si ninguno
	/// coincide, todos los activos, para que igual se pueda elegir el modelo.
	List<Producto> modelosActivosDe(String palabra) {
		final buscada = palabra.toLowerCase();
		final categoriasIds = categorias
				.where((categoria) => categoria.activo && categoria.nombre.toLowerCase().contains(buscada))
				.map((categoria) => categoria.id)
				.toSet();

		final activos = productos.where((producto) => producto.activo).toList();
		final coinciden = activos
				.where(
					(producto) =>
							categoriasIds.contains(producto.categoriaId) ||
							producto.nombre.toLowerCase().contains(buscada),
				)
				.toList();
		return coinciden.isEmpty ? activos : coinciden;
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
