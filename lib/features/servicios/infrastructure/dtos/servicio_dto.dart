import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/documento_orden.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';

class ServicioDto {
	final String id;
	final String? idempotencyKey;
	final DateTime? fechaHoraServicio;
	final String? timezoneIana;
	final int? utcOffsetMinutos;
	final Canal canal;
	final String clienteId;
	final String lugarProvinciaId;
	final String lugarDetalle;
	final String equipoNroSerie;
	final String equipoModelo;
	final String equipoUbicacion;
	final int equipoAnio;
	final List<String> partesFallaron;
	final int km;
	final String sintoma;
	final String diagnosticoDetalle;
	final List<String> diagnosticoCatIds;
	final String resolucionId;
	final String? observaciones;
	final List<String> productoIds;
	final List<ProductoFalla> productosFalla;
	final Facturacion? facturacion;
	final List<FacturacionItem> facturacionItems;
	final DocumentoOrden? documento;

	final String tecnicoId;
	final DateTime? fecha;
	final bool resuelto;
	final bool aprobado;

	const ServicioDto({
		required this.id,
		this.idempotencyKey,
		this.fechaHoraServicio,
		this.timezoneIana,
		this.utcOffsetMinutos,
		required this.canal,
		required this.clienteId,
		required this.lugarProvinciaId,
		required this.lugarDetalle,
		required this.equipoNroSerie,
		required this.equipoModelo,
		required this.equipoUbicacion,
		required this.equipoAnio,
		required this.partesFallaron,
		required this.km,
		required this.sintoma,
		required this.diagnosticoDetalle,
		required this.diagnosticoCatIds,
		required this.resolucionId,
		this.observaciones,
		required this.productoIds,
		this.productosFalla = const [],
		this.facturacion,
		this.facturacionItems = const [],
		this.documento,
		this.tecnicoId = '',
		this.fecha,
		this.resuelto = true,
		this.aprobado = false,
	});

