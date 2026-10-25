import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/servicio_vinculado.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/precarga_formulario_servicio.dart';
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

	/// Servicio de fabrica ya guardado que todavia no quedo vinculado a la
	/// recepcion. Mientras este, no se ofrece cargar otro.
	final String? servicioPorVincular;
	final bool vinculando;

	/// Por que fallo la ultima vinculacion (queda a la vista con "Reintentar").
	final String? errorVinculacion;

	/// Resumen del servicio vinculado (`GET /servicios/:id`).
	final ServicioVinculado? servicioVinculado;
	final bool cargandoServicioVinculado;

	/// El backend no deja ver el servicio (403: es de otro tecnico) o ya no
	/// existe (404): se muestra solo el id, sin error.
	final bool servicioVinculadoNoDisponible;

	/// Cualquier otro error al traer el resumen (queda con "Reintentar").
	final String? errorServicioVinculado;

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
		this.servicioPorVincular,
		this.vinculando = false,
		this.errorVinculacion,
		this.servicioVinculado,
		this.cargandoServicioVinculado = false,
		this.servicioVinculadoNoDisponible = false,
		this.errorServicioVinculado,
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

	/// Servicio vinculado a la recepcion, o null si todavia no tiene.
	String? get servicioVinculadoId {
		final actual = recepcion;
		return actual == null || !ReglasRecepcion.tieneServicio(actual)
				? null
				: actual.servicioId!.trim();
	}

	/// "Cargar servicio de fabrica": sin servicio vinculado ni uno guardado
	/// esperando la vinculacion (no se crea un segundo servicio).
	bool get puedeCargarServicio {
		final actual = recepcion;
		return actual != null &&
				servicioPorVincular == null &&
				ReglasRecepcion.admiteServicio(actual);
	}

	bool get puedeReintentarVinculacion => servicioPorVincular != null && !vinculando;

	/// El resumen, solo si es del servicio que hoy figura vinculado.
	ServicioVinculado? get resumenServicioVinculado {
		final resumen = servicioVinculado;
		return resumen != null && resumen.id == servicioVinculadoId ? resumen : null;
	}

	/// "Ingresar pieza retirada": mientras el equipo siga en fabrica.
	bool get puedeIngresarPieza {
		final actual = recepcion;
		return actual != null && ReglasRecepcion.admiteIngresos(actual);
	}

	/// Con que arranca el ingreso de una pieza retirada: la recepcion y las
	/// piezas que figuran en el indicador.
	PrecargaIngresoRecepcion? get precargaIngreso {
		final actual = recepcion;
		if (actual == null) {
			return null;
		}
		return PrecargaIngresoRecepcion(
			recepcionId: actual.id,
			numero: actual.numero,
			clienteNombre: actual.cliente.nombre,
			indicadorNroSerie: actual.indicador.nroSerie,
			piezasInstaladas: actual.piezasInstaladas,
		);
	}

	/// Con que arranca el formulario de servicio: canal fabrica fijo, el
	/// cliente, el indicador y lo que reporto el cliente.
	PrecargaFormularioServicio? get precargaServicio {
		final actual = recepcion;
		if (actual == null) {
			return null;
		}
		final producto = actual.indicador.producto;
		return PrecargaFormularioServicio(
			canal: Canal.fabrica,
			cliente: Cliente(
				id: actual.cliente.id,
				nombre: actual.cliente.nombre,
				cuit: actual.cliente.cuit,
			),
			equipoNroSerie: actual.indicador.nroSerie,
			equipoModelo: producto?.nombre ?? '',
			equipoModeloProductoId: producto?.id,
			sintoma: actual.sintomaReportado,
		);
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
		String? servicioPorVincular,
		bool limpiarServicioPorVincular = false,
		bool? vinculando,
		String? errorVinculacion,
		bool limpiarErrorVinculacion = false,
		ServicioVinculado? servicioVinculado,
		bool? cargandoServicioVinculado,
		bool? servicioVinculadoNoDisponible,
		String? errorServicioVinculado,
		bool limpiarErrorServicioVinculado = false,
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
			servicioPorVincular: limpiarServicioPorVincular
					? null
					: (servicioPorVincular ?? this.servicioPorVincular),
			vinculando: vinculando ?? this.vinculando,
			errorVinculacion:
					limpiarErrorVinculacion ? null : (errorVinculacion ?? this.errorVinculacion),
			servicioVinculado: servicioVinculado ?? this.servicioVinculado,
			cargandoServicioVinculado: cargandoServicioVinculado ?? this.cargandoServicioVinculado,
			servicioVinculadoNoDisponible:
					servicioVinculadoNoDisponible ?? this.servicioVinculadoNoDisponible,
			errorServicioVinculado: limpiarErrorServicioVinculado
					? null
					: (errorServicioVinculado ?? this.errorServicioVinculado),
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
				servicioPorVincular,
				vinculando,
				errorVinculacion,
				servicioVinculado,
				cargandoServicioVinculado,
				servicioVinculadoNoDisponible,
				errorServicioVinculado,
				exitoMensaje,
				errorMensaje,
				fechaReferencia,
			];
}
