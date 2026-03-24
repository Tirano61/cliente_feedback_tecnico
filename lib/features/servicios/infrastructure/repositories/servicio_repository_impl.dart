import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/servicio_dto.dart';

class ServicioRepositoryImpl implements IServicioRepository {
	final ApiClient apiClient;

	ServicioRepositoryImpl(this.apiClient);

	@override
	Future<void> cargarServicio(Servicio servicio) async {
		final response = await apiClient.post(
			ApiConstants.servicios,
			ServicioDto.desdeEntidad(servicio).toJson(),
		);

		if (response.statusCode != 200 && response.statusCode != 201) {
			throw ServerException(
				'No se pudo guardar la orden de servicio.',
				statusCode: response.statusCode,
			);
		}
	}

	@override
	Future<List<Servicio>> obtenerMisServicios() async {
		final response = await apiClient.get(ApiConstants.serviciosMios);

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
				.map((item) => ServicioDto.fromJson(item).aEntidad())
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


