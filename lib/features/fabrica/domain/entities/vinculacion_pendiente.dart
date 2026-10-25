import 'package:equatable/equatable.dart';

/// Servicio de fabrica ya guardado (`POST /servicios`) que todavia no quedo
/// vinculado a su recepcion. Se guarda en el dispositivo para reintentar la
/// vinculacion aunque se cierre la app, sin crear otro servicio.
class VinculacionPendiente extends Equatable {
	final String recepcionId;
	final String servicioId;

	const VinculacionPendiente({
		required this.recepcionId,
		required this.servicioId,
	});

	@override
	List<Object?> get props => [recepcionId, servicioId];
}
