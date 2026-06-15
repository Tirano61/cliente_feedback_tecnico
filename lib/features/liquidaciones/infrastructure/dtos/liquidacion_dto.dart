import 'dart:developer' as developer;

import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';

class LiquidacionDto {
  final String id;
  final EstadoLiquidacion estado;
  final bool aprobado;
  final DateTime? fechaAprobacion;
  final ServicioLiquidacion servicio;
  final TipoSalidaLiquidacion tipoSalida;
  final double km;
  final double? precioKmUsdSnapshotLegacy;
  final List<ItemLiquidacion> items;
  final ResumenLiquidacion resumen;

  const LiquidacionDto({
    required this.id,
    required this.estado,
    required this.aprobado,
    required this.fechaAprobacion,
    required this.servicio,
    required this.tipoSalida,
    required this.km,
    required this.precioKmUsdSnapshotLegacy,
    required this.items,
    required this.resumen,
  });

  factory LiquidacionDto.fromJson(Map<String, dynamic> json) {
    final servicioJson = _mapa(json['servicio']);
    final tipoSalidaJson = _mapa(json['tipoSalida']);
    final resumenJson = _mapa(json['resumen']);
    final itemsJson = _listaMapas(json['items']);

    return LiquidacionDto(
      id: _textoConFallback(json, 'id', contexto: 'liquidacion'),
      estado: _estadoDesdeString(_texto(json['estado'])),
      aprobado: _boolDesdeDynamic(json['aprobado']),
      fechaAprobacion: _fecha(json['fechaAprobacion']),
      servicio: ServicioLiquidacion(
        id: _textoConFallback(servicioJson, 'id', contexto: 'liquidacion.servicio'),
        canal: _textoConFallback(servicioJson, 'canal', contexto: 'liquidacion.servicio'),
        fechaHoraServicio: _fecha(servicioJson['fechaHoraServicio']),
        clienteId: _textoConFallback(servicioJson, 'clienteId', contexto: 'liquidacion.servicio'),
        clienteNombre: _texto(servicioJson['clienteNombre']),
        lugarProvinciaId: _texto(servicioJson['lugarProvinciaId']),
        lugarProvinciaNombre: _texto(servicioJson['lugarProvinciaNombre']),
        lugarDetalle: _texto(servicioJson['lugarDetalle']),
      ),
      tipoSalida: TipoSalidaLiquidacion(
        id: _texto(tipoSalidaJson['id']),
        nombre: _texto(tipoSalidaJson['nombre']),
        precioUsd: _double(tipoSalidaJson['precioUsd']),
      ),
      km: _double(json['km']),
      precioKmUsdSnapshotLegacy: _doubleNullable(json['precioKmUsdSnapshotLegacy']),
      items: itemsJson.map(ItemLiquidacionDto.fromJson).map((dto) => dto.aEntidad()).toList(),
      resumen: ResumenLiquidacion(
        subtotalSalidaUsd: _double(resumenJson['subtotalSalidaUsd']),
        subtotalItemsUsd: _double(resumenJson['subtotalItemsUsd']),
        totalLiquidacionUsd: _double(resumenJson['totalLiquidacionUsd']),
        cantidadItems: _int(resumenJson['cantidadItems']),
      ),
    );
  }

  Liquidacion aEntidad() {
    return Liquidacion(
      id: id,
      estado: estado,
      aprobado: aprobado,
      fechaAprobacion: fechaAprobacion,
      servicio: servicio,
      tipoSalida: tipoSalida,
      km: km,
      precioKmUsdSnapshotLegacy: precioKmUsdSnapshotLegacy,
      items: items,
      resumen: resumen,
    );
  }

  static EstadoLiquidacionFiltro filtroDesdeString(String estado) {
    final normalizado = estado.trim().toLowerCase();
    switch (normalizado) {
      case 'pendiente':
        return EstadoLiquidacionFiltro.pendiente;
      case 'aprobada':
        return EstadoLiquidacionFiltro.aprobada;
      case 'reabierta':
        return EstadoLiquidacionFiltro.reabierta;
      default:
        return EstadoLiquidacionFiltro.todas;
    }
  }

  static String filtroAString(EstadoLiquidacionFiltro filtro) {
    switch (filtro) {
      case EstadoLiquidacionFiltro.pendiente:
        return 'pendiente';
      case EstadoLiquidacionFiltro.aprobada:
        return 'aprobada';
      case EstadoLiquidacionFiltro.reabierta:
        return 'reabierta';
      case EstadoLiquidacionFiltro.todas:
        return 'todas';
    }
  }

  static EstadoLiquidacion _estadoDesdeString(String valor) {
    switch (valor.trim().toLowerCase()) {
      case 'pendiente':
        return EstadoLiquidacion.pendiente;
      case 'aprobada':
        return EstadoLiquidacion.aprobada;
      case 'reabierta':
        return EstadoLiquidacion.reabierta;
      default:
        return EstadoLiquidacion.desconocido;
    }
  }

