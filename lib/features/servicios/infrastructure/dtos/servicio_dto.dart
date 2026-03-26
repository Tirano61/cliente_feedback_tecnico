import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';

class ServicioDto {
	final String id;
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

	final String tecnicoId;
	final DateTime? fecha;
	final bool resuelto;
	final bool aprobado;

	const ServicioDto({
		required this.id,
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
		this.tecnicoId = '',
		this.fecha,
		this.resuelto = true,
		this.aprobado = false,
	});

	factory ServicioDto.fromJson(Map<String, dynamic> json) {
		final productoIds = _listaString(
			json['productoIds'] ?? json['producto_ids'] ?? json['producto_id'],
		);

		return ServicioDto(
			id: json['id']?.toString() ?? '',
			canal: _canalDesdeString(json['canal']?.toString() ?? 'campo'),
			clienteId:
					json['clienteId']?.toString() ??
					json['cliente_id']?.toString() ??
					'',
			lugarProvinciaId:
					json['lugarProvinciaId']?.toString() ??
					json['lugar_provincia_id']?.toString() ??
					json['zona_id']?.toString() ??
					'',
			lugarDetalle:
					json['lugarDetalle']?.toString() ??
					json['lugar_detalle']?.toString() ??
					'',
			equipoNroSerie:
					json['equipoNroSerie']?.toString() ??
					json['equipo_nro_serie']?.toString() ??
					'',
			equipoModelo:
					json['equipoModelo']?.toString() ??
					json['equipo_modelo']?.toString() ??
					'',
			equipoUbicacion:
					json['equipoUbicacion']?.toString() ??
					json['equipo_ubicacion']?.toString() ??
					'',
			equipoAnio: _intDesdeDynamic(json['equipoAnio'] ?? json['equipo_anio']),
			partesFallaron:
					_listaString(json['partesFallaron'] ?? json['partes_fallaron']),
			km: _intDesdeDynamic(json['km']),
			sintoma: json['sintoma']?.toString() ?? '',
			diagnosticoDetalle:
					json['diagnosticoDetalle']?.toString() ??
					json['diagnostico_detalle']?.toString() ??
					'',
			diagnosticoCatIds: _listaString(
				json['diagnosticoCatId'] ?? json['diagnostico_cat_id'],
			),
			resolucionId: _primerValorListaOString(
				json['resolucionId'] ?? json['resolucion_id'],
			),
			observaciones: json['observaciones']?.toString(),
			productoIds: productoIds,
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
			'productoIds': productoIds,
		};

		final observacionesNormalizadas = observaciones?.trim();
		if (observacionesNormalizadas != null && observacionesNormalizadas.isNotEmpty) {
			body['observaciones'] = observacionesNormalizadas;
		}

		return body;
	}

	Servicio aEntidad() {
		return Servicio(
			id: id,
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
			tecnicoId: tecnicoId,
			fecha: fecha,
			resuelto: resuelto,
			aprobado: aprobado,
		);
	}

	factory ServicioDto.desdeEntidad(Servicio servicio) {
		return ServicioDto(
			id: servicio.id,
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


