import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PiezasBloc extends Bloc<PiezasEvent, PiezasState> {
	static const String _mensajeErrorListado = 'No se pudieron buscar las piezas.';
	static const String _mensajeErrorPaginacion = 'No se pudieron cargar más piezas.';

	final BuscarUnidadesUseCase _buscarUnidadesUseCase;

	/// Pausa antes de mandar la busqueda, para no pegarle al backend por tecla.
	final Duration _esperaBusqueda;

	/// Cada consulta nueva deja sin efecto las respuestas que sigan en vuelo.
	int _secuencia = 0;

	PiezasBloc(
		this._buscarUnidadesUseCase, {
		Duration esperaBusqueda = const Duration(milliseconds: 400),
	})  : _esperaBusqueda = esperaBusqueda,
				super(const PiezasState()) {
		on<PiezasSolicitadas>(_onSolicitadas);
		on<PiezasRefrescadas>(_onRefrescadas);
		on<PiezasBusquedaCambiada>(_onBusquedaCambiada);
		on<PiezasReacondicionadasAlternadas>(_onReacondicionadasAlternadas);
		on<PiezasSiguientePaginaSolicitada>(_onSiguientePagina);
	}

	Future<void> _onSolicitadas(
		PiezasSolicitadas event,
		Emitter<PiezasState> emit,
	) async {
		// Volver a entrar no le borra al tecnico la busqueda ni el atajo.
		emit(
			state.copyWith(
				piezas: const [],
				total: 0,
				pagina: 0,
				totalPaginas: 0,
				cargando: state.hayConsulta,
				actualizando: false,
				cargandoMas: false,
				limpiarErrorListado: true,
				limpiarErrorPaginacion: true,
			),
		);
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onRefrescadas(
		PiezasRefrescadas event,
		Emitter<PiezasState> emit,
	) async {
		if (state.cargando) {
			return;
		}
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onBusquedaCambiada(
		PiezasBusquedaCambiada event,
		Emitter<PiezasState> emit,
	) async {
		final anterior = state.busqueda;
		if (anterior == event.texto) {
			return;
		}

		// El texto se guarda tal cual para que el campo no salte; si solo
		// cambiaron los espacios de los bordes, la consulta vigente sirve.
		emit(state.copyWith(busqueda: event.texto));
		if (anterior.trim() == event.texto.trim()) {
			return;
		}

		await _consultarPrimeraPagina(emit, espera: _esperaBusqueda);
	}

	Future<void> _onReacondicionadasAlternadas(
		PiezasReacondicionadasAlternadas event,
		Emitter<PiezasState> emit,
	) async {
		if (state.soloReacondicionadas == event.activas) {
			return;
		}

		emit(state.copyWith(soloReacondicionadas: event.activas));
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onSiguientePagina(
		PiezasSiguientePaginaSolicitada event,
		Emitter<PiezasState> emit,
	) async {
		final actual = state;
		if (actual.cargando || actual.actualizando || actual.cargandoMas || !actual.hayMasPaginas) {
			return;
		}
		if (actual.errorPaginacion != null && !event.reintento) {
			return;
		}

		final consulta = _secuencia;
		emit(actual.copyWith(cargandoMas: true, limpiarErrorPaginacion: true));

		try {
			final pagina = await _pedir(actual.pagina + 1);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}

			// Si se registro una pieza entre pagina y pagina, el offset se corre
			// y una se repite.
			final idsCargados = state.piezas.map((p) => p.id).toSet();
			emit(
				state.copyWith(
					piezas: [
						...state.piezas,
						...pagina.items.where((p) => !idsCargados.contains(p.id)),
					],
					total: pagina.total,
					pagina: pagina.pagina,
					totalPaginas: pagina.totalPaginas,
					cargandoMas: false,
				),
			);
		} on ServerException catch (e) {
			_cerrarPaginaConError(emit, consulta, e.mensaje);
		} catch (_) {
			_cerrarPaginaConError(emit, consulta, _mensajeErrorPaginacion);
		}
	}

	/// Pide la primera pagina con la busqueda y el atajo vigentes. Sin
	/// ninguno de los dos no hay nada que pedir.
	Future<void> _consultarPrimeraPagina(
		Emitter<PiezasState> emit, {
		Duration? espera,
	}) async {
		final consulta = ++_secuencia;
		if (!state.hayConsulta) {
			emit(
				state.copyWith(
					piezas: const [],
					total: 0,
					pagina: 0,
					totalPaginas: 0,
					cargando: false,
					actualizando: false,
					cargandoMas: false,
					limpiarErrorListado: true,
					limpiarErrorPaginacion: true,
				),
			);
			return;
		}

		if (espera != null) {
			await Future<void>.delayed(espera);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}
		}

		if (!state.cargando) {
			emit(
				state.copyWith(
					actualizando: true,
					cargandoMas: false,
					limpiarErrorListado: true,
					limpiarErrorPaginacion: true,
				),
			);
		}

		try {
			final pagina = await _pedir(1);
			if (consulta != _secuencia || emit.isDone) {
				return;
			}

			emit(
				state.copyWith(
					piezas: pagina.items,
					total: pagina.total,
					pagina: pagina.pagina,
					totalPaginas: pagina.totalPaginas,
					cargando: false,
					actualizando: false,
				),
			);
		} on ServerException catch (e) {
			_cerrarConsultaConError(emit, consulta, e.mensaje);
		} catch (_) {
			_cerrarConsultaConError(emit, consulta, _mensajeErrorListado);
		}
	}

	/// La busqueda va en `q` (el backend busca el numero de serie en parte,
	/// sin importar mayusculas).
	Future<PaginaFabrica<Unidad>> _pedir(int pagina) {
		final reacondicionadas = state.soloReacondicionadas;
		return _buscarUnidadesUseCase.ejecutar(
			pagina: pagina,
			tipo: reacondicionadas ? TipoUnidad.placa : null,
			estado: reacondicionadas ? EstadoUnidad.reacondicionadaDisponible : null,
			busqueda: state.busqueda.trim(),
		);
	}

	/// Si falla la consulta con la busqueda nueva, el listado anterior no
	/// corresponde a lo que pide el tecnico: se vacia.
	void _cerrarConsultaConError(
		Emitter<PiezasState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(
			state.copyWith(
				piezas: const [],
				total: 0,
				pagina: 0,
				totalPaginas: 0,
				cargando: false,
				actualizando: false,
				errorListado: mensaje,
			),
		);
	}

	void _cerrarPaginaConError(
		Emitter<PiezasState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(state.copyWith(cargandoMas: false, errorPaginacion: mensaje));
	}
}
