import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_diagnostico.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_resolucion.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/categoria_producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/zona.dart';

abstract class ICatalogoRepository {
	Future<List<CatDiagnostico>> obtenerDiagnosticos();

	Future<List<CatResolucion>> obtenerResoluciones();

	Future<List<Zona>> obtenerZonas();

	Future<List<CategoriaProducto>> obtenerCategorias();

	Future<List<Producto>> obtenerProductos();
}
