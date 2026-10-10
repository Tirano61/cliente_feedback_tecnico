import 'package:equatable/equatable.dart';

/// Codigos con los que el backend rechaza (409) una orden porque los valores
/// con los que se le mostro el total al cliente ya no son los vigentes.
///
/// El backend nunca corrige precios: si algo no coincide rechaza la orden
/// entera y no consume la idempotencyKey, asi que la misma orden se puede
/// volver a guardar despues de revisar el total con el cliente.
class CodigoRechazoValores {
	const CodigoRechazoValores._();

	static const String cotizacionInvalida = 'COTIZACION_INVALIDA';
	static const String tarifaKmInvalida = 'TARIFA_KM_INVALIDA';
	static const String repuestoInexistente = 'REPUESTO_INEXISTENTE';
	static const String repuestoInactivo = 'REPUESTO_INACTIVO';
	static const String precioRepuestoDesactualizado = 'PRECIO_REPUESTO_DESACTUALIZADO';

	static const Set<String> todos = {
		cotizacionInvalida,
		tarifaKmInvalida,
		repuestoInexistente,
		repuestoInactivo,
		precioRepuestoDesactualizado,
	};
}

/// Un valor puntual de la orden que el backend no acepto.
///
/// - Cotizacion / tarifa km: `campo` es `cotizacionDolarSnapshot` o
///   `valorKmUsdSnapshot`.
/// - Repuestos: `repuestoId` y `descripcion` identifican la linea;
///   `valorVigente` es null si el repuesto no existe.
class ValorRechazado extends Equatable {
	final String codigo;
	final String? campo;
	final String? repuestoId;
	final String? descripcion;
	final double? valorEnviado;
	final double? valorVigente;

	const ValorRechazado({
		required this.codigo,
		this.campo,
		this.repuestoId,
		this.descripcion,
		this.valorEnviado,
		this.valorVigente,
	});

	@override
	List<Object?> get props => [
				codigo,
				campo,
				repuestoId,
				descripcion,
				valorEnviado,
				valorVigente,
			];
}

/// La orden no se guardo porque la cotizacion, el valor del km o el precio de
/// algun repuesto cambio (o el repuesto ya no esta en el catalogo).
class ValoresOrdenRechazadosException implements Exception {
	final String codigo;
	final String mensaje;
	final List<ValorRechazado> items;

	const ValoresOrdenRechazadosException({
		required this.codigo,
		required this.mensaje,
		required this.items,
	});

	@override
	String toString() => 'ValoresOrdenRechazadosException($codigo): $mensaje';
}
