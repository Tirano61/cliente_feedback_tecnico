import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/repositories/i_liquidacion_repository.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/infrastructure/datasources/liquidacion_remote_data_source.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/infrastructure/dtos/liquidacion_dto.dart';

class LiquidacionRepositoryImpl implements ILiquidacionRepository {
  final LiquidacionRemoteDataSource _remoteDataSource;

  LiquidacionRepositoryImpl(this._remoteDataSource);

  @override
  Future<RespuestaLiquidaciones> obtenerMisLiquidaciones({
    required EstadoLiquidacionFiltro estado,
    required int page,
    required int limit,
  }) async {
    final estadoQuery = LiquidacionDto.filtroAString(estado);
    var response = await _remoteDataSource.obtenerMisLiquidacionesRaw(
      estado: LiquidacionDto.filtroAString(estado),
      page: page,
      limit: limit,
    );

    if (response.statusCode == 400 && _debeReintentarSinPaginacion(response.body)) {
      response = await _remoteDataSource.obtenerMisLiquidacionesRawSinPaginacion(
        estado: estadoQuery,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Sesion expirada. Inicia sesion nuevamente.');
    }

    if (response.statusCode != 200) {
      throw ServerException(
        _extraerMensajeError(response.body) ??
            'No se pudieron obtener tus liquidaciones.',
        statusCode: response.statusCode,
      );
    }

    final payload = _remoteDataSource.parsearMapaSeguro(response.body);
    if (payload == null) {
      throw const ServerException('Respuesta invalida al cargar liquidaciones.');
    }

    return RespuestaLiquidacionesDto.fromJson(payload).aEntidad();
  }

  @override
  Future<RespuestaItemsLiquidacion> obtenerItemsLiquidacion(String liquidacionId) async {
    final response = await _remoteDataSource.obtenerItemsLiquidacionRaw(liquidacionId);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Sesion expirada. Inicia sesion nuevamente.');
    }

    if (response.statusCode != 200) {
      throw ServerException(
        _extraerMensajeError(response.body) ??
            'No se pudieron obtener los items de la liquidacion.',
        statusCode: response.statusCode,
      );
    }

    final payload = _remoteDataSource.parsearMapaSeguro(response.body);
    if (payload == null) {
      throw const ServerException('Respuesta invalida al cargar items.');
    }

    return RespuestaItemsLiquidacionDto.fromJson(payload).aEntidad();
  }

  String? _extraerMensajeError(String body) {
    final json = _remoteDataSource.parsearMapaSeguro(body);
    if (json == null) {
      return null;
    }

    final mensaje = json['message'];
    if (mensaje is String && mensaje.trim().isNotEmpty) {
      return mensaje;
    }
    if (mensaje is List && mensaje.isNotEmpty) {
      return mensaje.first.toString();
    }

    return null;
  }

  bool _debeReintentarSinPaginacion(String body) {
    final json = _remoteDataSource.parsearMapaSeguro(body);
    if (json == null) {
      return false;
    }

    final mensaje = json['message'];
    if (mensaje is String) {
      return _contieneErrorParametroNoPermitido(mensaje);
    }

    if (mensaje is List) {
      return mensaje.any(
        (item) => _contieneErrorParametroNoPermitido(item.toString()),
      );
    }

    return false;
  }

  bool _contieneErrorParametroNoPermitido(String texto) {
    final normalizado = texto.toLowerCase();
    return normalizado.contains('property page should not exist') ||
        normalizado.contains('property limit should not exist');
  }
}
