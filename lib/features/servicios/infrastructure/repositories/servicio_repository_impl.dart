import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/cliente_dto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/servicio_dto.dart';

class ServicioRepositoryImpl implements IServicioRepository {
	final ApiClient apiClient;

	ServicioRepositoryImpl(this.apiClient);

	@override
	Future<void> cargarServicio(Servicio servicio) async {
		final body = ServicioDto.desdeEntidad(servicio).toJson();
		final response = await apiClient.post(
			ApiConstants.servicios,
			body,
		);

		if (response.statusCode != 200 && response.statusCode != 201) {
			final mensajeBackend = _extraerMensajeError(response.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudo guardar la orden de servicio.',
				statusCode: response.statusCode,
			);
		}
	}

	@override
	Future<List<Servicio>> obtenerMisServicios() async {
		final response = await apiClient.get(ApiConstants.serviciosMios);

		if (response.statusCode != 200) {
			final mensajeBackend = _extraerMensajeError(response.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudieron obtener los servicios del tecnico.',
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

	@override
	Future<List<Cliente>> buscarClientes(String query) async {
		final termino = Uri.encodeQueryComponent(query);
		final response = await apiClient.get('${ApiConstants.clientesBuscar}?q=$termino');

		if (response.statusCode != 200) {
			final mensajeBackend = _extraerMensajeError(response.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudieron buscar clientes.',
				statusCode: response.statusCode,
			);
		}

		final dynamic json = jsonDecode(response.body);
		final lista = _extraerLista(json);

		return lista
				.whereType<Map<String, dynamic>>()
				.map((item) => ClienteDto.fromJson(item))
				.toList();
	}

	@override
	Future<Cliente> crearClienteRapido(Map<String, dynamic> payloadCliente) async {
		final response = await apiClient.post(ApiConstants.clientes, payloadCliente);

		if (response.statusCode != 200 && response.statusCode != 201) {
			final mensajeBackend = _extraerMensajeError(response.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudo crear el cliente.',
				statusCode: response.statusCode,
			);
		}

		final dynamic json = jsonDecode(response.body);
		if (json is Map<String, dynamic>) {
			if (json['data'] is Map<String, dynamic>) {
				return ClienteDto.fromJson(json['data'] as Map<String, dynamic>);
			}
			if (json['cliente'] is Map<String, dynamic>) {
				return ClienteDto.fromJson(json['cliente'] as Map<String, dynamic>);
			}
			return ClienteDto.fromJson(json);
		}

		throw const ServerException('Respuesta invalida al crear cliente.');
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

	String? _extraerMensajeError(String body) {
		try {
			final dynamic json = jsonDecode(body);
			if (json is Map<String, dynamic>) {
				final message = json['message'];
				if (message is String && message.trim().isNotEmpty) {
					return message;
				}
				if (message is List && message.isNotEmpty) {
					return message.first.toString();
				}
			}
		} catch (_) {
			return null;
		}
		return null;
	}
}