	factory ServicioDto.fromJson(Map<String, dynamic> json) {
		final servicioJson = _mapaDesdeDynamic(json['servicio']) ?? json;
		final facturacionJson = _mapaDesdeDynamic(json['facturacion']);
		final documentoJson = _mapaDesdeDynamic(json['documento']);
		final productosFallaJson = _listaMapasDesdeDynamic(servicioJson['productosFalla']);
		final facturacionItemsJson = _listaMapasDesdeDynamic(json['facturacionItems']);

		final productoIds = _listaString(
			servicioJson['productoIds'] ??
					servicioJson['producto_ids'] ??
					servicioJson['producto_id'],
		);

		return ServicioDto(
			id: json['id']?.toString() ?? json['servicioId']?.toString() ?? '',
			idempotencyKey: json['idempotencyKey']?.toString(),
			fechaHoraServicio: DateTime.tryParse(json['fechaHoraServicio']?.toString() ?? ''),
			timezoneIana: json['timezoneIana']?.toString(),
			utcOffsetMinutos: _intOpcionalDesdeDynamic(json['utcOffsetMinutos']),
			canal: _canalDesdeString(servicioJson['canal']?.toString() ?? 'campo'),
			clienteId:
					servicioJson['clienteId']?.toString() ??
					servicioJson['cliente_id']?.toString() ??
					'',
			lugarProvinciaId:
					servicioJson['lugarProvinciaId']?.toString() ??
					servicioJson['lugar_provincia_id']?.toString() ??
					servicioJson['zona_id']?.toString() ??
					'',
			lugarDetalle:
					servicioJson['lugarDetalle']?.toString() ??
					servicioJson['lugar_detalle']?.toString() ??
					'',
			equipoNroSerie:
					servicioJson['equipoNroSerie']?.toString() ??
					servicioJson['equipo_nro_serie']?.toString() ??
					'',
			equipoModelo:
					servicioJson['equipoModelo']?.toString() ??
					servicioJson['equipo_modelo']?.toString() ??
					'',
			equipoUbicacion:
					servicioJson['equipoUbicacion']?.toString() ??
					servicioJson['equipo_ubicacion']?.toString() ??
					'',
			equipoAnio: _intDesdeDynamic(servicioJson['equipoAnio'] ?? servicioJson['equipo_anio']),
			partesFallaron:
					_listaString(servicioJson['partesFallaron'] ?? servicioJson['partes_fallaron']),
			km: _intDesdeDynamic(servicioJson['km']),
			sintoma: servicioJson['sintoma']?.toString() ?? '',
			diagnosticoDetalle:
					servicioJson['diagnosticoDetalle']?.toString() ??
					servicioJson['diagnostico_detalle']?.toString() ??
					'',
			diagnosticoCatIds: _listaString(
				servicioJson['diagnosticoCatId'] ?? servicioJson['diagnostico_cat_id'],
			),
			resolucionId: _primerValorListaOString(
				servicioJson['resolucionId'] ?? servicioJson['resolucion_id'],
			),
			observaciones: servicioJson['observaciones']?.toString(),
			productoIds: productoIds,
			productosFalla: productosFallaJson
					.map(
						(item) => ProductoFalla(
							parteFallo: item['parteFallo']?.toString() ?? '',
							productoFallaId: item['productoFallaId']?.toString() ?? '',
						),
					)
					.where(
						(item) =>
							item.parteFallo.trim().isNotEmpty &&
							item.productoFallaId.trim().isNotEmpty,
					)
					.toList(),
			facturacion: facturacionJson == null
					? null
					: Facturacion(
							cotizacionDolarSnapshot:
								_doubleDesdeDynamic(facturacionJson['cotizacionDolarSnapshot']),
							valorKmUsdSnapshot:
								_doubleDesdeDynamic(facturacionJson['valorKmUsdSnapshot']),
							kmCantidad: _doubleDesdeDynamic(facturacionJson['kmCantidad']),
							subtotalKmUsd: _doubleDesdeDynamic(facturacionJson['subtotalKmUsd']),
							subtotalKmArs: _doubleDesdeDynamic(facturacionJson['subtotalKmArs']),
							subtotalGeneralUsd:
								_doubleDesdeDynamic(facturacionJson['subtotalGeneralUsd']),
							subtotalGeneralArs:
								_doubleDesdeDynamic(facturacionJson['subtotalGeneralArs']),
							ivaPorcentaje: _doubleDesdeDynamic(facturacionJson['ivaPorcentaje']),
							totalConIvaArs: _doubleDesdeDynamic(facturacionJson['totalConIvaArs']),
							descuentoPorcentaje:
								_doubleDesdeDynamic(facturacionJson['descuentoPorcentaje']),
							totalFinalArs: _doubleDesdeDynamic(facturacionJson['totalFinalArs']),
							version: _intDesdeDynamic(facturacionJson['version']),
						),
			facturacionItems: facturacionItemsJson
					.map(
						(item) => FacturacionItem(
							tipoItem: item['tipoItem']?.toString() ?? '',
							referenciaId: item['referenciaId']?.toString(),
							descripcion: item['descripcion']?.toString() ?? '',
							cantidad: _doubleDesdeDynamic(item['cantidad']),
							precioUnitarioUsd: _doubleDesdeDynamic(item['precioUnitarioUsd']),
							precioUnitarioArs: _doubleDesdeDynamic(item['precioUnitarioArs']),
							subtotalUsd: _doubleDesdeDynamic(item['subtotalUsd']),
							subtotalArs: _doubleDesdeDynamic(item['subtotalArs']),
						),
					)
					.toList(),
			documento: documentoJson == null
					? null
					: DocumentoOrden(
							pdfHashSha256: documentoJson['pdfHashSha256']?.toString(),
							pdfUrl: documentoJson['pdfUrl']?.toString(),
							firmaClienteNombre: documentoJson['firmaClienteNombre']?.toString(),
							firmaClienteDocumento: documentoJson['firmaClienteDocumento']?.toString(),
							firmaFechaHora:
								DateTime.tryParse(documentoJson['firmaFechaHora']?.toString() ?? ''),
						),
			tecnicoId: json['tecnicoId']?.toString() ?? json['tecnico_id']?.toString() ?? '',
			fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
			resuelto: json['resuelto'] == true,
			aprobado: _aprobadoDesdeJson(json),
		);
	}

