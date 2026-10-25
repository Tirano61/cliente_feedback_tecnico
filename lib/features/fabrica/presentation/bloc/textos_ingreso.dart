import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';

// Nombres para mostrar de los valores de piezas e ingresos.

String nombreTipoUnidad(TipoUnidad tipo) {
	return switch (tipo) {
		TipoUnidad.indicador => 'Indicador',
		TipoUnidad.placa => 'Placa',
		TipoUnidad.celda => 'Celda',
		TipoUnidad.desconocido => 'Pieza',
	};
}

String nombreEstadoIngreso(EstadoIngreso estado) {
	return switch (estado) {
		EstadoIngreso.enServicioTecnico => 'En servicio técnico',
		EstadoIngreso.derivadoDesarrollo => 'Derivada a desarrollo',
		EstadoIngreso.reparado => 'Reparada',
		EstadoIngreso.descartado => 'Descartada',
		EstadoIngreso.devueltoAServicioTecnico => 'Volvió a servicio técnico',
		EstadoIngreso.desconocido => 'Sin dato',
	};
}

String nombreResultadoReparacion(ResultadoReparacion resultado) {
	return switch (resultado) {
		ResultadoReparacion.reparada => 'Reparada',
		ResultadoReparacion.irreparable => 'Irreparable',
		ResultadoReparacion.desconocido => 'Sin dato',
	};
}
