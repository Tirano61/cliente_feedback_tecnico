import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecepcionesBloc extends Bloc<RecepcionesEvent, RecepcionesState> {
	static const String _mensajeErrorListado = 'No se pudieron cargar los equipos en fábrica.';
	static const String _mensajeErrorPaginacion = 'No se pudieron cargar más equipos.';

	final ObtenerRecepcionesUseCase _obtenerRecepcionesUseCase;

	/// Pausa antes de mandar la busqueda, para no pegarle al backend por tecla.
	final Duration _esperaBusqueda;
	final DateTime Function() _ahora;

	/// Cada consulta nueva deja sin efecto las respuestas que sigan en vuelo:
	/// si el tecnico tipeo otra letra o cambio el filtro, la vieja ya no es lo
	/// que esta mirando.
	int _secuencia = 0;

	RecepcionesBloc(
		this._obtenerRecepcionesUseCase, {
		Duration esperaBusqueda = const Duration(milliseconds: 400),
		DateTime Function()? ahora,
	})  : _esperaBusqueda = esperaBusqueda,
				_ahora = ahora ?? DateTime.now,
				super(const RecepcionesState()) {
		on<RecepcionesSolicitadas>(_onSolicitadas);
		on<RecepcionesRefrescadas>(_onRefrescadas);
		on<RecepcionesBusquedaCambiada>(_onBusquedaCambiada);
		on<RecepcionesFiltroEstadoCambiado>(_onFiltroEstadoCambiado);
		on<RecepcionesVerDevueltasCambiado>(_onVerDevueltasCambiado);
		on<RecepcionesSiguientePaginaSolicitada>(_onSiguientePagina);
	}

	Future<void> _onSolicitadas(
		RecepcionesSolicitadas event,
		Emitter<RecepcionesState> emit,
	) async {
		// Volver a entrar no le borra al tecnico la busqueda ni los filtros.
		emit(
			state.copyWith(
				recepciones: const [],
				total: 0,
				pagina: 0,
				totalPaginas: 0,
				cargando: true,
				actualizando: false,
				cargandoMas: false,
				limpiarErrorListado: true,
				limpiarErrorPaginacion: true,
			),
		);
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onRefrescadas(
		RecepcionesRefrescadas event,
		Emitter<RecepcionesState> emit,
	) async {
		if (state.cargando) {
			return;
		}
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onBusquedaCambiada(
		RecepcionesBusquedaCambiada event,
		Emitter<RecepcionesState> emit,
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

	Future<void> _onFiltroEstadoCambiado(
		RecepcionesFiltroEstadoCambiado event,
		Emitter<RecepcionesState> emit,
	) async {
		if (state.filtroEstado == event.estado) {
			return;
		}

		emit(
			state.copyWith(
				filtroEstado: event.estado,
				limpiarFiltroEstado: event.estado == null,
			),
		);
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onVerDevueltasCambiado(
		RecepcionesVerDevueltasCambiado event,
		Emitter<RecepcionesState> emit,
	) async {
		if (state.verDevueltas == event.verDevueltas) {
			return;
		}

		// Sin las devueltas, el filtro "Devuelto" ya no tiene chip ni resultados.
		final quitarFiltroDevuelto =
				!event.verDevueltas && state.filtroEstado == EstadoRecepcion.devuelto;
		emit(
			state.copyWith(
				verDevueltas: event.verDevueltas,
				limpiarFiltroEstado: quitarFiltroDevuelto,
			),
		);
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onSiguientePagina(
		RecepcionesSiguientePaginaSolicitada event,
		Emitter<RecepcionesState> emit,
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

			// El backend pagina por fecha: si entro una recepcion entre pagina y
			// pagina, el offset se corre y una se repite.
			final idsCargados = state.recepciones.map((r) => r.id).toSet();
			emit(
				state.copyWith(
					recepciones: [
						...state.recepciones,
						...pagina.items.where((r) => !idsCargados.contains(r.id)),
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

	/// Pide la primera pagina con la busqueda y los filtros vigentes.
	Future<void> _consultarPrimeraPagina(
		Emitter<RecepcionesState> emit, {
		Duration? espera,
	}) async {
		final consulta = ++_secuencia;
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
					recepciones: pagina.items,
					total: pagina.total,
					pagina: pagina.pagina,
					totalPaginas: pagina.totalPaginas,
					cargando: false,
					actualizando: false,
					fechaReferencia: _ahora(),
				),
			);
		} on ServerException catch (e) {
			_cerrarConsultaConError(emit, consulta, e.mensaje);
		} catch (_) {
			_cerrarConsultaConError(emit, consulta, _mensajeErrorListado);
		}
	}

	Future<PaginaFabrica<Recepcion>> _pedir(int pagina) {
		return _obtenerRecepcionesUseCase.ejecutar(
			pagina: pagina,
			estado: state.filtroEstado,
			abiertas: state.verDevueltas ? null : true,
			busqueda: state.busqueda.trim(),
		);
	}

	/// Si falla la consulta con la busqueda o los filtros nuevos, el listado
	/// anterior no corresponde a lo que pide el tecnico: se vacia.
	void _cerrarConsultaConError(
		Emitter<RecepcionesState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(
			state.copyWith(
				recepciones: const [],
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
		Emitter<RecepcionesState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(state.copyWith(cargandoMas: false, errorPaginacion: mensaje));
	}
}