	Map<String, dynamic> toJson() {
		final body = <String, dynamic>{
			'canal': canal.name,
			'clienteId': clienteId,
			'lugarProvinciaId': lugarProvinciaId,
			'lugarDetalle': lugarDetalle,
			'equipoNroSerie': equipoNroSerie,
			'equipoModelo': equipoModelo,
			'equipoUbicacion': equipoUbicacion,
			'equipoAnio': equipoAnio,
			'partesFallaron': partesFallaron,
			'km': km,
			'sintoma': sintoma,
			'diagnosticoDetalle': diagnosticoDetalle,
			'diagnosticoCatId': diagnosticoCatIds,
			'resolucionId': resolucionId.trim().isEmpty ? const <String>[] : [resolucionId],
			'productosFalla': _productosFallaJsonParaEnvio(),
			'productoIds': productoIds,
		};

		if (idempotencyKey != null && idempotencyKey!.trim().isNotEmpty) {
			body['idempotencyKey'] = idempotencyKey;
		}
		if (fechaHoraServicio != null) {
			body['fechaHoraServicio'] = fechaHoraServicio!.toIso8601String();
		}
		if (timezoneIana != null && timezoneIana!.trim().isNotEmpty) {
			body['timezoneIana'] = timezoneIana;
		}
		if (utcOffsetMinutos != null) {
			body['utcOffsetMinutos'] = utcOffsetMinutos;
		}
		if (facturacion != null) {
			body['facturacion'] = {
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
			};
		}
		if (facturacionItems.isNotEmpty) {
			body['facturacionItems'] = facturacionItems
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
					.toList();
		}
		if (documento != null) {
			body['documento'] = {
				'pdfHashSha256': documento!.pdfHashSha256,
				'pdfUrl': documento!.pdfUrl,
				'firmaClienteNombre': documento!.firmaClienteNombre,
				'firmaClienteDocumento': documento!.firmaClienteDocumento,
				'firmaFechaHora': documento!.firmaFechaHora?.toIso8601String(),
			};
		}

		final observacionesNormalizadas = observaciones?.trim();
		if (observacionesNormalizadas != null && observacionesNormalizadas.isNotEmpty) {
			body['observaciones'] = observacionesNormalizadas;
		}

		return body;
	}

	Servicio aEntidad() {
		return Servicio(
			id: id,
			idempotencyKey: idempotencyKey,
			fechaHoraServicio: fechaHoraServicio,
			timezoneIana: timezoneIana,
			utcOffsetMinutos: utcOffsetMinutos,
			canal: canal,
			clienteId: clienteId,
			lugarProvinciaId: lugarProvinciaId,
			lugarDetalle: lugarDetalle,
			equipoNroSerie: equipoNroSerie,
			equipoModelo: equipoModelo,
			equipoUbicacion: equipoUbicacion,
			equipoAnio: equipoAnio,
			partesFallaron: partesFallaron,
			km: km,
			sintoma: sintoma,
			diagnosticoDetalle: diagnosticoDetalle,
			diagnosticoCatIds: diagnosticoCatIds,
			resolucionId: resolucionId,
			observaciones: observaciones,
			productoIds: productoIds,
			productosFalla: productosFalla,
			facturacion: facturacion,
			facturacionItems: facturacionItems,
			documento: documento,
			tecnicoId: tecnicoId,
			fecha: fecha,
			resuelto: resuelto,
			aprobado: aprobado,
		);
	}

