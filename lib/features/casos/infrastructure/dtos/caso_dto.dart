import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';

class CasoDto {
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
	final String? observaciones;

	const CasoDto({
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
		this.observaciones,
	});

	factory CasoDto.fromJson(Map<String, dynamic> json) {
		return CasoDto(
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
			'observaciones': observaciones,
		};
	}

	Caso aEntidad() {
		return Caso(
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
			observaciones: observaciones,
		);
	}

	factory CasoDto.desdeEntidad(Caso caso) {
		return CasoDto(
			id: caso.id,
			tecnicoId: caso.tecnicoId,
			productoId: caso.productoId,
			zonaId: caso.zonaId,
			canal: caso.canal,
			fecha: caso.fecha,
			sintoma: caso.sintoma,
			diagnosticoCatId: caso.diagnosticoCatId,
			diagnosticoDetalle: caso.diagnosticoDetalle,
			resolucionId: caso.resolucionId,
			resuelto: caso.resuelto,
			observaciones: caso.observaciones,
		);
	}

	static Canal _canalDesdeString(String valor) {
		return Canal.values.firstWhere(
			(canal) => canal.name == valor,
			orElse: () => Canal.campo,
		);
	}
}
