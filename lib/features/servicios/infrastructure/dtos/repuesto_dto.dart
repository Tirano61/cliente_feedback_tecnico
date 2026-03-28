import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';

class RepuestoDto {
	final String id;
	final String codigo;
	final String nombre;
	final double precioUsd;

	const RepuestoDto({
		required this.id,
		required this.codigo,
		required this.nombre,
		required this.precioUsd,
	});

	factory RepuestoDto.fromJson(Map<String, dynamic> json) {
		return RepuestoDto(
			id: json['id']?.toString() ?? json['repuestoId']?.toString() ?? '',
			codigo: json['codigo']?.toString() ?? json['code']?.toString() ?? '',
			nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
			precioUsd: _doubleDesdeDynamic(
				json['precioUsd'] ?? json['precio_usd'] ?? json['precio'] ?? json['priceUsd'],
			),
		);
	}

	Repuesto aEntidad() {
		return Repuesto(
			id: id,
			codigo: codigo,
			nombre: nombre,
			precioUsd: precioUsd,
		);
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
			return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
		}
		return 0;
	}
}
