import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cotizacion_actual.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/politica_firma_canal.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/cliente_dto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/cotizacion_actual_dto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/orden_servicio_respuesta_dto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/repuesto_dto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/servicio_dto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ServicioRepositoryImpl implements IServicioRepository {
	final ApiClient apiClient;
	final SecureStorage secureStorage;
	static const String _colaDocumentosPendientesStorageKey =
			'servicios_documentos_pendientes_v1';

	ServicioRepositoryImpl(this.apiClient, this.secureStorage);

	@override
	Future<OrdenServicioRespuesta> cargarServicio(Servicio servicio) async {
		final body = ServicioDto.desdeEntidad(servicio).toJson();
		_logPayloadAltaServicio(body);
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

		final payload = _extraerMapa(_decodeJsonSeguro(response.body));
		if (payload == null) {
			throw const ServerException('Respuesta invalida al guardar la orden de servicio.');
		}

		return OrdenServicioRespuestaDto.fromJson(payload).aEntidad();
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
	Future<CotizacionActual> obtenerCotizacionActual() async {
		final responseCotizacion = await apiClient.get(ApiConstants.cotizacion);
		final responseTarifaKm = await apiClient.get(ApiConstants.tarifaKm);

		if (responseCotizacion.statusCode != 200) {
			final mensajeBackend = _extraerMensajeError(responseCotizacion.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudo obtener la cotizacion actual.',
				statusCode: responseCotizacion.statusCode,
			);
		}

		if (responseTarifaKm.statusCode != 200) {
			final mensajeBackend = _extraerMensajeError(responseTarifaKm.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudo obtener la tarifa de km actual.',
				statusCode: responseTarifaKm.statusCode,
			);
		}

		final payloadCotizacion = _extraerMapaFlexible(_decodeJsonSeguro(responseCotizacion.body));
		if (payloadCotizacion == null) {
			throw const ServerException('Respuesta invalida de cotizacion.');
		}

		final payloadTarifaKm = _extraerMapaFlexible(_decodeJsonSeguro(responseTarifaKm.body));
		if (payloadTarifaKm == null) {
			throw const ServerException('Respuesta invalida de tarifa km.');
		}

		final cotizacionDolar = _extraerCotizacionDolar(payloadCotizacion) ??
				CotizacionActualDto.fromJson(payloadCotizacion).cotizacionDolar;
		final valorKmUsd = _extraerValorKmUsd(payloadTarifaKm) ??
				CotizacionActualDto.fromJson(payloadTarifaKm).valorKmUsd;

		_logFacturacionInicializada(
			cotizacionDolar: cotizacionDolar,
			valorKmUsd: valorKmUsd,
		);

		return CotizacionActual(
			cotizacionDolar: cotizacionDolar,
			valorKmUsd: valorKmUsd,
		);
	}

	@override
	Future<List<Repuesto>> buscarRepuestos(String query) async {
		final termino = Uri.encodeQueryComponent(query);
		final response = await apiClient.get('${ApiConstants.repuestos}?q=$termino');

		if (response.statusCode != 200) {
			final mensajeBackend = _extraerMensajeError(response.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudieron obtener repuestos.',
				statusCode: response.statusCode,
			);
		}

		final dynamic json = _decodeJsonSeguro(response.body);
		final lista = _extraerLista(json);

		return lista
				.whereType<Map<String, dynamic>>()
				.map((item) => RepuestoDto.fromJson(item).aEntidad())
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

	@override
	Future<OrdenServicioRespuesta> subirDocumentoFirmado(
		SolicitudDocumentoFirmado solicitud,
	) async {
		final path = ApiConstants.servicioDocumentoFirmado(solicitud.servicioId);
		final puedeEnviarFirma = PoliticaFirmaCanal.puedeEnviarFirma(
			canal: solicitud.canal,
			firmaClienteNombre: solicitud.firmaClienteNombre,
			firmaFechaHora: solicitud.firmaFechaHora,
		);

		final campos = <String, String>{};
		if (puedeEnviarFirma) {
			campos['firmaClienteNombre'] = solicitud.firmaClienteNombre!.trim();
			if ((solicitud.firmaClienteDocumento ?? '').trim().isNotEmpty) {
				campos['firmaClienteDocumento'] = solicitud.firmaClienteDocumento!.trim();
			}
			campos['firmaFechaHora'] = solicitud.firmaFechaHora!.toIso8601String();
		}

		final archivoPdf = http.MultipartFile.fromBytes(
			'file',
			solicitud.pdfBytes,
			filename: _normalizarNombrePdf(
				solicitud.nombreArchivoPdf,
				solicitud.servicioId,
			),
			contentType: MediaType('application', 'pdf'),
		);

		final response = await apiClient.postMultipart(
			path: path,
			archivos: [archivoPdf],
			campos: campos,
		);

		if (response.statusCode != 200 && response.statusCode != 201) {
			final mensajeBackend = _extraerMensajeError(response.body);
			throw ServerException(
				mensajeBackend ?? 'No se pudo subir el documento firmado.',
				statusCode: response.statusCode,
			);
		}

		final payload = _extraerMapa(_decodeJsonSeguro(response.body));
		if (payload == null) {
			throw const ServerException('Respuesta invalida al subir documento firmado.');
		}

		return OrdenServicioRespuestaDto.fromJson(payload).aEntidad();
	}

	@override
	Future<void> encolarDocumentoPendiente(SolicitudDocumentoFirmado solicitud) async {
		final pendientes = await obtenerDocumentosPendientes();
		final actualizados = pendientes
				.where((item) => item.servicioId != solicitud.servicioId)
				.toList()
			..add(solicitud);

		await _guardarColaPendientes(actualizados);
	}

	@override
	Future<List<SolicitudDocumentoFirmado>> obtenerDocumentosPendientes() async {
		final jsonCrudo = await secureStorage.obtenerValor(
			_colaDocumentosPendientesStorageKey,
		);
		if (jsonCrudo == null || jsonCrudo.trim().isEmpty) {
			return const [];
		}

		try {
			final dynamic payload = jsonDecode(jsonCrudo);
			if (payload is! List) {
				return const [];
			}

			return payload
					.whereType<Map<String, dynamic>>()
					.map(_solicitudDesdeJson)
					.whereType<SolicitudDocumentoFirmado>()
					.toList();
		} catch (_) {
			return const [];
		}
	}

	@override
	Future<void> quitarDocumentoPendiente(String servicioId) async {
		final pendientes = await obtenerDocumentosPendientes();
		final actualizados = pendientes
				.where((item) => item.servicioId != servicioId)
				.toList();
		await _guardarColaPendientes(actualizados);
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

	void _logPayloadAltaServicio(Map<String, dynamic> body) {
		if (const bool.fromEnvironment('dart.vm.product')) {
			return;
		}

		final payloadPretty = const JsonEncoder.withIndent('  ').convert(body);
		developer.log('[POST /servicios] body final:\n$payloadPretty');
	}

	dynamic _decodeJsonSeguro(String body) {
		try {
			return jsonDecode(body);
		} catch (_) {
			return null;
		}
	}

	Map<String, dynamic>? _extraerMapa(dynamic json) {
		if (json is Map<String, dynamic>) {
			if (json['data'] is Map<String, dynamic>) {
				return json['data'] as Map<String, dynamic>;
			}
			return json;
		}
		return null;
	}

	Map<String, dynamic>? _extraerMapaFlexible(dynamic json) {
		if (json is Map<String, dynamic>) {
			final data = json['data'];
			if (data is Map<String, dynamic>) {
				return data;
			}
			if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
				return data.first as Map<String, dynamic>;
			}

			final items = json['items'];
			if (items is Map<String, dynamic>) {
				return items;
			}
			if (items is List && items.isNotEmpty && items.first is Map<String, dynamic>) {
				return items.first as Map<String, dynamic>;
			}

			return json;
		}

		if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
			return json.first as Map<String, dynamic>;
		}

		return null;
	}

	double? _extraerCotizacionDolar(Map<String, dynamic> payload) {
		final valor = _buscarValorPorClaves(payload, const [
			'cotizacionDolar',
			'cotizacion_dolar',
			'valorDolar',
			'dolar',
			'valor',
		]);
		return _doubleDesdeDynamic(valor);
	}

	double? _extraerValorKmUsd(Map<String, dynamic> payload) {
		final valor = _buscarValorPorClaves(payload, const [
			'valorKmUsd',
			'valor_km_usd',
			'precioKmUsd',
			'precio_km_usd',
			'valorKm',
			'tarifa',
			'valor',
		]);

		return _doubleDesdeDynamic(valor);
	}

	dynamic _buscarValorPorClaves(dynamic origen, List<String> claves) {
		if (origen is Map<String, dynamic>) {
			for (final clave in claves) {
				if (origen.containsKey(clave) && origen[clave] != null) {
					return origen[clave];
				}
			}
			for (final valor in origen.values) {
				final encontrado = _buscarValorPorClaves(valor, claves);
				if (encontrado != null) {
					return encontrado;
				}
			}
		}

		if (origen is List) {
			for (final item in origen) {
				final encontrado = _buscarValorPorClaves(item, claves);
				if (encontrado != null) {
					return encontrado;
				}
			}
		}

		return null;
	}

	double? _doubleDesdeDynamic(dynamic valor) {

		if (valor is num) {
			return valor.toDouble();
		}
		if (valor is String) {
			return double.tryParse(valor.replaceAll(',', '.'));
		}
		return null;
	}

	void _logFacturacionInicializada({
		required double cotizacionDolar,
		required double valorKmUsd,
	}) {
		if (const bool.fromEnvironment('dart.vm.product')) {
			return;
		}

		developer.log(
			'[FACTURACION] cotizacionDolar=$cotizacionDolar, valorKmUsd=$valorKmUsd',
		);
	}

	Future<void> _guardarColaPendientes(
		List<SolicitudDocumentoFirmado> pendientes,
	) async {
		final serializado = pendientes.map(_solicitudAJson).toList();
		await secureStorage.guardarValor(
			key: _colaDocumentosPendientesStorageKey,
			value: jsonEncode(serializado),
		);
	}

	Map<String, dynamic> _solicitudAJson(SolicitudDocumentoFirmado solicitud) {
		return {
			'servicioId': solicitud.servicioId,
			'canal': solicitud.canal.name,
			'pdfBytesBase64': base64Encode(solicitud.pdfBytes),
			'nombreArchivoPdf': solicitud.nombreArchivoPdf,
			'rutaPdfLocal': solicitud.rutaPdfLocal,
			'firmaClienteNombre': solicitud.firmaClienteNombre,
			'firmaClienteDocumento': solicitud.firmaClienteDocumento,
			'firmaFechaHora': solicitud.firmaFechaHora?.toIso8601String(),
		};
	}

	SolicitudDocumentoFirmado? _solicitudDesdeJson(Map<String, dynamic> json) {
		final servicioId = json['servicioId']?.toString() ?? '';
		final nombreArchivoPdf = json['nombreArchivoPdf']?.toString() ?? '';
		final rutaPdfLocal = json['rutaPdfLocal']?.toString() ?? '';
		final pdfBase64 = json['pdfBytesBase64']?.toString() ?? '';
		if (servicioId.trim().isEmpty || nombreArchivoPdf.trim().isEmpty || pdfBase64.isEmpty) {
			return null;
		}

		Uint8List pdfBytes;
		try {
			pdfBytes = base64Decode(pdfBase64);
		} catch (_) {
			return null;
		}

		final canal = _canalDesdeString(json['canal']?.toString() ?? 'campo');

		return SolicitudDocumentoFirmado(
			servicioId: servicioId,
			canal: canal,
			pdfBytes: pdfBytes,
			nombreArchivoPdf: nombreArchivoPdf,
			rutaPdfLocal: rutaPdfLocal,
			firmaClienteNombre: json['firmaClienteNombre']?.toString(),
			firmaClienteDocumento: json['firmaClienteDocumento']?.toString(),
			firmaFechaHora: DateTime.tryParse(json['firmaFechaHora']?.toString() ?? ''),
		);
	}

	Canal _canalDesdeString(String valor) {
		return Canal.values.firstWhere(
			(canal) => canal.name == valor,
			orElse: () => Canal.campo,
		);
	}

	String _normalizarNombrePdf(String nombreArchivo, String servicioId) {
		final limpio = nombreArchivo.trim();
		final base = limpio.isEmpty ? 'orden_servicio_$servicioId' : limpio;
		if (base.toLowerCase().endsWith('.pdf')) {
			return base;
		}
		return '$base.pdf';
	}
}


