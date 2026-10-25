import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/servicio_vinculado.dart';
import 'package:equatable/equatable.dart';

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

/// Un cambio del historial de estados, listo para leer.
class PasoHistorialRecepcion extends Equatable {
	final EstadoRecepcion estado;
	final String titulo;
	final DateTime? fecha;
	final String? usuario;
	final String? observacion;

	const PasoHistorialRecepcion({
		required this.estado,
		required this.titulo,
		this.fecha,
		this.usuario,
		this.observacion,
	});

	@override
	List<Object?> get props => [estado, titulo, fecha, usuario, observacion];
}

/// Los cambios en el orden en que llegan (del mas viejo al mas nuevo). Lo que
/// decidio el cliente con el presupuesto sale del estado anterior: el backend
/// solo guarda a que estado se paso.
List<PasoHistorialRecepcion> pasosHistorialRecepcion(List<CambioEstadoRecepcion> historial) {
	return [
		for (var i = 0; i < historial.length; i++)
			PasoHistorialRecepcion(
				estado: historial[i].estado,
				titulo: tituloCambioEstadoRecepcion(
					i == 0 ? null : historial[i - 1].estado,
					historial[i].estado,
				),
				fecha: historial[i].fecha,
				usuario: _textoOpcional(historial[i].usuarioNombre),
				observacion: _textoOpcional(historial[i].observacion),
			),
	];
}

String tituloCambioEstadoRecepcion(EstadoRecepcion? anterior, EstadoRecepcion estado) {
	return switch ((anterior, estado)) {
		(EstadoRecepcion.esperandoPresupuesto, EstadoRecepcion.enReparacion) => 'Aceptó el presupuesto',
		(EstadoRecepcion.esperandoPresupuesto, EstadoRecepcion.listoParaDevolver) =>
			'No aceptó el presupuesto',
		_ => nombreEstadoRecepcion(estado),
	};
}

/// Titulo del servicio de fabrica vinculado: con la fecha del resumen, o
/// generico mientras no llega (o si el backend no lo deja ver).
String tituloServicioVinculado(ServicioVinculado? resumen) {
	final fecha = resumen?.fecha?.toLocal();
	if (fecha == null) {
		return 'Servicio de fábrica';
	}
	final dia = fecha.day.toString().padLeft(2, '0');
	final mes = fecha.month.toString().padLeft(2, '0');
	return 'Servicio de fábrica del $dia/$mes/${fecha.year}';
}

String? _textoOpcional(String? texto) {
	final limpio = (texto ?? '').trim();
	return limpio.isEmpty ? null : limpio;
}
