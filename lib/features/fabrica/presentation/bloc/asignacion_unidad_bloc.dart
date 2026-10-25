import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Poner placa/celda" en el indicador de una recepcion
/// (`POST /fabrica/unidades/asignaciones`).
class AsignacionUnidadBloc extends Bloc<AsignacionUnidadEvent, AsignacionUnidadState> {
	/// Rechazos que dicen que las piezas del indicador no son las que se
	/// muestran: se vuelven a pedir.
	static const Set<String> _codigosPiezasDesactualizadas = {
		CodigoReglaFabrica.retiradaNoInstalada,
		CodigoReglaFabrica.unidadYaInstalada,
	};

	final AsignarUnidadUseCase _asignarUnidadUseCase;
	final BuscarUnidadesUseCase _buscarUnidadesUseCase;
	final ObtenerUnidadUseCase _obtenerUnidadUseCase;

	/// Un formulario nuevo o un cambio de tipo deja sin efecto la lista de
	/// reacondicionadas que siga en vuelo.
	int _secuenciaReacondicionadas = 0;

	/// Un formulario nuevo deja sin efecto la asignacion y las piezas que
	/// sigan en vuelo.
	int _secuencia = 0;

	AsignacionUnidadBloc(
		this._asignarUnidadUseCase,
		this._buscarUnidadesUseCase,
		this._obtenerUnidadUseCase,
	) : super(const AsignacionUnidadState()) {
		on<AsignacionIniciada>(_onIniciada);
		on<AsignacionCambiada>(_onCambiada);
		on<AsignacionReacondicionadaElegida>(_onReacondicionadaElegida);
		on<AsignacionRetiradaElegida>(_onRetiradaElegida);
		on<AsignacionReacondicionadasSolicitadas>(_onReacondicionadasSolicitadas);
		on<AsignacionGuardada>(_onGuardada);
	}

	void _onIniciada(
		AsignacionIniciada event,
		Emitter<AsignacionUnidadState> emit,
	) {
		_secuencia++;
		_secuenciaReacondicionadas++;
		emit(
			AsignacionUnidadState(
				precarga: event.precarga,
				piezasInstaladas: event.precarga.piezasInstaladas,
			),
		);
	}

	Future<void> _onCambiada(
		AsignacionCambiada event,
		Emitter<AsignacionUnidadState> emit,
	) async {
		if (state.asignada) {
			return;
		}

		// El modelo, la pieza que sale y las reacondicionadas son del tipo:
		// si cambia ya no valen.
		final tipo = event.tipo;
		final cambioTipo = tipo != null && tipo != state.tipo;
		emit(
			state.copyWith(
				tipo: tipo,
				nroSerie: event.nroSerie,
				productoId: event.productoId,
				limpiarProducto: event.limpiarProducto || (cambioTipo && event.productoId == null),
				retiradaNroSerie: event.retiradaNroSerie ?? (cambioTipo ? '' : null),
				observacion: event.observacion,
				reacondicionadas: cambioTipo ? const [] : null,
				totalReacondicionadas: cambioTipo ? 0 : null,
				cargandoReacondicionadas: cambioTipo ? true : null,
			),
		);

		if (cambioTipo) {
			await _cargarReacondicionadas(emit, tipo);
		}
	}

	void _onReacondicionadaElegida(
		AsignacionReacondicionadaElegida event,
		Emitter<AsignacionUnidadState> emit,
	) {
		final unidad = event.unidad;
		if (state.asignada || unidad.tipo != state.tipo) {
			return;
		}
		emit(
			state.copyWith(
				nroSerie: unidad.nroSerie,
				productoId: unidad.producto?.id,
				limpiarProducto: unidad.producto == null,
			),
		);
	}

	void _onRetiradaElegida(
		AsignacionRetiradaElegida event,
		Emitter<AsignacionUnidadState> emit,
	) {
		final pieza = event.pieza;
		if (state.asignada || pieza.tipo != state.tipo) {
			return;
		}
		final yaElegida = normalizarSerie(state.retiradaNroSerie) == normalizarSerie(pieza.nroSerie);
		emit(state.copyWith(retiradaNroSerie: yaElegida ? '' : pieza.nroSerie));
	}

	Future<void> _onReacondicionadasSolicitadas(
		AsignacionReacondicionadasSolicitadas event,
		Emitter<AsignacionUnidadState> emit,
	) async {
		final tipo = state.tipo;
		if (tipo == null || state.cargandoReacondicionadas || state.asignada) {
			return;
		}
		await _cargarReacondicionadas(emit, tipo);
	}

