import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:equatable/equatable.dart';

// Reglas de la recepcion que la pantalla necesita para decidir que mostrar.
// Las valida el backend; aca se calculan para no ofrecer lo que va a rechazar.

/// Cambios de estado que se piden con `PATCH .../estado`, por estado actual
/// (endpoints.md, "Recepcion"). `devuelto` no esta: solo se llega con la
/// devolucion.
const Map<EstadoRecepcion, List<EstadoRecepcion>> _transiciones = {
	EstadoRecepcion.recibido: [
		EstadoRecepcion.enReparacion,
		EstadoRecepcion.esperandoPresupuesto,
	],
	EstadoRecepcion.enReparacion: [
		EstadoRecepcion.esperandoPresupuesto,
		EstadoRecepcion.listoParaDevolver,
	],
	EstadoRecepcion.esperandoPresupuesto: [
		EstadoRecepcion.enReparacion,
		EstadoRecepcion.listoParaDevolver,
	],
	EstadoRecepcion.listoParaDevolver: [
		EstadoRecepcion.enReparacion,
	],
};

/// Un boton de cambio de estado del detalle.
class AccionEstadoRecepcion extends Equatable {
	final EstadoRecepcion destino;
	final String etiqueta;

	/// Por que todavia no se puede (null = se puede).
	final String? motivoBloqueo;

	const AccionEstadoRecepcion({
		required this.destino,
		required this.etiqueta,
		this.motivoBloqueo,
	});

	bool get habilitada => motivoBloqueo == null;

	@override
	List<Object?> get props => [destino, etiqueta, motivoBloqueo];
}

class ReglasRecepcion {
	const ReglasRecepcion._();

	static const String motivoFaltaServicio =
			'Falta vincular el servicio de fábrica de esta recepción.';

	/// Estados a los que se puede pasar desde el estado actual. Vacio en
	/// `devuelto` y en un estado que la app no conoce.
	static List<EstadoRecepcion> estadosPermitidos(EstadoRecepcion actual) {
		return _transiciones[actual] ?? const [];
	}

	static List<AccionEstadoRecepcion> acciones(Recepcion recepcion) {
		final tieneServicio = (recepcion.servicioId ?? '').trim().isNotEmpty;
		return [
			for (final destino in estadosPermitidos(recepcion.estado))
				AccionEstadoRecepcion(
					destino: destino,
					etiqueta: _etiqueta(recepcion.estado, destino),
					motivoBloqueo: destino == EstadoRecepcion.listoParaDevolver && !tieneServicio
							? motivoFaltaServicio
							: null,
				),
		];
	}

	/// La devolucion al cliente solo sale de `listo_para_devolver`.
	static bool puedeDevolver(Recepcion recepcion) {
		return recepcion.estado == EstadoRecepcion.listoParaDevolver;
	}

	/// Dias calendario (hora local) desde que llego el equipo hasta hoy, o
	/// hasta la devolucion si ya se devolvio. El dia que llega cuenta 0.
	static int? diasEnFabrica(Recepcion recepcion, DateTime ahora) {
		final desde = recepcion.fechaRecepcion;
		if (desde == null) {
			return null;
		}

		final hasta = recepcion.estado == EstadoRecepcion.devuelto
				? (recepcion.fechaDevolucion ?? ahora)
				: ahora;
		// Fechas en UTC a medianoche: un cambio de horario no corre el conteo.
		final dias = _dia(hasta).difference(_dia(desde)).inDays;
		return dias < 0 ? 0 : dias;
	}

	static DateTime _dia(DateTime fecha) {
		final local = fecha.toLocal();
		return DateTime.utc(local.year, local.month, local.day);
	}

	static String _etiqueta(EstadoRecepcion origen, EstadoRecepcion destino) {
		return switch ((origen, destino)) {
			(EstadoRecepcion.esperandoPresupuesto, EstadoRecepcion.enReparacion) =>
				'Aceptó el presupuesto',
			(EstadoRecepcion.esperandoPresupuesto, EstadoRecepcion.listoParaDevolver) =>
				'No aceptó el presupuesto',
			(EstadoRecepcion.listoParaDevolver, EstadoRecepcion.enReparacion) =>
				'Falló la prueba final',
			(_, EstadoRecepcion.enReparacion) => 'Pasar a reparación',
			(_, EstadoRecepcion.esperandoPresupuesto) => 'Esperando presupuesto',
			(_, EstadoRecepcion.listoParaDevolver) => 'Listo para devolver',
			_ => 'Cambiar estado',
		};
	}
}
