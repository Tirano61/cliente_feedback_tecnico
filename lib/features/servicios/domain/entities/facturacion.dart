import 'package:equatable/equatable.dart';

class Facturacion extends Equatable {
	final double cotizacionDolarSnapshot;
	final double valorKmUsdSnapshot;
	final double kmCantidad;
	final double subtotalKmUsd;
	final double subtotalKmArs;
	final double subtotalGeneralUsd;
	final double subtotalGeneralArs;
	final double ivaPorcentaje;
	final double totalConIvaArs;
	final double descuentoPorcentaje;
	final double totalFinalArs;
	final int version;

	const Facturacion({
		required this.cotizacionDolarSnapshot,
		required this.valorKmUsdSnapshot,
		required this.kmCantidad,
		required this.subtotalKmUsd,
		required this.subtotalKmArs,
		required this.subtotalGeneralUsd,
		required this.subtotalGeneralArs,
		required this.ivaPorcentaje,
		required this.totalConIvaArs,
		required this.descuentoPorcentaje,
		required this.totalFinalArs,
		this.version = 1,
	});

	@override
	List<Object> get props => [
				cotizacionDolarSnapshot,
				valorKmUsdSnapshot,
				kmCantidad,
				subtotalKmUsd,
				subtotalKmArs,
				subtotalGeneralUsd,
				subtotalGeneralArs,
				ivaPorcentaje,
				totalConIvaArs,
				descuentoPorcentaje,
				totalFinalArs,
				version,
			];
}
