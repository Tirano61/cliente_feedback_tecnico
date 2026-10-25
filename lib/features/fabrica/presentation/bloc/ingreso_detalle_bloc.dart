import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_falla_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_reparacion_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/derivar_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_causas_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_componentes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/recibir_de_desarrollo_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IngresoDetalleBloc extends Bloc<IngresoDetalleEvent, IngresoDetalleState> {
	/// Rechazos que indican que el ingreso cambio por otro lado: se vuelve a
	/// pedir para que los botones muestren lo que corresponde ahora.
	static const Set<String> _codigosIngresoDesactualizado = {
		CodigoReglaFabrica.transicionInvalida,
		CodigoReglaFabrica.celdaNoSeDeriva,
		CodigoReglaFabrica.fallaRequerida,
		CodigoReglaFabrica.reparacionYaRegistrada,
	};

	final ObtenerIngresoUseCase _obtenerIngresoUseCase;
	final DerivarIngresoUseCase _derivarIngresoUseCase;
	final CargarFallaIngresoUseCase _cargarFallaIngresoUseCase;
	final CargarReparacionIngresoUseCase _cargarReparacionIngresoUseCase;
	final RecibirDeDesarrolloUseCase _recibirDeDesarrolloUseCase;
	final ObtenerComponentesUseCase _obtenerComponentesUseCase;
	final ObtenerCausasUseCase _obtenerCausasUseCase;

	/// Cada apertura deja sin efecto las respuestas del ingreso anterior.
	int _secuencia = 0;

	IngresoDetalleBloc(
		this._obtenerIngresoUseCase,
		this._derivarIngresoUseCase,
		this._cargarFallaIngresoUseCase,
		this._cargarReparacionIngresoUseCase,
		this._recibirDeDesarrolloUseCase,
		this._obtenerComponentesUseCase,
		this._obtenerCausasUseCase,
	) : super(const IngresoDetalleState()) {
		on<IngresoDetalleAbierto>(_onAbierto);
		on<IngresoDetalleRefrescado>(_onRefrescado);
		on<IngresoDerivacionSolicitada>(_onDerivacionSolicitada);
		on<IngresoVueltaDesarrolloSolicitada>(_onVueltaDesarrolloSolicitada);
		on<IngresoCatalogosFallaSolicitados>(_onCatalogosFallaSolicitados);
		on<IngresoFallaSolicitada>(_onFallaSolicitada);
		on<IngresoReparacionSolicitada>(_onReparacionSolicitada);
		on<IngresoErrorAccionDescartado>(_onErrorAccionDescartado);
	}

	Future<void> _onAbierto(
		IngresoDetalleAbierto event,
		Emitter<IngresoDetalleState> emit,
	) async {
		final consulta = ++_secuencia;
		final inicial = event.ingreso;
		if (inicial != null) {
			emit(IngresoDetalleState(ingresoId: event.ingresoId, ingreso: inicial));
			return;
		}

		emit(IngresoDetalleState(ingresoId: event.ingresoId, cargando: true));
		await _cargar(emit, consulta);
	}

	Future<void> _onRefrescado(
		IngresoDetalleRefrescado event,
		Emitter<IngresoDetalleState> emit,
	) async {
		if (state.ingresoId == null || state.cargando) {
			return;
		}
		emit(state.copyWith(cargando: true, limpiarErrorCarga: true));
		await _cargar(emit, _secuencia);
	}

	Future<void> _cargar(Emitter<IngresoDetalleState> emit, int consulta) async {
		final ingresoId = state.ingresoId;
		if (ingresoId == null) {
			return;
		}

		String? error;
		try {
			final ingreso = await _obtenerIngresoUseCase.ejecutar(ingresoId);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			emit(state.copyWith(ingreso: ingreso, cargando: false, limpiarErrorCarga: true));
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudo cargar el ingreso.';
		}

		if (consulta != _secuencia || emit.isDone) {
			return;
		}
		// Con el ingreso a la vista, el error de un refresco va al snackbar.
		emit(
			state.ingreso == null
					? state.copyWith(cargando: false, errorCarga: error)
					: state.copyWith(cargando: false, errorMensaje: error),
		);
	}

	Future<void> _onDerivacionSolicitada(
		IngresoDerivacionSolicitada event,
		Emitter<IngresoDetalleState> emit,
	) {
		return _ejecutar(
			emit,
			AccionIngreso.derivar,
			(ingreso) => _derivarIngresoUseCase.ejecutar(
				ingresoId: ingreso.id,
				observacion: _textoOpcional(event.observacion),
			),
			exito: (_) => 'Placa derivada a desarrollo.',
			errorGenerico: 'No se pudo derivar la placa a desarrollo.',
		);
	}

	Future<void> _onVueltaDesarrolloSolicitada(
		IngresoVueltaDesarrolloSolicitada event,
		Emitter<IngresoDetalleState> emit,
	) {
		return _ejecutar(
			emit,
			AccionIngreso.recibirDeDesarrollo,
			(ingreso) => _recibirDeDesarrolloUseCase.ejecutar(
				ingresoId: ingreso.id,
				observacion: _textoOpcional(event.observacion),
			),
			exito: (_) => 'Placa recibida de desarrollo: quedó reacondicionada disponible.',
			errorGenerico: 'No se pudo recibir la placa de desarrollo.',
		);
	}

	Future<void> _onCatalogosFallaSolicitados(
		IngresoCatalogosFallaSolicitados event,
		Emitter<IngresoDetalleState> emit,
	) async {
		final ingreso = state.ingreso;
		if (ingreso == null || state.cargandoCatalogosFalla || state.catalogosFallaCargados) {
			return;
		}

		final consulta = _secuencia;
		final productoId = ingreso.unidad.producto?.id.trim() ?? '';
		emit(state.copyWith(cargandoCatalogosFalla: true, limpiarErrorCatalogosFalla: true));

		String error;
		try {
			// Sin modelo de la pieza no hay componentes de catalogo: solo "otro".
			final resultados = await Future.wait([
				productoId.isEmpty
						? Future.value(const <Componente>[])
						: _obtenerComponentesUseCase.ejecutar(productoId: productoId),
				_obtenerCausasUseCase.ejecutar(),
			]);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			emit(
				state.copyWith(
					componentes: resultados[0] as List<Componente>,
					causas: resultados[1] as List<Causa>,
					cargandoCatalogosFalla: false,
					catalogosFallaCargados: true,
				),
			);
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudieron cargar los componentes y las causas.';
		}

		if (consulta != _secuencia || emit.isDone) {
			return;
		}
		emit(state.copyWith(cargandoCatalogosFalla: false, errorCatalogosFalla: error));
	}

	Future<void> _onFallaSolicitada(
		IngresoFallaSolicitada event,
		Emitter<IngresoDetalleState> emit,
	) async {
		final componenteId = (event.componenteId ?? '').trim();
		final componenteOtro = event.componenteOtro.trim();
		final causaId = (event.causaId ?? '').trim();
		final faltantes = [
			if (componenteId.isEmpty && componenteOtro.isEmpty) 'componente que falló',
			if (causaId.isEmpty) 'causa',
		];
		if (faltantes.isNotEmpty) {
			emit(state.copyWith(errorAccion: 'Falta completar: ${faltantes.join(', ')}.'));
			return;
		}

		await _ejecutar(
			emit,
			AccionIngreso.cargarFalla,
			(ingreso) => _cargarFallaIngresoUseCase.ejecutar(
				ingresoId: ingreso.id,
				// Uno u otro: el del catalogo manda sobre lo escrito.
				solicitud: SolicitudFalla(
					componenteId: componenteId.isEmpty ? null : componenteId,
					componenteOtro: componenteId.isEmpty ? componenteOtro : null,
					causaId: causaId,
					detalle: _textoOpcional(event.detalle),
				),
			),
			exito: (_) => 'Falla cargada.',
			errorGenerico: 'No se pudo cargar la falla.',
		);
	}

	Future<void> _onReparacionSolicitada(
		IngresoReparacionSolicitada event,
		Emitter<IngresoDetalleState> emit,
	) async {
		final resultado = event.resultado;
		final trabajo = event.trabajoRealizado.trim();
		final faltantes = [
			if (resultado == null) 'resultado (reparada o irreparable)',
			if (trabajo.isEmpty) 'trabajo realizado',
		];
		if (faltantes.isNotEmpty) {
			emit(state.copyWith(errorAccion: 'Falta completar: ${faltantes.join(', ')}.'));
			return;
		}

		await _ejecutar(
			emit,
			AccionIngreso.cargarReparacion,
			(ingreso) => _cargarReparacionIngresoUseCase.ejecutar(
				ingresoId: ingreso.id,
				solicitud: SolicitudReparacion(
					resultado: resultado!,
					trabajoRealizado: trabajo,
					componentesReemplazados: _textoOpcional(event.componentesReemplazados),
				),
			),
			exito: (_) => resultado == ResultadoReparacion.reparada
					? 'Reparación cargada: la celda quedó reacondicionada disponible.'
					: 'Reparación cargada: la celda quedó descartada.',
			errorGenerico: 'No se pudo cargar la reparación.',
		);
	}

	/// Corre una accion permitida para el tipo y el estado actuales. Una que no
	/// corresponde no llega al backend.
	Future<void> _ejecutar(
		Emitter<IngresoDetalleState> emit,
		AccionIngreso accion,
		Future<Ingreso> Function(Ingreso ingreso) operacion, {
		required String Function(Ingreso actualizado) exito,
		required String errorGenerico,
	}) async {
		final ingreso = state.ingreso;
		if (ingreso == null || state.procesandoAccion) {
			return;
		}

		final disponible = state.acciones.where((a) => a.accion == accion).firstOrNull;
		if (disponible == null) {
			emit(
				state.copyWith(
					errorAccion: 'No se puede hacer esto con una '
							'${nombreTipoUnidad(ingreso.unidad.tipo).toLowerCase()} en '
							'"${nombreEstadoIngreso(ingreso.estado)}".',
				),
			);
			return;
		}
		if (!disponible.habilitada) {
			emit(state.copyWith(errorAccion: disponible.motivoBloqueo));
			return;
		}

		final consulta = _secuencia;
		emit(state.copyWith(accionEnCurso: accion, limpiarErrorAccion: true));

		ServerException error;
		try {
			final actualizado = await operacion(ingreso);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			emit(
				state.copyWith(
					ingreso: actualizado,
					limpiarAccionEnCurso: true,
					exitoMensaje: exito(actualizado),
				),
			);
			return;
		} on ServerException catch (e) {
			error = e;
		} catch (_) {
			error = ServerException(errorGenerico);
		}

		if (consulta != _secuencia || emit.isDone) {
			return;
		}
		// El mensaje del backend se muestra tal cual en el dialogo, que conserva
		// lo que el tecnico cargo.
		emit(state.copyWith(limpiarAccionEnCurso: true, errorAccion: error.mensaje));

		if (error is ReglaFabricaException &&
				_codigosIngresoDesactualizado.contains(error.codigo)) {
			add(const IngresoDetalleRefrescado());
		}
	}

	void _onErrorAccionDescartado(
		IngresoErrorAccionDescartado event,
		Emitter<IngresoDetalleState> emit,
	) {
		if (state.errorAccion != null) {
			emit(state.copyWith(limpiarErrorAccion: true));
		}
	}

	static String? _textoOpcional(String texto) {
		final limpio = texto.trim();
		return limpio.isEmpty ? null : limpio;
	}
}
