import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:equatable/equatable.dart';

/// Cambio de placa o celda de un servicio de campo ya guardado
/// (`POST /servicios`) que todavia no quedo registrado con
/// `POST /fabrica/unidades/asignaciones`. Se guarda en el dispositivo para
/// reintentarlo aunque se cierre la app, sin crear otro servicio.
class AsignacionPendiente extends Equatable {
	/// El body que se manda, con el `servicioId` del servicio guardado.
	final SolicitudAsignacion solicitud;

	/// Por que fallo el ultimo intento (el `mensaje` del backend, tal cual).
	/// Null mientras no se intento.
	final String? mensajeError;

	const AsignacionPendiente({required this.solicitud, this.mensajeError});

	String get servicioId => solicitud.servicioId ?? '';

	/// Identifica el cambio: una misma pieza no se pone dos veces en el mismo
	/// servicio. El backend guarda los numeros de serie sin espacios en los
	/// extremos y en mayusculas.
	String get clave =>
			'$servicioId|${solicitud.tipo.name}|${solicitud.nroSerie.trim().toUpperCase()}';

	AsignacionPendiente conError(String? mensaje) {
		return AsignacionPendiente(solicitud: solicitud, mensajeError: mensaje);
	}

	@override
	List<Object?> get props => [solicitud, mensajeError];
}
