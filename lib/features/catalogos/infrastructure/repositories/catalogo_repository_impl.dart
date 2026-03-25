import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
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
		final response = await apiClient.get(ApiConstants.diagnosticos);
		if (response.statusCode != 200) {
			throw ServerException(
				'No se pudo cargar el catalogo de diagnosticos.',
				statusCode: response.statusCode,
			);
		}

		return _extraerLista(jsonDecode(response.body))
				.whereType<Map<String, dynamic>>()
				.map(
					(item) => CatDiagnostico(
						id: item['id']?.toString() ?? '',
						nombre: item['nombre']?.toString() ?? '',
						activo: _boolDesdeDynamic(item['activo']),
					),
				)
				.toList();
	}

	@override
	Future<List<CatResolucion>> obtenerResoluciones() async {
		final response = await apiClient.get(ApiConstants.resoluciones);
		if (response.statusCode != 200) {
			throw ServerException(
				'No se pudo cargar el catalogo de resoluciones.',
				statusCode: response.statusCode,
			);
		}

		return _extraerLista(jsonDecode(response.body))
				.whereType<Map<String, dynamic>>()
				.map(
					(item) => CatResolucion(
						id: item['id']?.toString() ?? '',
						nombre: item['nombre']?.toString() ?? '',
						activo: _boolDesdeDynamic(item['activo']),
					),
				)
				.toList();
	}

	@override
	Future<List<Zona>> obtenerZonas() async {
		final response = await apiClient.get(ApiConstants.zonas);
		if (response.statusCode != 200) {
			throw ServerException(
				'No se pudo cargar el catalogo de zonas.',
				statusCode: response.statusCode,
			);
		}

		return _extraerLista(jsonDecode(response.body))
				.whereType<Map<String, dynamic>>()
				.map(
					(item) => Zona(
						id: item['id']?.toString() ?? '',
						nombre: item['nombre']?.toString() ?? '',
						provincia: item['provincia']?.toString() ?? '',
						activo: _boolDesdeDynamic(item['activo']),
					),
				)
				.toList();
	}

	@override
	Future<List<CategoriaProducto>> obtenerCategorias() async {
		final response = await apiClient.get(ApiConstants.categoriasProducto);
		if (response.statusCode != 200) {
			throw ServerException(
				'No se pudo cargar el catalogo de categorias.',
				statusCode: response.statusCode,
			);
		}

		return _extraerLista(jsonDecode(response.body))
				.whereType<Map<String, dynamic>>()
				.map(
					(item) => CategoriaProducto(
						id: item['id']?.toString() ?? '',
						nombre: item['nombre']?.toString() ?? '',
						activo: _boolDesdeDynamic(item['activo']),
					),
				)
				.toList();
	}

	@override
	Future<List<Producto>> obtenerProductosPorCategoria(String categoriaId) async {
		final response = await apiClient.get(
			'${ApiConstants.productos}?categoriaId=$categoriaId',
		);
		if (response.statusCode != 200) {
			throw ServerException(
				'No se pudo cargar el catalogo de productos.',
				statusCode: response.statusCode,
			);
		}

		return _extraerLista(jsonDecode(response.body))
				.whereType<Map<String, dynamic>>()
				.map(
					(item) => Producto(
						id: item['id']?.toString() ?? '',
						nombre: item['nombre']?.toString() ?? '',
						activo: _boolDesdeDynamic(item['activo']),
						categoriaId:
								item['categoriaId']?.toString() ??
								item['categoria_id']?.toString() ??
								categoriaId,
					),
				)
				.toList();
	}

	List<dynamic> _extraerLista(dynamic json) {
		if (json is List<dynamic>) {
			return json;
		}
		if (json is Map<String, dynamic>) {
			if (json['data'] is List<dynamic>) {
				return json['data'] as List<dynamic>;
			}
			if (json['items'] is List<dynamic>) {
				return json['items'] as List<dynamic>;
			}
		}
		return const [];
	}

	bool _boolDesdeDynamic(dynamic valor) {
		if (valor is bool) {
			return valor;
		}
		if (valor is num) {
			return valor == 1;
		}
		if (valor is String) {
			final normalizado = valor.toLowerCase().trim();
			return normalizado == 'true' || normalizado == '1' || normalizado == 'si';
		}
		return true;
	}
}
