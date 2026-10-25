import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:equatable/equatable.dart';

// Nombres para mostrar de las piezas y su historial.

String nombreEstadoUnidad(EstadoUnidad estado) {
	return switch (estado) {
		EstadoUnidad.instalada => 'Instalada',
		EstadoUnidad.retirada => 'Retirada',
		EstadoUnidad.enServicioTecnico => 'En servicio técnico',
		EstadoUnidad.enDesarrollo => 'En desarrollo',
		EstadoUnidad.reacondicionadaDisponible => 'Reacondicionada disponible',
		EstadoUnidad.descartada => 'Descartada',
		EstadoUnidad.desconocido => 'Sin dato',
	};
}

/// Un movimiento del historial, listo para leer.
class PasoHistorial extends Equatable {
	final TipoMovimiento tipo;
	final String titulo;
	final DateTime? fecha;

	/// Quien lo registro.
	final String? usuario;
	final String? observacion;

	const PasoHistorial({
		required this.tipo,
		required this.titulo,
		this.fecha,
		this.usuario,
		this.observacion,
	});

	@override
	List<Object?> get props => [tipo, titulo, fecha, usuario, observacion];
}

/// Los movimientos en el orden en que llegan (del mas viejo al mas nuevo).
List<PasoHistorial> pasosHistorial(TipoUnidad tipoUnidad, List<Movimiento> movimientos) {
	return movimientos.map((movimiento) {
		final usuario = (movimiento.usuario?.fullName ?? '').trim();
		final observacion = (movimiento.observacion ?? '').trim();
		return PasoHistorial(
			tipo: movimiento.tipo,
			titulo: tituloMovimiento(tipoUnidad, movimiento),
			fecha: movimiento.fecha,
			usuario: usuario.isEmpty ? null : usuario,
			observacion: observacion.isEmpty ? null : observacion,
		);
	}).toList();
}

String tituloMovimiento(TipoUnidad tipoUnidad, Movimiento movimiento) {
	final esIndicador = tipoUnidad == TipoUnidad.indicador;
	String segun(String pieza, String indicador) => esIndicador ? indicador : pieza;

	final serie = (movimiento.indicador?.nroSerie ?? '').trim();
	final enIndicador = serie.isEmpty ? 'en un indicador' : 'en el indicador $serie';
	final delIndicador = serie.isEmpty ? 'de un indicador' : 'del indicador $serie';
	// En fabrica la asignacion va con la recepcion; en campo, con el servicio.
	final donde = (movimiento.recepcionId ?? '').isNotEmpty
			? ' en fábrica'
			: (movimiento.servicioId ?? '').isNotEmpty
					? ' en un servicio'
					: '';

	return switch (movimiento.tipo) {
		TipoMovimiento.alta => segun(
				'${nombreTipoUnidad(tipoUnidad)} dada de alta',
				'Indicador dado de alta',
			),
		TipoMovimiento.instalacion => 'Puesta $enIndicador$donde',
		TipoMovimiento.retiro => 'Retirada $delIndicador$donde',
		TipoMovimiento.recepcion => segun(
				'Llegó a fábrica con el equipo del cliente',
				'Llegó a fábrica (recepción del equipo)',
			),
		TipoMovimiento.devolucionCliente => segun('Devuelta al cliente', 'Devuelto al cliente'),
		TipoMovimiento.ingresoFabrica => 'Ingresó a fábrica para revisión',
		TipoMovimiento.derivacionDesarrollo => 'Derivada a desarrollo',
		TipoMovimiento.reparada => 'Reparada',
		TipoMovimiento.descartada => 'Descartada por irreparable',
		TipoMovimiento.vueltaAServicioTecnico =>
			'Volvió a servicio técnico: reacondicionada disponible',
		TipoMovimiento.desconocido => 'Movimiento sin descripción',
	};
}
