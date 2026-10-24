import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cambiar_estado_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/devolver_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/vincular_servicio_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_recepcion.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecepcionDetalleBloc extends Bloc<RecepcionDetalleEvent, RecepcionDetalleState> {
	/// Rechazos que indican que la recepcion cambio por otro lado: se vuelve a
	/// pedir para que los botones muestren lo que corresponde ahora.
	static const Set<String> _codigosRecepcionDesactualizada = {
		CodigoReglaFabrica.transicionInvalida,
		CodigoReglaFabrica.recepcionCerrada,
		CodigoReglaFabrica.servicioRequerido,
		CodigoReglaFabrica.servicioYaVinculado,
	};

	final ObtenerRecepcionUseCase _obtenerRecepcionUseCase;
	final CambiarEstadoRecepcionUseCase _cambiarEstadoRecepcionUseCase;
	final DevolverRecepcionUseCase _devolverRecepcionUseCase;
	final VincularServicioRecepcionUseCase _vincularServicioRecepcionUseCase;
	final DateTime Function() _ahora;

	/// Cada apertura deja sin efecto las respuestas de la recepcion anterior.
	int _secuencia = 0;

	/// Servicios ya guardados cuya vinculacion fallo, por recepcion. Sobreviven
	/// a cerrar el detalle: al volver a abrir esa recepcion se ofrece reintentar
	/// en lugar de cargar otro servicio.
	final Map<String, String> _serviciosPorVincular = {};

	RecepcionDetalleBloc(
		this._obtenerRecepcionUseCase,
		this._cambiarEstadoRecepcionUseCase,
		this._devolverRecepcionUseCase,
		this._vincularServicioRecepcionUseCase, {
		DateTime Function()? ahora,
	})  : _ahora = ahora ?? DateTime.now,
				super(const RecepcionDetalleState()) {
		on<RecepcionDetalleAbierto>(_onAbierto);
		on<RecepcionDetalleRefrescado>(_onRefrescado);
		on<RecepcionEstadoCambioSolicitado>(_onEstadoCambioSolicitado);
		on<RecepcionDevolucionSolicitada>(_onDevolucionSolicitada);
		on<RecepcionServicioGuardado>(_onServicioGuardado);
		on<RecepcionVinculacionReintentada>(_onVinculacionReintentada);
		on<RecepcionErrorAccionDescartado>(_onErrorAccionDescartado);
	}

	Future<void> _onAbierto(
		RecepcionDetalleAbierto event,
		Emitter<RecepcionDetalleState> emit,
	) async {
		final consulta = ++_secuencia;
		final inicial = event.recepcion;
		if (inicial != null) {
			emit(
				RecepcionDetalleState(
					recepcionId: event.recepcionId,
					recepcion: inicial,
					servicioPorVincular: _servicioPorVincular(inicial),
					fechaReferencia: _ahora(),
				),
			);
			return;
		}

		emit(
			RecepcionDetalleState(
				recepcionId: event.recepcionId,
				cargando: true,
				servicioPorVincular: _serviciosPorVincular[event.recepcionId],
			),
		);
		await _cargar(emit, consulta);
	}

	Future<void> _onRefrescado(
		RecepcionDetalleRefrescado event,
		Emitter<RecepcionDetalleState> emit,
	) async {
		if (state.recepcionId == null || state.cargando) {
			return;
		}
		emit(state.copyWith(cargando: true, limpiarErrorCarga: true));
		await _cargar(emit, _secuencia);
	}

	Future<void> _cargar(Emitter<RecepcionDetalleState> emit, int consulta) async {
		final recepcionId = state.recepcionId;
		if (recepcionId == null) {
			return;
		}

		String? error;
		try {
			final recepcion = await _obtenerRecepcionUseCase.ejecutar(recepcionId);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			final porVincular = _servicioPorVincular(recepcion);
			emit(
				state.copyWith(
					recepcion: recepcion,
					cargando: false,
					limpiarErrorCarga: true,
					servicioPorVincular: porVincular,
					limpiarServicioPorVincular: porVincular == null,
					limpiarErrorVinculacion: porVincular == null,
					fechaReferencia: _ahora(),
				),
			);
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudo cargar la recepción.';
		}

		if (consulta != _secuencia || emit.isDone) {
			return;
		}
		// Con la recepcion a la vista, el error de un refresco va al snackbar.
		emit(
			state.recepcion == null
					? state.copyWith(cargando: false, errorCarga: error)
					: state.copyWith(cargando: false, errorMensaje: error),
		);
	}

	Future<void> _onEstadoCambioSolicitado(
		RecepcionEstadoCambioSolicitado event,
		Emitter<RecepcionDetalleState> emit,
	) async {
		final recepcion = state.recepcion;
		if (recepcion == null || state.procesandoAccion) {
			return;
		}

		final accion = state.accionesEstado
				.where((a) => a.destino == event.estado)
				.firstOrNull;
		if (accion == null) {
			emit(
				state.copyWith(
					errorAccion: 'Una recepción en "${nombreEstadoRecepcion(recepcion.estado)}" '
							'no puede pasar a "${nombreEstadoRecepcion(event.estado)}".',
				),
			);
			return;
		}
		if (!accion.habilitada) {
			emit(state.copyWith(errorAccion: accion.motivoBloqueo));
			return;
		}

		final consulta = _secuencia;
		emit(state.copyWith(estadoEnCurso: event.estado, limpiarErrorAccion: true));

		try {
			final actualizada = await _cambiarEstadoRecepcionUseCase.ejecutar(
				recepcionId: recepcion.id,
				estado: event.estado,
				observacion: _textoOpcional(event.observacion),
			);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			emit(
				state.copyWith(
					recepcion: actualizada,
					limpiarEstadoEnCurso: true,
					exitoMensaje: 'Estado actualizado: ${nombreEstadoRecepcion(actualizada.estado)}.',
					fechaReferencia: _ahora(),
				),
			);
		} on ServerException catch (e) {
			_cerrarAccionConError(emit, consulta, e);
		} catch (_) {
			_cerrarAccionConError(
				emit,
				consulta,
				const ServerException('No se pudo cambiar el estado de la recepción.'),
			);
		}
	}

	Future<void> _onDevolucionSolicitada(
		RecepcionDevolucionSolicitada event,
		Emitter<RecepcionDetalleState> emit,
	) async {
		final recepcion = state.recepcion;
		if (recepcion == null || state.procesandoAccion) {
			return;
		}

		if (!ReglasRecepcion.puedeDevolver(recepcion)) {
			emit(
				state.copyWith(
					errorAccion: 'Solo se puede devolver un equipo en '
							'"${nombreEstadoRecepcion(EstadoRecepcion.listoParaDevolver)}".',
				),
			);
			return;
		}
		final forma = event.forma;
		if (forma == null) {
			emit(state.copyWith(errorAccion: 'Elegí cómo se devuelve el equipo.'));
			return;
		}

		final consulta = _secuencia;
		emit(state.copyWith(devolviendo: true, limpiarErrorAccion: true));

		try {
			final actualizada = await _devolverRecepcionUseCase.ejecutar(
				recepcionId: recepcion.id,
				solicitud: SolicitudDevolucion(
					formaDevolucion: forma,
					observacion: _textoOpcional(event.observacion),
				),
			);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			emit(
				state.copyWith(
					recepcion: actualizada,
					devolviendo: false,
					exitoMensaje: 'Equipo devuelto al cliente (${nombreFormaDevolucion(forma)}).',
					fechaReferencia: _ahora(),
				),
			);
		} on ServerException catch (e) {
			_cerrarAccionConError(emit, consulta, e);
		} catch (_) {
			_cerrarAccionConError(
				emit,
				consulta,
				const ServerException('No se pudo registrar la devolución.'),
			);
		}
	}

	Future<void> _onServicioGuardado(
		RecepcionServicioGuardado event,
		Emitter<RecepcionDetalleState> emit,
	) async {
		final servicioId = event.servicioId.trim();
		if (event.recepcionId.isEmpty || servicioId.isEmpty) {
			return;
		}
		_serviciosPorVincular[event.recepcionId] = servicioId;
		await _vincular(emit, event.recepcionId, servicioId);
	}

	Future<void> _onVinculacionReintentada(
		RecepcionVinculacionReintentada event,
		Emitter<RecepcionDetalleState> emit,
	) async {
		final recepcionId = state.recepcionId;
		final servicioId = state.servicioPorVincular;
		if (recepcionId == null || servicioId == null || state.vinculando) {
			return;
		}
		await _vincular(emit, recepcionId, servicioId);
	}

	/// La vinculacion se pide aunque el tecnico ya este mirando otra recepcion;
	/// el resultado solo se muestra si sigue en la misma.
	Future<void> _vincular(
		Emitter<RecepcionDetalleState> emit,
		String recepcionId,
		String servicioId,
	) async {
		final consulta = _secuencia;
		bool aLaVista() =>
				consulta == _secuencia && state.recepcionId == recepcionId && !emit.isDone;

		if (aLaVista()) {
			emit(
				state.copyWith(
					servicioPorVincular: servicioId,
					vinculando: true,
					limpiarErrorVinculacion: true,
				),
			);
		}

		ServerException error;
		try {
			final actualizada = await _vincularServicioRecepcionUseCase.ejecutar(
				recepcionId: recepcionId,
				servicioId: servicioId,
			);
			_serviciosPorVincular.remove(recepcionId);
			if (!aLaVista()) {
				return;
			}
			emit(
				state.copyWith(
					recepcion: actualizada,
					vinculando: false,
					limpiarServicioPorVincular: true,
					exitoMensaje: 'Servicio de fábrica vinculado a la recepción.',
					fechaReferencia: _ahora(),
				),
			);
			return;
		} on ServerException catch (e) {
			error = e;
		} catch (_) {
			error = const ServerException('No se pudo vincular el servicio a la recepción.');
		}

		if (!aLaVista()) {
			return;
		}
		// El servicio sigue guardado: queda para reintentar la vinculacion.
		emit(state.copyWith(vinculando: false, errorVinculacion: error.mensaje));

		if (error is ReglaFabricaException &&
				_codigosRecepcionDesactualizada.contains(error.codigo)) {
			add(const RecepcionDetalleRefrescado());
		}
	}

	/// El servicio pendiente de esa recepcion, salvo que ya tenga uno vinculado
	/// (la vinculacion pudo haber llegado aunque se perdio la respuesta).
	String? _servicioPorVincular(Recepcion recepcion) {
		if (ReglasRecepcion.tieneServicio(recepcion)) {
			_serviciosPorVincular.remove(recepcion.id);
			return null;
		}
		return _serviciosPorVincular[recepcion.id];
	}

	void _onErrorAccionDescartado(
		RecepcionErrorAccionDescartado event,
		Emitter<RecepcionDetalleState> emit,
	) {
		if (state.errorAccion != null) {
			emit(state.copyWith(limpiarErrorAccion: true));
		}
	}

	/// El mensaje del backend se muestra tal cual en el dialogo, que conserva
	/// lo que el tecnico escribio.
	void _cerrarAccionConError(
		Emitter<RecepcionDetalleState> emit,
		int consulta,
		ServerException error,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(
			state.copyWith(
				limpiarEstadoEnCurso: true,
				devolviendo: false,
				errorAccion: error.mensaje,
			),
		);

		if (error is ReglaFabricaException &&
				_codigosRecepcionDesactualizada.contains(error.codigo)) {
			add(const RecepcionDetalleRefrescado());
		}
	}

	static String? _textoOpcional(String texto) {
		final limpio = texto.trim();
		return limpio.isEmpty ? null : limpio;
	}
}