	factory ServicioDto.desdeEntidad(Servicio servicio) {
		return ServicioDto(
			id: servicio.id,
			idempotencyKey: servicio.idempotencyKey,
			fechaHoraServicio: servicio.fechaHoraServicio,
			timezoneIana: servicio.timezoneIana,
			utcOffsetMinutos: servicio.utcOffsetMinutos,
			canal: servicio.canal,
			clienteId: servicio.clienteId,
			lugarProvinciaId: servicio.lugarProvinciaId,
			lugarDetalle: servicio.lugarDetalle,
			equipoNroSerie: servicio.equipoNroSerie,
			equipoModelo: servicio.equipoModelo,
			equipoUbicacion: servicio.equipoUbicacion,
			equipoAnio: servicio.equipoAnio,
			partesFallaron: servicio.partesFallaron,
			km: servicio.km,
			sintoma: servicio.sintoma,
			diagnosticoDetalle: servicio.diagnosticoDetalle,
			diagnosticoCatIds: servicio.diagnosticoCatIds,
			resolucionId: servicio.resolucionId,
			observaciones: servicio.observaciones,
			productoIds: servicio.productoIds,
			productosFalla: servicio.productosFalla,
			facturacion: servicio.facturacion,
			facturacionItems: servicio.facturacionItems,
			documento: servicio.documento,
			tecnicoId: servicio.tecnicoId,
			fecha: servicio.fecha,
			resuelto: servicio.resuelto,
			aprobado: servicio.aprobado,
		);
	}

	static int _intDesdeDynamic(dynamic valor) {
		if (valor is int) {
			return valor;
		}
		if (valor is num) {
			return valor.toInt();
		}
		if (valor is String) {
			return int.tryParse(valor) ?? 0;
		}
		return 0;
	}

	static int? _intOpcionalDesdeDynamic(dynamic valor) {
		if (valor == null) {
			return null;
		}
		return _intDesdeDynamic(valor);
	}

	static double _doubleDesdeDynamic(dynamic valor) {
		if (valor is double) {
			return valor;
		}
		if (valor is int) {
			return valor.toDouble();
		}
		if (valor is num) {
			return valor.toDouble();
		}
		if (valor is String) {
			return double.tryParse(valor) ?? 0;
		}
		return 0;
	}

	static List<String> _listaString(dynamic valor) {
		if (valor is List) {
			return valor.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
		}
		if (valor == null) {
			return const [];
		}
		final texto = valor.toString().trim();
		if (texto.isEmpty) {
			return const [];
		}
		return [texto];
	}

	static Map<String, dynamic>? _mapaDesdeDynamic(dynamic valor) {
		if (valor is Map<String, dynamic>) {
			return valor;
		}
		return null;
	}

	static List<Map<String, dynamic>> _listaMapasDesdeDynamic(dynamic valor) {
		if (valor is List) {
			return valor.whereType<Map<String, dynamic>>().toList();
		}
		return const [];
	}

	List<Map<String, dynamic>> _productosFallaJsonParaEnvio() {
		if (productosFalla.isNotEmpty) {
			return productosFalla
					.map(
						(item) => {
							'parteFallo': item.parteFallo,
							'productoFallaId': item.productoFallaId,
						},
					)
					.toList();
		}

		if (productoIds.isEmpty) {
			return const [];
		}

		final parteDefault = partesFallaron.isNotEmpty ? partesFallaron.first : 'otro';
		return productoIds
				.map(
					(productoId) => {
						'parteFallo': parteDefault,
						'productoFallaId': productoId,
					},
				)
				.toList();
	}

	static String _primerValorListaOString(dynamic valor) {
		final lista = _listaString(valor);
		if (lista.isEmpty) {
			return '';
		}
		return lista.first;
	}

	static bool _aprobadoDesdeJson(Map<String, dynamic> json) {
		if (json.containsKey('aprobado')) {
			return _boolDesdeDynamic(json['aprobado']);
		}

		if (json.containsKey('aprobado_liquidacion')) {
			return _boolDesdeDynamic(json['aprobado_liquidacion']);
		}

		final liquidacion = json['liquidacion'];
		if (liquidacion is Map<String, dynamic>) {
			return _boolDesdeDynamic(liquidacion['aprobado']);
		}

		return false;
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

	static Canal _canalDesdeString(String valor) {
		return Canal.values.firstWhere(
			(canal) => canal.name == valor,
			orElse: () => Canal.campo,
		);
	}
}


