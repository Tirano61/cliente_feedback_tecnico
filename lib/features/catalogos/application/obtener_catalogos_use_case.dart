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

class ObtenerCatalogosUseCase {
	final ICatalogoRepository _repository;

	ObtenerCatalogosUseCase(this._repository);

	Future<CatalogosData> ejecutar() async {
		final diagnosticos = await _repository.obtenerDiagnosticos();
		final resoluciones = await _repository.obtenerResoluciones();
		final zonas = await _repository.obtenerZonas();
		final categorias = await _repository.obtenerCategorias();
		final productos = await _repository.obtenerProductos();

		return CatalogosData(
			diagnosticos: diagnosticos,
			resoluciones: resoluciones,
			zonas: zonas,
			categorias: categorias,
			productos: productos,
		);
	}
}
