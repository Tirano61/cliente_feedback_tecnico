import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/resultado_asignacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/catalogos_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/historial_unidad_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/ingreso_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/recepcion_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/resultado_asignacion_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/solicitudes_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/unidad_dto.dart';
import 'package:http/http.dart' as http;

class FabricaRepositoryImpl implements IFabricaRepository {
	final ApiClient apiClient;

	/// Claves del body de error que no son datos extra de la regla.
	static const Set<String> _clavesBaseError = {
		'statusCode',
		'error',
		'codigo',
		'mensaje',
		'message',
	};

	FabricaRepositoryImpl(this.apiClient);

	@override
	Future<List<Componente>> obtenerComponentes({required String productoId}) async {
		final response = await apiClient.get(
			_conQuery(ApiConstants.fabricaComponentes, {'productoId': productoId}),
		);
		return _lista(
			response,
			'obtener los componentes',
			(json) => ComponenteDto.fromJson(json).aEntidad(),
		);
	}

	@override
	Future<List<Causa>> obtenerCausas() async {
		final response = await apiClient.get(ApiConstants.fabricaCausas);
		return _lista(
			response,
			'obtener las causas',
			(json) => CausaDto.fromJson(json).aEntidad(),
		);
	}

	@override
	Future<PaginaFabrica<Unidad>> buscarUnidades({
		TipoUnidad? tipo,
		EstadoUnidad? estado,
		String nroSerie = '',
		String busqueda = '',
		required int pagina,
		required int limite,
	}) async {
		final serie = nroSerie.trim();
		final texto = busqueda.trim();
		final response = await apiClient.get(
			_conQuery(ApiConstants.fabricaUnidades, {
				if (tipo != null) 'tipo': CodigosFabrica.codigoTipoUnidad(tipo),
				if (estado != null) 'estado': CodigosFabrica.codigoEstadoUnidad(estado),
				if (serie.isNotEmpty) 'nroSerie': serie,
				if (texto.isNotEmpty) 'q': texto,
				'page': '$pagina',
				'limit': '$limite',
			}),
		);
		return _pagina(
			response,
			'buscar las piezas',
			(json) => UnidadDto.fromJson(json).aEntidad(),
			pagina: pagina,
			limite: limite,
		);
	}

	@override
	Future<Unidad> obtenerUnidad(String unidadId) async {
		final response = await apiClient.get(ApiConstants.fabricaUnidad(unidadId));
		return UnidadDto.fromJson(_objeto(response, 'obtener la pieza')).aEntidad();
	}

	@override
	Future<HistorialUnidad> obtenerHistorialUnidad(String unidadId) async {
		final response = await apiClient.get(ApiConstants.fabricaUnidadHistorial(unidadId));
		return HistorialUnidadDto.fromJson(
			_objeto(response, 'obtener el historial de la pieza'),
		).aEntidad();
	}

	@override
	Future<ResultadoAsignacion> asignarUnidad(SolicitudAsignacion solicitud) async {
		final response = await apiClient.post(
			ApiConstants.fabricaAsignaciones,
			SolicitudAsignacionDto.desdeEntidad(solicitud).toJson(),
		);
		return ResultadoAsignacionDto.fromJson(
			_objeto(response, 'poner la pieza en el indicador'),
		).aEntidad();
	}

	@override
	Future<Recepcion> crearRecepcion(NuevaRecepcion recepcion) async {
		final response = await apiClient.post(
			ApiConstants.fabricaRecepciones,
			NuevaRecepcionDto.desdeEntidad(recepcion).toJson(),
		);
		return RecepcionDto.fromJson(_objeto(response, 'registrar la recepcion')).aEntidad();
	}

	@override
	Future<PaginaFabrica<Recepcion>> obtenerRecepciones({
		EstadoRecepcion? estado,
		bool? abiertas,
		String? clienteId,
		String busqueda = '',
		required int pagina,
		required int limite,
	}) async {
		final cliente = clienteId?.trim() ?? '';
		final texto = busqueda.trim();
		final response = await apiClient.get(
			_conQuery(ApiConstants.fabricaRecepciones, {
				if (estado != null) 'estado': CodigosFabrica.codigoEstadoRecepcion(estado),
				if (abiertas != null) 'abiertas': '$abiertas',
				if (cliente.isNotEmpty) 'clienteId': cliente,
				if (texto.isNotEmpty) 'q': texto,
				'page': '$pagina',
				'limit': '$limite',
			}),
		);
		return _pagina(
			response,
			'obtener los equipos en fabrica',
			(json) => RecepcionDto.fromJson(json).aEntidad(),
			pagina: pagina,
			limite: limite,
		);
	}

