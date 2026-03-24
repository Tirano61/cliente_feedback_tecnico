import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';

class ServicioDto {
	final String id;
	final String tecnicoId;
	final String productoId;
	final String zonaId;
	final Canal canal;
	final DateTime fecha;
	final String sintoma;
	final String diagnosticoCatId;
	final String diagnosticoDetalle;
	final String resolucionId;
	final bool resuelto;
	final bool aprobado;
	final String? observaciones;

	const ServicioDto({
		required this.id,
		required this.tecnicoId,
		required this.productoId,
		required this.zonaId,
		required this.canal,
		required this.fecha,
		required this.sintoma,
		required this.diagnosticoCatId,
		required this.diagnosticoDetalle,
		required this.resolucionId,
		required this.resuelto,
		required this.aprobado,
		this.observaciones,
	});

	factory ServicioDto.fromJson(Map<String, dynamic> json) {
		return ServicioDto(
			id: json['id']?.toString() ?? '',
			tecnicoId: json['tecnico_id']?.toString() ?? '',
			productoId: json['producto_id']?.toString() ?? '',
			zonaId: json['zona_id']?.toString() ?? '',
			canal: _canalDesdeString(json['canal']?.toString() ?? 'campo'),
			fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
			sintoma: json['sintoma']?.toString() ?? '',
			diagnosticoCatId: json['diagnostico_cat_id']?.toString() ?? '',
			diagnosticoDetalle: json['diagnostico_detalle']?.toString() ?? '',
			resolucionId: json['resolucion_id']?.toString() ?? '',
			resuelto: json['resuelto'] == true,
			aprobado: _aprobadoDesdeJson(json),
			observaciones: json['observaciones']?.toString(),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'tecnico_id': tecnicoId,
			'producto_id': productoId,
			'zona_id': zonaId,
			'canal': canal.name,
			'fecha': fecha.toIso8601String(),
			'sintoma': sintoma,
			'diagnostico_cat_id': diagnosticoCatId,
			'diagnostico_detalle': diagnosticoDetalle,
			'resolucion_id': resolucionId,
			'resuelto': resuelto,
			'aprobado': aprobado,
			'observaciones': observaciones,
		};
	}

	Servicio aEntidad() {
		return Servicio(
			id: id,
			tecnicoId: tecnicoId,
			productoId: productoId,
			zonaId: zonaId,
			canal: canal,
			fecha: fecha,
			sintoma: sintoma,
			diagnosticoCatId: diagnosticoCatId,
			diagnosticoDetalle: diagnosticoDetalle,
			resolucionId: resolucionId,
			resuelto: resuelto,
			aprobado: aprobado,
			observaciones: observaciones,
		);
	}

	factory ServicioDto.desdeEntidad(Servicio servicio) {
		return ServicioDto(
			id: servicio.id,
			tecnicoId: servicio.tecnicoId,
			productoId: servicio.productoId,
			zonaId: servicio.zonaId,
			canal: servicio.canal,
			fecha: servicio.fecha,
			sintoma: servicio.sintoma,
			diagnosticoCatId: servicio.diagnosticoCatId,
			diagnosticoDetalle: servicio.diagnosticoDetalle,
			resolucionId: servicio.resolucionId,
			resuelto: servicio.resuelto,
			aprobado: servicio.aprobado,
			observaciones: servicio.observaciones,
		);
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


