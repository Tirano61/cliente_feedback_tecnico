import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';

// Nombres para mostrar de los valores de la recepcion.

String nombreEstadoRecepcion(EstadoRecepcion estado) {
	return switch (estado) {
		EstadoRecepcion.recibido => 'Recibido',
		EstadoRecepcion.enReparacion => 'En reparación',
		EstadoRecepcion.esperandoPresupuesto => 'Esperando presupuesto',
		EstadoRecepcion.listoParaDevolver => 'Listo para devolver',
		EstadoRecepcion.devuelto => 'Devuelto',
		EstadoRecepcion.desconocido => 'Sin dato',
	};
}

String textoDiasEnFabrica(int? dias) {
	return switch (dias) {
		null => 'Sin fecha de recepción',
		0 => 'Llegó hoy',
		1 => '1 día en fábrica',
		_ => '$dias días en fábrica',
	};
}

String nombreFormaDevolucion(FormaDevolucion forma) {
	return switch (forma) {
		FormaDevolucion.envio => 'Envío',
		FormaDevolucion.retiraCliente => 'Retira el cliente',
		FormaDevolucion.llevaTecnico => 'Lo lleva un técnico',
	};
}