	@override
	Future<Recepcion> obtenerRecepcion(String recepcionId) async {
		final response = await apiClient.get(ApiConstants.fabricaRecepcion(recepcionId));
		return RecepcionDto.fromJson(_objeto(response, 'obtener la recepcion')).aEntidad();
	}

	@override
	Future<Recepcion> cambiarEstadoRecepcion({
		required String recepcionId,
		required EstadoRecepcion estado,
		String? observacion,
	}) async {
		final response = await apiClient.patch(
			ApiConstants.fabricaRecepcionEstado(recepcionId),
			CambioEstadoRecepcionBodyDto(estado: estado, observacion: observacion).toJson(),
		);
		return RecepcionDto.fromJson(
			_objeto(response, 'cambiar el estado de la recepcion'),
		).aEntidad();
	}

	@override
	Future<Recepcion> vincularServicioRecepcion({
		required String recepcionId,
		required String servicioId,
	}) async {
		final response = await apiClient.patch(
			ApiConstants.fabricaRecepcionServicio(recepcionId),
			{'servicioId': servicioId},
		);
		return RecepcionDto.fromJson(
			_objeto(response, 'vincular el servicio a la recepcion'),
		).aEntidad();
	}

	@override
	Future<Recepcion> devolverRecepcion({
		required String recepcionId,
		required SolicitudDevolucion solicitud,
	}) async {
		final response = await apiClient.patch(
			ApiConstants.fabricaRecepcionDevolucion(recepcionId),
			SolicitudDevolucionDto.desdeEntidad(solicitud).toJson(),
		);
		return RecepcionDto.fromJson(
			_objeto(response, 'registrar la devolucion'),
		).aEntidad();
	}

	@override
	Future<Ingreso> crearIngreso(NuevoIngreso ingreso) async {
		final response = await apiClient.post(
			ApiConstants.fabricaIngresos,
			NuevoIngresoDto.desdeEntidad(ingreso).toJson(),
		);
		return IngresoDto.fromJson(_objeto(response, 'registrar el ingreso')).aEntidad();
	}

	@override
	Future<PaginaFabrica<Ingreso>> obtenerIngresos({
		EstadoIngreso? estado,
		TipoUnidad? tipo,
		String busqueda = '',
		required int pagina,
		required int limite,
	}) async {
		final texto = busqueda.trim();
		final response = await apiClient.get(
			_conQuery(ApiConstants.fabricaIngresos, {
				if (estado != null) 'estado': CodigosFabrica.codigoEstadoIngreso(estado),
				if (tipo != null) 'tipo': CodigosFabrica.codigoTipoUnidad(tipo),
				if (texto.isNotEmpty) 'q': texto,
				'page': '$pagina',
				'limit': '$limite',
			}),
		);
		return _pagina(
			response,
			'obtener las piezas ingresadas',
			(json) => IngresoDto.fromJson(json).aEntidad(),
			pagina: pagina,
			limite: limite,
		);
	}

	@override
	Future<Ingreso> obtenerIngreso(String ingresoId) async {
		final response = await apiClient.get(ApiConstants.fabricaIngreso(ingresoId));
		return IngresoDto.fromJson(_objeto(response, 'obtener el ingreso')).aEntidad();
	}

	@override
	Future<Ingreso> derivarIngreso({
		required String ingresoId,
		String? observacion,
	}) async {
		final response = await apiClient.patch(
			ApiConstants.fabricaIngresoDerivar(ingresoId),
			{'observacion': ?observacion},
		);
		return IngresoDto.fromJson(_objeto(response, 'derivar la placa a desarrollo')).aEntidad();
	}

	@override
	Future<Ingreso> cargarFallaIngreso({
		required String ingresoId,
		required SolicitudFalla solicitud,
	}) async {
		final response = await apiClient.put(
			ApiConstants.fabricaIngresoFalla(ingresoId),
			SolicitudFallaDto.desdeEntidad(solicitud).toJson(),
		);
		return IngresoDto.fromJson(_objeto(response, 'cargar la falla')).aEntidad();
	}

