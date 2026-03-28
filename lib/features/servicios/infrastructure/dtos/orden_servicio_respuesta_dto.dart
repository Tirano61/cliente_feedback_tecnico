import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/documento_orden.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/dtos/servicio_dto.dart';

class OrdenServicioRespuestaDto {
	final bool replayed;
	final String servicioId;
	final String idempotencyKey;
	final String estadoOrden;
	final int version;
	final DateTime? fechaHoraServicio;
	final String? timezoneIana;
	final int? utcOffsetMinutos;
	final Servicio servicio;
	final Facturacion? facturacion;
	final List<FacturacionItem> facturacionItems;
	final DocumentoOrden? documento;

	const OrdenServicioRespuestaDto({
		required this.replayed,
		required this.servicioId,
		required this.idempotencyKey,
		required this.estadoOrden,
		required this.version,
		this.fechaHoraServicio,
		this.timezoneIana,
		this.utcOffsetMinutos,
		required this.servicio,
		this.facturacion,
		this.facturacionItems = const [],
		this.documento,
	});

	factory OrdenServicioRespuestaDto.fromJson(Map<String, dynamic> json) {
		final servicio = ServicioDto.fromJson(json).aEntidad();

		return OrdenServicioRespuestaDto(
			replayed: _boolDesdeDynamic(json['replayed']),
			servicioId: json['servicioId']?.toString() ?? json['id']?.toString() ?? '',
			idempotencyKey: json['idempotencyKey']?.toString() ?? '',
			estadoOrden: json['estadoOrden']?.toString() ?? '',
			version: _intDesdeDynamic(json['version'], valorPorDefecto: 1),
			fechaHoraServicio: DateTime.tryParse(json['fechaHoraServicio']?.toString() ?? ''),
			timezoneIana: json['timezoneIana']?.toString(),
			utcOffsetMinutos: _intOpcionalDesdeDynamic(json['utcOffsetMinutos']),
			servicio: servicio,
			facturacion: servicio.facturacion,
			facturacionItems: servicio.facturacionItems,
			documento: servicio.documento,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'replayed': replayed,
			'servicioId': servicioId,
			'idempotencyKey': idempotencyKey,
			'estadoOrden': estadoOrden,
			'version': version,
			'fechaHoraServicio': fechaHoraServicio?.toIso8601String(),
			'timezoneIana': timezoneIana,
			'utcOffsetMinutos': utcOffsetMinutos,
			'servicio': {
				'canal': servicio.canal.name,
				'clienteId': servicio.clienteId,
				'lugarProvinciaId': servicio.lugarProvinciaId,
				'lugarDetalle': servicio.lugarDetalle,
				'equipoNroSerie': servicio.equipoNroSerie,
				'equipoModelo': servicio.equipoModelo,
				'equipoUbicacion': servicio.equipoUbicacion,
				'equipoAnio': servicio.equipoAnio,
				'partesFallaron': servicio.partesFallaron,
				'km': servicio.km,
				'sintoma': servicio.sintoma,
				'diagnosticoDetalle': servicio.diagnosticoDetalle,
				'diagnosticoCatId': servicio.diagnosticoCatIds,
				'resolucionId': servicio.resolucionId.trim().isEmpty
						? const <String>[]
						: [servicio.resolucionId],
				'observaciones': servicio.observaciones,
				'productosFalla': servicio.productosFalla
						.map(
							(item) => {
								'parteFallo': item.parteFallo,
								'productoFallaId': item.productoFallaId,
							},
						)
						.toList(),
			},
			'facturacion': facturacion == null
					? null
					: {
						'cotizacionDolarSnapshot': facturacion!.cotizacionDolarSnapshot,
						'valorKmUsdSnapshot': facturacion!.valorKmUsdSnapshot,
						'kmCantidad': facturacion!.kmCantidad,
						'subtotalKmUsd': facturacion!.subtotalKmUsd,
						'subtotalKmArs': facturacion!.subtotalKmArs,
						'subtotalGeneralUsd': facturacion!.subtotalGeneralUsd,
						'subtotalGeneralArs': facturacion!.subtotalGeneralArs,
						'ivaPorcentaje': facturacion!.ivaPorcentaje,
						'totalConIvaArs': facturacion!.totalConIvaArs,
						'descuentoPorcentaje': facturacion!.descuentoPorcentaje,
						'totalFinalArs': facturacion!.totalFinalArs,
						'version': facturacion!.version,
					},
			'facturacionItems': facturacionItems
					.map(
						(item) => {
							'tipoItem': item.tipoItem,
							'referenciaId': item.referenciaId,
							'descripcion': item.descripcion,
							'cantidad': item.cantidad,
							'precioUnitarioUsd': item.precioUnitarioUsd,
							'precioUnitarioArs': item.precioUnitarioArs,
							'subtotalUsd': item.subtotalUsd,
							'subtotalArs': item.subtotalArs,
						},
					)
					.toList(),
			'documento': documento == null
					? null
					: {
						'pdfHashSha256': documento!.pdfHashSha256,
						'pdfUrl': documento!.pdfUrl,
						'firmaClienteNombre': documento!.firmaClienteNombre,
						'firmaClienteDocumento': documento!.firmaClienteDocumento,
						'firmaFechaHora': documento!.firmaFechaHora?.toIso8601String(),
					},
		};
	}

	OrdenServicioRespuesta aEntidad() {
		return OrdenServicioRespuesta(
			replayed: replayed,
			servicioId: servicioId,
			idempotencyKey: idempotencyKey,
			estadoOrden: estadoOrden,
			version: version,
			fechaHoraServicio: fechaHoraServicio,
			timezoneIana: timezoneIana,
			utcOffsetMinutos: utcOffsetMinutos,
			servicio: servicio,
			facturacion: facturacion,
			facturacionItems: facturacionItems,
			documento: documento,
		);
	}

	static int _intDesdeDynamic(dynamic valor, {required int valorPorDefecto}) {
		if (valor is int) {
			return valor;
		}
		if (valor is num) {
			return valor.toInt();
		}
		if (valor is String) {
			return int.tryParse(valor) ?? valorPorDefecto;
		}
		return valorPorDefecto;
	}

	static int? _intOpcionalDesdeDynamic(dynamic valor) {
		if (valor == null) {
			return null;
		}
		return _intDesdeDynamic(valor, valorPorDefecto: 0);
	}

	static bool _boolDesdeDynamic(dynamic valor) {
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
		return false;
	}
}
