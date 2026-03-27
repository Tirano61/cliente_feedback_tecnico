import 'package:equatable/equatable.dart';

class FacturacionItem extends Equatable {
	final String tipoItem;
	final String? referenciaId;
	final String descripcion;
	final double cantidad;
	final double precioUnitarioUsd;
	final double precioUnitarioArs;
	final double subtotalUsd;
	final double subtotalArs;

	const FacturacionItem({
		required this.tipoItem,
		this.referenciaId,
		required this.descripcion,
		required this.cantidad,
		required this.precioUnitarioUsd,
		required this.precioUnitarioArs,
		required this.subtotalUsd,
		required this.subtotalArs,
	});

	@override
	List<Object?> get props => [
				tipoItem,
				referenciaId,
				descripcion,
				cantidad,
				precioUnitarioUsd,
				precioUnitarioArs,
				subtotalUsd,
				subtotalArs,
			];
}
