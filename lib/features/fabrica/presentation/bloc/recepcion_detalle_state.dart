import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:equatable/equatable.dart';

class RecepcionDetalleState extends Equatable {
	final String? recepcionId;
	final Recepcion? recepcion;
	final bool cargando;

	/// La recepcion no se pudo cargar y no hay nada que mostrar.
	final String? errorCarga;

	/// Cambio de estado en curso (el boton muestra que esta trabajando).
	final EstadoRecepcion? estadoEnCurso;
	final bool devolviendo;

	/// Por que se rechazo la ultima accion, tal cual (lo muestra el dialogo,
	/// que queda abierto con lo que el tecnico escribio).
	final String? errorAccion;

	/// Mensajes de un solo uso para el snackbar.
	final String? exitoMensaje;
	final String? errorMensaje;

	/// "Hoy" de la ultima carga, para contar los dias en fabrica.
	final DateTime? fechaReferencia;

	const RecepcionDetalleState({
		this.recepcionId,
		this.recepcion,
		this.cargando = false,
		this.errorCarga,
		this.estadoEnCurso,
		this.devolviendo = false,
		this.errorAccion,
		this.exitoMensaje,
		this.errorMensaje,
		this.fechaReferencia,
	});

	bool get procesandoAccion => estadoEnCurso != null || devolviendo;

	/// Botones de cambio de estado: solo los permitidos desde el estado actual.
	List<AccionEstadoRecepcion> get accionesEstado {
		final actual = recepcion;
		return actual == null ? const [] : ReglasRecepcion.acciones(actual);
	}

	bool get puedeDevolver {
		final actual = recepcion;
		return actual != null && ReglasRecepcion.puedeDevolver(actual);
	}

	int? get diasEnFabrica {
		final actual = recepcion;
		final referencia = fechaReferencia;
		if (actual == null || referencia == null) {
			return null;
		}
		return ReglasRecepcion.diasEnFabrica(actual, referencia);
	}

	/// `exitoMensaje` y `errorMensaje` no se arrastran: valen para un emit.
	RecepcionDetalleState copyWith({
		Recepcion? recepcion,
		bool? cargando,
		String? errorCarga,
		bool limpiarErrorCarga = false,
		EstadoRecepcion? estadoEnCurso,
		bool limpiarEstadoEnCurso = false,
		bool? devolviendo,
		String? errorAccion,
		bool limpiarErrorAccion = false,
		String? exitoMensaje,
		String? errorMensaje,
		DateTime? fechaReferencia,
	}) {
		return RecepcionDetalleState(
			recepcionId: recepcionId,
			recepcion: recepcion ?? this.recepcion,
			cargando: cargando ?? this.cargando,
			errorCarga: limpiarErrorCarga ? null : (errorCarga ?? this.errorCarga),
			estadoEnCurso: limpiarEstadoEnCurso ? null : (estadoEnCurso ?? this.estadoEnCurso),
			devolviendo: devolviendo ?? this.devolviendo,
			errorAccion: limpiarErrorAccion ? null : (errorAccion ?? this.errorAccion),
			exitoMensaje: exitoMensaje,
			errorMensaje: errorMensaje,
			fechaReferencia: fechaReferencia ?? this.fechaReferencia,
		);
	}

	@override
	List<Object?> get props => [
				recepcionId,
				recepcion,
				cargando,
				errorCarga,
				estadoEnCurso,
				devolviendo,
				errorAccion,
				exitoMensaje,
				errorMensaje,
				fechaReferencia,
			];
}
