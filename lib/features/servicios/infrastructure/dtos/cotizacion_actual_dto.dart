import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cotizacion_actual.dart';

class CotizacionActualDto {
	final double cotizacionDolar;
	final double valorKmUsd;

	const CotizacionActualDto({
		required this.cotizacionDolar,
		required this.valorKmUsd,
	});

	factory CotizacionActualDto.fromJson(Map<String, dynamic> json) {
		final cotizacionMap = _mapaDesdeDynamic(json['cotizacion']);
		return CotizacionActualDto(
			cotizacionDolar: _doubleDesdeDynamic(
				json['cotizacionDolar'] ??
						json['cotizacion_dolar'] ??
						json['dolar'] ??
						json['valor'] ??
						cotizacionMap?['valor'] ??
						cotizacionMap?['cotizacionDolar'] ??
						cotizacionMap?['dolar'] ??
						json['cotizacion'] ??
						json['valorDolar'],
			),
			valorKmUsd: _doubleDesdeDynamic(
				json['valorKmUsd'] ??
						json['valor_km_usd'] ??
						json['valorKm'] ??
						json['precioKmUsd'],
			),
		);
	}

	CotizacionActual aEntidad() {
		return CotizacionActual(
			cotizacionDolar: cotizacionDolar,
			valorKmUsd: valorKmUsd,
		);
	}

	static Map<String, dynamic>? _mapaDesdeDynamic(dynamic valor) {
		if (valor is Map<String, dynamic>) {
			return valor;
		}
		return null;
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