	Future<void> _cargarReacondicionadas(
		Emitter<AsignacionUnidadState> emit,
		TipoUnidad tipo,
	) async {
		final consulta = ++_secuenciaReacondicionadas;
		bool vigente() => consulta == _secuenciaReacondicionadas && !emit.isDone;

		emit(state.copyWith(cargandoReacondicionadas: true, limpiarErrorReacondicionadas: true));

		String error;
		try {
			final pagina = await _buscarUnidadesUseCase.ejecutar(
				pagina: 1,
				tipo: tipo,
				estado: EstadoUnidad.reacondicionadaDisponible,
			);
			if (!vigente()) {
				return;
			}
			emit(
				state.copyWith(
					reacondicionadas: pagina.items,
					totalReacondicionadas: pagina.total,
					cargandoReacondicionadas: false,
				),
			);
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudieron cargar las piezas reacondicionadas.';
		}

		if (vigente()) {
			emit(state.copyWith(cargandoReacondicionadas: false, errorReacondicionadas: error));
		}
	}

	Future<void> _onGuardada(
		AsignacionGuardada event,
		Emitter<AsignacionUnidadState> emit,
	) async {
		final precarga = state.precarga;
		if (precarga == null || state.guardando || state.asignada) {
			return;
		}

		final tipo = state.tipo;
		final nroSerie = state.nroSerie.trim();
		final retirada = state.retiradaNroSerie.trim();
		final faltantes = [
			if (tipo == null) 'tipo de pieza',
			if (nroSerie.isEmpty) 'número de serie de la pieza que se pone',
		];
		String? aviso;
		if (faltantes.isNotEmpty) {
			aviso = 'Falta completar: ${faltantes.join(', ')}.';
		} else if (retirada.isNotEmpty && normalizarSerie(retirada) == normalizarSerie(nroSerie)) {
			aviso = 'La pieza que se saca no puede ser la misma que se pone.';
		}
		if (aviso != null) {
			// Si toca "Poner" otra vez sin cambios, el aviso tiene que volver a salir.
			emit(state.copyWith());
			emit(state.copyWith(errorMensaje: aviso));
			return;
		}

		final consulta = _secuencia;
		bool vigente() => consulta == _secuencia && !emit.isDone;
		final observacion = state.observacion.trim();
		emit(state.copyWith(guardando: true, limpiarErrorAsignacion: true));

		try {
			final resultado = await _asignarUnidadUseCase.ejecutar(
				SolicitudAsignacion(
					indicadorNroSerie: precarga.indicadorNroSerie,
					tipo: tipo!,
					nroSerie: nroSerie,
					productoId: state.productoId,
					retiradaNroSerie: retirada.isEmpty ? null : retirada,
					recepcionId: precarga.recepcionId,
					observacion: observacion.isEmpty ? null : observacion,
				),
			);
			if (vigente()) {
				emit(state.copyWith(guardando: false, resultado: resultado));
			}
		} on ReglaFabricaException catch (e) {
			// Se conserva todo lo cargado: el tecnico corrige y vuelve a poner.
			if (!vigente()) {
				return;
			}
			emit(state.copyWith(guardando: false, errorAsignacion: e.mensaje));
			if (_codigosPiezasDesactualizadas.contains(e.codigo)) {
				await _refrescarPiezasInstaladas(emit, precarga.indicadorId, consulta);
			} else if (e.codigo == CodigoReglaFabrica.unidadNoDisponible) {
				// La reacondicionada elegida pudo haberse usado en otro equipo.
				await _cargarReacondicionadas(emit, tipo!);
			}
		} on ServerException catch (e) {
			if (vigente()) {
				emit(state.copyWith(guardando: false, errorAsignacion: e.mensaje));
			}
		} catch (_) {
			if (vigente()) {
				emit(state.copyWith(guardando: false, errorAsignacion: 'No se pudo poner la pieza.'));
			}
		}
	}

	/// Si no se pueden traer, quedan las que se mostraban: el mensaje del
	/// rechazo ya esta a la vista.
	Future<void> _refrescarPiezasInstaladas(
		Emitter<AsignacionUnidadState> emit,
		String indicadorId,
		int consulta,
	) async {
		try {
			final indicador = await _obtenerUnidadUseCase.ejecutar(indicadorId);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
			// Lo cargado no se toca: el tecnico ve las piezas actuales y corrige.
			emit(
				state.copyWith(
					piezasInstaladas: indicador.piezasInstaladas
							.where((p) => AsignacionUnidadState.tiposAsignables.contains(p.tipo))
							.toList(),
				),
			);
		} catch (_) {
			// Quedan las piezas que se mostraban.
		}
	}
}
