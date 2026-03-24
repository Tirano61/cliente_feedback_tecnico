import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/repositories/i_caso_repository.dart';
import 'package:cliente_feedback_tecnico/features/casos/infrastructure/dtos/caso_dto.dart';

class CasoRepositoryImpl implements ICasoRepository {
	final ApiClient apiClient;

	CasoRepositoryImpl(this.apiClient);

	@override
	Future<void> cargarCaso(Caso caso) async {
		final response = await apiClient.post(
			ApiConstants.casos,
			CasoDto.desdeEntidad(caso).toJson(),
		);

		if (response.statusCode != 200 && response.statusCode != 201) {
			throw ServerException(
				'No se pudo guardar la orden de servicio.',
				statusCode: response.statusCode,
			);
		}
	}

	@override
	Future<List<Caso>> obtenerMisCasos() async {
		final response = await apiClient.get(ApiConstants.casosMios);

		if (response.statusCode != 200) {
			throw ServerException(
				'No se pudieron obtener los servicios del tecnico.',
				statusCode: response.statusCode,
			);
		}

		final dynamic json = jsonDecode(response.body);
		final lista = _extraerLista(json);

		return lista
				.whereType<Map<String, dynamic>>()
				.map((item) => CasoDto.fromJson(item).aEntidad())
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
}
