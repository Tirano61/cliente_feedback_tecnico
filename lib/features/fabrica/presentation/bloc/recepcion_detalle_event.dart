import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:equatable/equatable.dart';

abstract class RecepcionDetalleEvent extends Equatable {
	const RecepcionDetalleEvent();

	@override
	List<Object?> get props => [];
}

/// Abre el detalle. Con `recepcion` (la respuesta del alta) se muestra sin
/// volver a pedirla.
class RecepcionDetalleAbierto extends RecepcionDetalleEvent {
	final String recepcionId;
	final Recepcion? recepcion;

	const RecepcionDetalleAbierto({required this.recepcionId, this.recepcion});

	@override
	List<Object?> get props => [recepcionId, recepcion];
}

class RecepcionDetalleRefrescado extends RecepcionDetalleEvent {
	const RecepcionDetalleRefrescado();
}

class RecepcionEstadoCambioSolicitado extends RecepcionDetalleEvent {
	final EstadoRecepcion estado;
	final String observacion;

	const RecepcionEstadoCambioSolicitado({
		required this.estado,
		this.observacion = '',
	});

	@override
	List<Object?> get props => [estado, observacion];
}

/// `forma` null: el tecnico todavia no eligio (lo rechaza el BLoC).
class RecepcionDevolucionSolicitada extends RecepcionDetalleEvent {
	final FormaDevolucion? forma;
	final String observacion;

	const RecepcionDevolucionSolicitada({
		required this.forma,
		this.observacion = '',
	});

	@override
	List<Object?> get props => [forma, observacion];
}

/// Se guardo el servicio de fabrica de la recepcion (`POST /servicios`): hay
/// que vincularlo. El servicio ya existe, asi que si la vinculacion falla se
/// reintenta con este mismo `servicioId`, nunca creando otro.
class RecepcionServicioGuardado extends RecepcionDetalleEvent {
	final String recepcionId;
	final String servicioId;

	const RecepcionServicioGuardado({
		required this.recepcionId,
		required this.servicioId,
	});

	@override
	List<Object?> get props => [recepcionId, servicioId];
}

/// Vuelve a pedir la vinculacion del servicio que quedo sin vincular.
class RecepcionVinculacionReintentada extends RecepcionDetalleEvent {
	const RecepcionVinculacionReintentada();
}

/// Al abrir el dialogo de una accion: el error de un intento anterior ya no
/// corresponde.
class RecepcionErrorAccionDescartado extends RecepcionDetalleEvent {
	const RecepcionErrorAccionDescartado();
}

/// Resumen del servicio vinculado (`GET /servicios/:id`). Lo pide el BLoC al
/// ver un servicio vinculado; tambien "Reintentar" si fallo.
class RecepcionServicioVinculadoSolicitado extends RecepcionDetalleEvent {
	const RecepcionServicioVinculadoSolicitado();
}

/// Generar el PDF de la orden del servicio vinculado para compartirlo.
class RecepcionPdfServicioSolicitado extends RecepcionDetalleEvent {
	const RecepcionPdfServicioSolicitado();
}