	@override
	Future<Ingreso> cargarReparacionIngreso({
		required String ingresoId,
		required SolicitudReparacion solicitud,
	}) async {
		final response = await apiClient.post(
			ApiConstants.fabricaIngresoReparacion(ingresoId),
			SolicitudReparacionDto.desdeEntidad(solicitud).toJson(),
		);
		return IngresoDto.fromJson(_objeto(response, 'cargar la reparacion')).aEntidad();
	}

	String _conQuery(String path, Map<String, String> parametros) {
		if (parametros.isEmpty) {
			return path;
		}
		return '$path?${Uri(queryParameters: parametros).query}';
	}

	/// Respuesta con un solo recurso. `accion` completa los mensajes:
	/// `No se pudo {accion}.` / `Respuesta invalida al {accion}.`.
	Map<String, dynamic> _objeto(http.Response response, String accion) {
		_verificarRespuesta(response, accion);
		final json = _decodeJsonSeguro(response.body);
		if (json is Map<String, dynamic>) {
			final data = json['data'];
			return data is Map<String, dynamic> ? data : json;
		}
		throw ServerException('Respuesta invalida al $accion.');
	}

	List<T> _lista<T>(
		http.Response response,
		String accion,
		T Function(Map<String, dynamic> json) parsear,
	) {
		_verificarRespuesta(response, accion);
		final json = _decodeJsonSeguro(response.body);
		final lista = json is Map<String, dynamic> ? json['data'] : json;
		if (lista is! List) {
			throw ServerException('Respuesta invalida al $accion.');
		}
		return lista.whereType<Map<String, dynamic>>().map(parsear).toList();
	}

	PaginaFabrica<T> _pagina<T>(
		http.Response response,
		String accion,
		T Function(Map<String, dynamic> json) parsear, {
		required int pagina,
		required int limite,
	}) {
		_verificarRespuesta(response, accion);
		final json = _decodeJsonSeguro(response.body);
		if (json is! Map<String, dynamic> ||
				json['data'] is! List ||
				json['meta'] is! Map<String, dynamic>) {
			throw ServerException('Respuesta invalida al $accion.');
		}

		final meta = json['meta'] as Map<String, dynamic>;
		return PaginaFabrica<T>(
			items: (json['data'] as List)
					.whereType<Map<String, dynamic>>()
					.map(parsear)
					.toList(),
			pagina: (meta['page'] as num?)?.toInt() ?? pagina,
			limite: (meta['limit'] as num?)?.toInt() ?? limite,
			total: (meta['total'] as num?)?.toInt() ?? 0,
			totalPaginas: (meta['totalPages'] as num?)?.toInt() ?? 0,
		);
	}

	/// Un body con `codigo` es una regla de negocio del modulo y se lanza como
	/// `ReglaFabricaException`; cualquier otro error, como `ServerException`.
	void _verificarRespuesta(http.Response response, String accion) {
		if (response.statusCode >= 200 && response.statusCode < 300) {
			return;
		}

		final json = _decodeJsonSeguro(response.body);
		final mensajeBackend = json is Map<String, dynamic>
				? _texto(json['mensaje']) ?? _mensajeNest(json['message'])
				: null;
		final codigo = json is Map<String, dynamic> ? _texto(json['codigo']) : null;

		if (codigo != null) {
			throw ReglaFabricaException(
				codigo: codigo,
				mensaje: mensajeBackend ?? 'No se pudo $accion.',
				statusCode: response.statusCode,
				extra: Map<String, dynamic>.from(json as Map<String, dynamic>)
					..removeWhere((clave, _) => _clavesBaseError.contains(clave)),
			);
		}

		throw ServerException(
			mensajeBackend ?? 'No se pudo $accion.',
			statusCode: response.statusCode,
		);
	}

	/// `message` de Nest: texto, o lista de errores de validacion (400).
	String? _mensajeNest(dynamic message) {
		if (message is List && message.isNotEmpty) {
			return _texto(message.first);
		}
		return _texto(message);
	}

	String? _texto(dynamic valor) {
		if (valor is String && valor.trim().isNotEmpty) {
			return valor.trim();
		}
		return null;
	}

	dynamic _decodeJsonSeguro(String body) {
		try {
			return jsonDecode(body);
		} catch (_) {
			return null;
		}
	}
}
