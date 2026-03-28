import 'package:equatable/equatable.dart';

class CotizacionActual extends Equatable {
	final double cotizacionDolar;
	final double valorKmUsd;

	const CotizacionActual({
		required this.cotizacionDolar,
		required this.valorKmUsd,
	});

	@override
	List<Object> get props => [cotizacionDolar, valorKmUsd];
}
