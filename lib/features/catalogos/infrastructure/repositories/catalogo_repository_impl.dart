import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_diagnostico.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/cat_resolucion.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/categoria_producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/zona.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/repositories/i_catalogo_repository.dart';

class CatalogoRepositoryImpl implements ICatalogoRepository {
	final ApiClient apiClient;

	CatalogoRepositoryImpl(this.apiClient);

	@override
	Future<List<CatDiagnostico>> obtenerDiagnosticos() async {
		return const [];
	}

	@override
	Future<List<CatResolucion>> obtenerResoluciones() async {
		return const [];
	}

	@override
	Future<List<Zona>> obtenerZonas() async {
		return const [];
	}

	@override
	Future<List<CategoriaProducto>> obtenerCategorias() async {
		return const [];
	}

	@override
	Future<List<Producto>> obtenerProductos() async {
		return const [];
	}
}
