import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:equatable/equatable.dart';

// Reglas del ingreso que la pantalla necesita para decidir que ofrecer. Las
// valida el backend (endpoints.md, "Ingreso"); aca se calculan para no
// mostrar lo que va a rechazar.
//
// placa: en_servicio_tecnico -> derivado_desarrollo -> reparado | descartado
//        reparado -> devuelto_a_servicio_tecnico
// celda: en_servicio_tecnico -> reparado | descartado
//
// La falla y la reparacion de las placas las carga desarrollo, no esta app.

enum AccionIngreso { derivar, cargarFalla, cargarReparacion, recibirDeDesarrollo }

/// Un boton de accion del detalle del ingreso.
class AccionIngresoDisponible extends Equatable {
	final AccionIngreso accion;
	final String etiqueta;

	/// Por que todavia no se puede (null = se puede).
	final String? motivoBloqueo;

	const AccionIngresoDisponible({
		required this.accion,
		required this.etiqueta,
		this.motivoBloqueo,
	});

	bool get habilitada => motivoBloqueo == null;

	@override
	List<Object?> get props => [accion, etiqueta, motivoBloqueo];
}

class ReglasIngreso {
	const ReglasIngreso._();

	static const String motivoFaltaFalla = 'Primero cargá la falla de la celda.';

	static const List<EstadoIngreso> _estadosPlaca = [
		EstadoIngreso.enServicioTecnico,
		EstadoIngreso.derivadoDesarrollo,
		EstadoIngreso.reparado,
		EstadoIngreso.descartado,
		EstadoIngreso.devueltoAServicioTecnico,
	];

	static const List<EstadoIngreso> _estadosCelda = [
		EstadoIngreso.enServicioTecnico,
		EstadoIngreso.reparado,
		EstadoIngreso.descartado,
	];

	/// Estados que puede tener un ingreso del tipo (null: placas y celdas).
	static List<EstadoIngreso> estadosPosibles(TipoUnidad? tipo) {
		return tipo == TipoUnidad.celda ? _estadosCelda : _estadosPlaca;
	}

	static List<AccionIngresoDisponible> acciones(Ingreso ingreso) {
		final estado = ingreso.estado;
		return switch (ingreso.unidad.tipo) {
			TipoUnidad.placa => [
					if (estado == EstadoIngreso.enServicioTecnico)
						const AccionIngresoDisponible(
							accion: AccionIngreso.derivar,
							etiqueta: 'Derivar a desarrollo',
						),
					if (estado == EstadoIngreso.reparado)
						const AccionIngresoDisponible(
							accion: AccionIngreso.recibirDeDesarrollo,
							etiqueta: 'Recibir de desarrollo',
						),
				],
			// La falla se puede corregir mientras no se cargo la reparacion.
			TipoUnidad.celda when estado == EstadoIngreso.enServicioTecnico && ingreso.reparacion == null => [
					AccionIngresoDisponible(
						accion: AccionIngreso.cargarFalla,
						etiqueta: ingreso.falla == null ? 'Cargar falla' : 'Corregir falla',
					),
					AccionIngresoDisponible(
						accion: AccionIngreso.cargarReparacion,
						etiqueta: 'Cargar reparación',
						motivoBloqueo: ingreso.falla == null ? motivoFaltaFalla : null,
					),
				],
			_ => const [],
		};
	}

	/// Que pasa con la pieza ahora, cuando no hay nada para hacer desde esta app.
	static String? aviso(Ingreso ingreso) {
		final esPlaca = ingreso.unidad.tipo == TipoUnidad.placa;
		return switch (ingreso.estado) {
			EstadoIngreso.derivadoDesarrollo =>
				'Está en desarrollo: la falla y la reparación las carga desarrollo.',
			EstadoIngreso.reparado when esPlaca =>
				'Desarrollo la reparó: falta recibirla en servicio técnico.',
			EstadoIngreso.reparado || EstadoIngreso.devueltoAServicioTecnico =>
				'Quedó reacondicionada, disponible para recambio.',
			EstadoIngreso.descartado => 'Irreparable: la pieza quedó descartada.',
			_ => null,
		};
	}
}
