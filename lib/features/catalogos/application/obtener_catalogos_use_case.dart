import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_diagnostico.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_resolucion.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/categoria_producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/zona.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/repositories/i_catalogo_repository.dart';

class CatalogosData {
	final List<CatDiagnostico> diagnosticos;
	final List<CatResolucion> resoluciones;
	final List<Zona> zonas;
	final List<CategoriaProducto> categorias;
	final List<Producto> productos;

	const CatalogosData({
		required this.diagnosticos,
		required this.resoluciones,
		required this.zonas,
		required this.categorias,
		required this.productos,
	});
}

class CatalogosBasicosData {
	final List<CatDiagnostico> diagnosticos;
	final List<CatResolucion> resoluciones;
	final List<Zona> zonas;
	final List<CategoriaProducto> categorias;

	const CatalogosBasicosData({
		required this.diagnosticos,
		required this.resoluciones,
		required this.zonas,
		required this.categorias,
	});
}

class ObtenerCatalogosUseCase {
	final ICatalogoRepository _repository;

	ObtenerCatalogosUseCase(this._repository);

	Future<CatalogosBasicosData> ejecutarBasicos() async {
		final resultados = await Future.wait<dynamic>([
			_repository.obtenerDiagnosticos(),
			_repository.obtenerResoluciones(),
			_repository.obtenerZonas(),
			_repository.obtenerCategorias(),
		]);

		return CatalogosBasicosData(
			diagnosticos: resultados[0] as List<CatDiagnostico>,
			resoluciones: resultados[1] as List<CatResolucion>,
			zonas: resultados[2] as List<Zona>,
			categorias: resultados[3] as List<CategoriaProducto>,
		);
	}

	Future<List<Producto>> ejecutarProductosPorCategorias(
		List<CategoriaProducto> categorias,
	) async {
		if (categorias.isEmpty) {
			return const [];
		}

		final productosPorCategoria = await Future.wait(
			categorias.map((categoria) {
				return _repository.obtenerProductosPorCategoria(categoria.id);
			}),
		);

		final mapaProductos = <String, Producto>{};
		for (final productosCategoria in productosPorCategoria) {
			for (final producto in productosCategoria) {
				mapaProductos[producto.id] = producto;
			}
		}

		return mapaProductos.values.toList();
	}

	Future<CatalogosData> ejecutar() async {
		final basicos = await ejecutarBasicos();
		final productos = await ejecutarProductosPorCategorias(basicos.categorias);

		return CatalogosData(
			diagnosticos: basicos.diagnosticos,
			resoluciones: basicos.resoluciones,
			zonas: basicos.zonas,
			categorias: basicos.categorias,
			productos: productos,
		);
	}
}
