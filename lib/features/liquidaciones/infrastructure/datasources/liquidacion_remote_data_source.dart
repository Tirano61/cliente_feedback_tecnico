import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:http/http.dart' as http;

class LiquidacionRemoteDataSource {
  final ApiClient _apiClient;

  LiquidacionRemoteDataSource(this._apiClient);

  Future<http.Response> obtenerMisLiquidacionesRaw({
    required String estado,
    required int page,
    required int limit,
  }) {
    final queryEstado = Uri.encodeQueryComponent(estado);
    return _apiClient.get(
      '${ApiConstants.liquidacionesMias}?estado=$queryEstado&page=$page&limit=$limit',
    );
  }

  Future<http.Response> obtenerMisLiquidacionesRawSinPaginacion({
    required String estado,
  }) {
    final queryEstado = Uri.encodeQueryComponent(estado);
    return _apiClient.get('${ApiConstants.liquidacionesMias}?estado=$queryEstado');
  }

  Future<http.Response> obtenerItemsLiquidacionRaw(String liquidacionId) {
    return _apiClient.get(ApiConstants.liquidacionItems(liquidacionId));
  }

  Map<String, dynamic>? parsearMapaSeguro(String body) {
    try {
      final dynamic json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