  static Map<String, dynamic> _mapa(dynamic valor) {
    if (valor is Map<String, dynamic>) {
      return valor;
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _listaMapas(dynamic valor) {
    if (valor is List) {
      return valor.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  static String _texto(dynamic valor) {
    return valor?.toString() ?? '';
  }

  static String _textoConFallback(
    Map<String, dynamic> json,
    String campo, {
    required String contexto,
  }) {
    final valor = _texto(json[campo]);
    if (valor.trim().isEmpty) {
      _registrarParsing('Campo faltante: $contexto.$campo');
      return '';
    }
    return valor;
  }

  static int _int(dynamic valor) {
    if (valor is int) {
      return valor;
    }
    return int.tryParse(_texto(valor)) ?? 0;
  }

  static double _double(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }
    return double.tryParse(_texto(valor)) ?? 0;
  }

  static double? _doubleNullable(dynamic valor) {
    if (valor == null) {
      return null;
    }
    if (valor is num) {
      return valor.toDouble();
    }
    return double.tryParse(_texto(valor));
  }

  static bool _boolDesdeDynamic(dynamic valor) {
    if (valor is bool) {
      return valor;
    }
    final normalizado = _texto(valor).toLowerCase();
    return normalizado == 'true' || normalizado == '1';
  }

  static DateTime? _fecha(dynamic valor) {
    final texto = _texto(valor).trim();
    if (texto.isEmpty) {
      return null;
    }
    return DateTime.tryParse(texto);
  }

  static void _registrarParsing(String mensaje) {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return;
    }
    developer.log('[LiquidacionesDTO] $mensaje');
  }
}

class ItemLiquidacionDto {
  final String id;
  final String tipoServicioId;
  final String tipoServicioNombre;
  final double precioUsdSnapshot;
  final bool aprobado;
  final DateTime? fechaAprobacion;
  final DateTime? createdAt;

  const ItemLiquidacionDto({
    required this.id,
    required this.tipoServicioId,
    required this.tipoServicioNombre,
    required this.precioUsdSnapshot,
    required this.aprobado,
    required this.fechaAprobacion,
    required this.createdAt,
  });

  factory ItemLiquidacionDto.fromJson(Map<String, dynamic> json) {
    return ItemLiquidacionDto(
      id: LiquidacionDto._texto(json['id']),
      tipoServicioId: LiquidacionDto._texto(json['tipoServicioId']),
      tipoServicioNombre: LiquidacionDto._texto(json['tipoServicioNombre']),
      precioUsdSnapshot: LiquidacionDto._double(json['precioUsdSnapshot']),
      aprobado: LiquidacionDto._boolDesdeDynamic(json['aprobado']),
      fechaAprobacion: LiquidacionDto._fecha(json['fechaAprobacion']),
      createdAt: LiquidacionDto._fecha(json['createdAt']),
    );
  }

  ItemLiquidacion aEntidad() {
    return ItemLiquidacion(
      id: id,
      tipoServicioId: tipoServicioId,
      tipoServicioNombre: tipoServicioNombre,
      precioUsdSnapshot: precioUsdSnapshot,
      aprobado: aprobado,
      fechaAprobacion: fechaAprobacion,
      createdAt: createdAt,
    );
  }
}

class RespuestaLiquidacionesDto {
  final List<LiquidacionDto> data;
  final MetaLiquidaciones meta;

  const RespuestaLiquidacionesDto({
    required this.data,
    required this.meta,
  });

  factory RespuestaLiquidacionesDto.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is List)
        ? (json['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(LiquidacionDto.fromJson)
            .toList()
        : <LiquidacionDto>[];

    final metaJson = LiquidacionDto._mapa(json['meta']);

    return RespuestaLiquidacionesDto(
      data: data,
      meta: MetaLiquidaciones(
        page: LiquidacionDto._int(metaJson['page']),
        limit: LiquidacionDto._int(metaJson['limit']),
        total: LiquidacionDto._int(metaJson['total']),
        totalPages: LiquidacionDto._int(metaJson['totalPages']),
        estado: LiquidacionDto.filtroDesdeString(
          LiquidacionDto._texto(metaJson['estado']),
        ),
      ),
    );
  }

  RespuestaLiquidaciones aEntidad() {
    return RespuestaLiquidaciones(
      liquidaciones: data.map((item) => item.aEntidad()).toList(),
      meta: meta,
    );
  }
}

class RespuestaItemsLiquidacionDto {
  final String liquidacionId;
  final List<ItemLiquidacionDto> items;
  final MetaItemsLiquidacion meta;

  const RespuestaItemsLiquidacionDto({
    required this.liquidacionId,
    required this.items,
    required this.meta,
  });

  factory RespuestaItemsLiquidacionDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] is List)
        ? (json['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ItemLiquidacionDto.fromJson)
            .toList()
        : <ItemLiquidacionDto>[];

    final metaJson = LiquidacionDto._mapa(json['meta']);

    return RespuestaItemsLiquidacionDto(
      liquidacionId: LiquidacionDto._texto(json['liquidacionId']),
      items: items,
      meta: MetaItemsLiquidacion(
        totalItems: LiquidacionDto._int(metaJson['totalItems']),
        aprobados: LiquidacionDto._int(metaJson['aprobados']),
        pendientes: LiquidacionDto._int(metaJson['pendientes']),
        subtotalUsdTotal: LiquidacionDto._double(metaJson['subtotalUsdTotal']),
      ),
    );
  }

  RespuestaItemsLiquidacion aEntidad() {
    return RespuestaItemsLiquidacion(
      liquidacionId: liquidacionId,
      items: items.map((item) => item.aEntidad()).toList(),
      meta: meta,
    );
  }
}
