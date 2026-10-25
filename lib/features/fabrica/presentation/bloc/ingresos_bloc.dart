import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingresos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_ingreso.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IngresosBloc extends Bloc<IngresosEvent, IngresosState> {
	static const String _mensajeErrorListado = 'No se pudieron cargar las piezas ingresadas.';
	static const String _mensajeErrorPaginacion = 'No se pudieron cargar más piezas.';

	final ObtenerIngresosUseCase _obtenerIngresosUseCase;

	/// Pausa antes de mandar la busqueda, para no pegarle al backend por tecla.
	final Duration _esperaBusqueda;

	/// Cada consulta nueva deja sin efecto las respuestas que sigan en vuelo.
	int _secuencia = 0;

	IngresosBloc(
		this._obtenerIngresosUseCase, {
		Duration esperaBusqueda = const Duration(milliseconds: 400),
	})  : _esperaBusqueda = esperaBusqueda,
				super(const IngresosState()) {
		on<IngresosSolicitados>(_onSolicitados);
		on<IngresosRefrescados>(_onRefrescados);
		on<IngresosBusquedaCambiada>(_onBusquedaCambiada);
		on<IngresosFiltroTipoCambiado>(_onFiltroTipoCambiado);
		on<IngresosFiltroEstadoCambiado>(_onFiltroEstadoCambiado);
		on<IngresosSiguientePaginaSolicitada>(_onSiguientePagina);
	}

	Future<void> _onSolicitados(
		IngresosSolicitados event,
		Emitter<IngresosState> emit,
	) async {
		// Volver a entrar no le borra al tecnico la busqueda ni los filtros.
		emit(
			state.copyWith(
				ingresos: const [],
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

	Future<void> _onRefrescados(
		IngresosRefrescados event,
		Emitter<IngresosState> emit,
	) async {
		if (state.cargando) {
			return;
		}
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onBusquedaCambiada(
		IngresosBusquedaCambiada event,
		Emitter<IngresosState> emit,
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

	Future<void> _onFiltroTipoCambiado(
		IngresosFiltroTipoCambiado event,
		Emitter<IngresosState> emit,
	) async {
		if (state.filtroTipo == event.tipo) {
			return;
		}

		// Un estado que el tipo nuevo no tiene (las celdas no van a desarrollo)
		// dejaria el listado vacio sin chip para sacarlo.
		final estado = state.filtroEstado;
		final quitarEstado =
				estado != null && !ReglasIngreso.estadosPosibles(event.tipo).contains(estado);
		emit(
			state.copyWith(
				filtroTipo: event.tipo,
				limpiarFiltroTipo: event.tipo == null,
				limpiarFiltroEstado: quitarEstado,
			),
		);
		await _consultarPrimeraPagina(emit);
	}

	Future<void> _onFiltroEstadoCambiado(
		IngresosFiltroEstadoCambiado event,
		Emitter<IngresosState> emit,
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

	Future<void> _onSiguientePagina(
		IngresosSiguientePaginaSolicitada event,
		Emitter<IngresosState> emit,
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

			// Si entro un ingreso entre pagina y pagina, el offset se corre y
			// uno se repite.
			final idsCargados = state.ingresos.map((i) => i.id).toSet();
			emit(
				state.copyWith(
					ingresos: [
						...state.ingresos,
						...pagina.items.where((i) => !idsCargados.contains(i.id)),
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
		Emitter<IngresosState> emit, {
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
					ingresos: pagina.items,
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

	Future<PaginaFabrica<Ingreso>> _pedir(int pagina) {
		return _obtenerIngresosUseCase.ejecutar(
			pagina: pagina,
			tipo: state.filtroTipo,
			estado: state.filtroEstado,
			busqueda: state.busqueda.trim(),
		);
	}

	/// Si falla la consulta con la busqueda o los filtros nuevos, el listado
	/// anterior no corresponde a lo que pide el tecnico: se vacia.
	void _cerrarConsultaConError(
		Emitter<IngresosState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(
			state.copyWith(
				ingresos: const [],
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
		Emitter<IngresosState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuencia || emit.isDone) {
			return;
		}

		emit(state.copyWith(cargandoMas: false, errorPaginacion: mensaje));
	}
}
