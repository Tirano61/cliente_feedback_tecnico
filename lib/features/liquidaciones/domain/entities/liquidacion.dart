import 'package:equatable/equatable.dart';

enum EstadoLiquidacion { pendiente, aprobada, reabierta, desconocido }

enum EstadoLiquidacionFiltro { todas, pendiente, aprobada, reabierta }

class ServicioLiquidacion extends Equatable {
  final String id;
  final String canal;
  final DateTime? fechaHoraServicio;
  final String clienteId;
  final String clienteNombre;
  final String lugarProvinciaId;
  final String lugarProvinciaNombre;
  final String lugarDetalle;

  const ServicioLiquidacion({
    required this.id,
    required this.canal,
    required this.fechaHoraServicio,
    required this.clienteId,
    required this.clienteNombre,
    required this.lugarProvinciaId,
    required this.lugarProvinciaNombre,
    required this.lugarDetalle,
  });

  @override
  List<Object?> get props => [
        id,
        canal,
        fechaHoraServicio,
        clienteId,
        clienteNombre,
        lugarProvinciaId,
        lugarProvinciaNombre,
        lugarDetalle,
      ];
}

class TipoSalidaLiquidacion extends Equatable {
  final String id;
  final String nombre;
  final double precioUsd;

  const TipoSalidaLiquidacion({
    required this.id,
    required this.nombre,
    required this.precioUsd,
  });

  @override
  List<Object?> get props => [id, nombre, precioUsd];
}

class ItemLiquidacion extends Equatable {
  final String id;
  final String tipoServicioId;
  final String tipoServicioNombre;
  final double precioUsdSnapshot;
  final bool aprobado;
  final DateTime? fechaAprobacion;
  final DateTime? createdAt;

  const ItemLiquidacion({
    required this.id,
    required this.tipoServicioId,
    required this.tipoServicioNombre,
    required this.precioUsdSnapshot,
    required this.aprobado,
    required this.fechaAprobacion,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        tipoServicioId,
        tipoServicioNombre,
        precioUsdSnapshot,
        aprobado,
        fechaAprobacion,
        createdAt,
      ];
}

class ResumenLiquidacion extends Equatable {
  final double subtotalSalidaUsd;
  final double subtotalItemsUsd;
  final double totalLiquidacionUsd;
  final int cantidadItems;

  const ResumenLiquidacion({
    required this.subtotalSalidaUsd,
    required this.subtotalItemsUsd,
    required this.totalLiquidacionUsd,
    required this.cantidadItems,
  });

  @override
  List<Object?> get props => [
        subtotalSalidaUsd,
        subtotalItemsUsd,
        totalLiquidacionUsd,
        cantidadItems,
      ];
}

class Liquidacion extends Equatable {
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

  const Liquidacion({
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

  @override
  List<Object?> get props => [
        id,
        estado,
        aprobado,
        fechaAprobacion,
        servicio,
        tipoSalida,
        km,
        precioKmUsdSnapshotLegacy,
        items,
        resumen,
      ];
}

class MetaLiquidaciones extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final EstadoLiquidacionFiltro estado;

  const MetaLiquidaciones({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.estado,
  });

  @override
  List<Object?> get props => [page, limit, total, totalPages, estado];
}

class RespuestaLiquidaciones extends Equatable {
  final List<Liquidacion> liquidaciones;
  final MetaLiquidaciones meta;

  const RespuestaLiquidaciones({
    required this.liquidaciones,
    required this.meta,
  });

  @override
  List<Object?> get props => [liquidaciones, meta];
}

class MetaItemsLiquidacion extends Equatable {
  final int totalItems;
  final int aprobados;
  final int pendientes;
  final double subtotalUsdTotal;

  const MetaItemsLiquidacion({
    required this.totalItems,
    required this.aprobados,
    required this.pendientes,
    required this.subtotalUsdTotal,
  });

  @override
  List<Object?> get props => [totalItems, aprobados, pendientes, subtotalUsdTotal];
}

class RespuestaItemsLiquidacion extends Equatable {
  final String liquidacionId;
  final List<ItemLiquidacion> items;
  final MetaItemsLiquidacion meta;

  const RespuestaItemsLiquidacion({
    required this.liquidacionId,
    required this.items,
    required this.meta,
  });

  @override
  List<Object?> get props => [liquidacionId, items, meta];
}
