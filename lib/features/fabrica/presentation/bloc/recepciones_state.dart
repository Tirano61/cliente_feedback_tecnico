import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:equatable/equatable.dart';

/// Listado de "Equipos en fabrica".
class RecepcionesState extends Equatable {
	static const List<EstadoRecepcion> _estadosAbiertos = [
		EstadoRecepcion.recibido,
		EstadoRecepcion.enReparacion,
		EstadoRecepcion.esperandoPresupuesto,
		EstadoRecepcion.listoParaDevolver,
	];

	final List<Recepcion> recepciones;
	final String busqueda;

	/// null: todos los estados.
	final EstadoRecepcion? filtroEstado;

	/// false: solo las abiertas (`abiertas=true`); true: tambien las devueltas.
	final bool verDevueltas;
	final int total;
	final int pagina;
	final int totalPaginas;

	/// Primera carga: todavia no hay listado que mostrar.
	final bool cargando;

	/// Consulta nueva (busqueda, filtro, refresco) con el listado a la vista.
	final bool actualizando;
	final bool cargandoMas;
	final String? errorListado;
	final String? errorPaginacion;

	/// "Hoy" de la ultima consulta, para contar los dias en fabrica.
	final DateTime? fechaReferencia;

	const RecepcionesState({
		this.recepciones = const [],
		this.busqueda = '',
		this.filtroEstado,
		this.verDevueltas = false,
		this.total = 0,
		this.pagina = 0,
		this.totalPaginas = 0,
		this.cargando = false,
		this.actualizando = false,
		this.cargandoMas = false,
		this.errorListado,
		this.errorPaginacion,
		this.fechaReferencia,
	});

	bool get hayMasPaginas => pagina < totalPaginas;

	bool get hayFiltrosActivos =>
			busqueda.trim().isNotEmpty || filtroEstado != null || verDevueltas;

	/// Chips del filtro: `devuelto` solo tiene sentido viendo las devueltas.
	List<EstadoRecepcion> get estadosFiltrables => [
				..._estadosAbiertos,
				if (verDevueltas) EstadoRecepcion.devuelto,
			];

	int? diasEnFabrica(Recepcion recepcion) {
		final referencia = fechaReferencia;
		if (referencia == null) {
			return null;
		}
		return ReglasRecepcion.diasEnFabrica(recepcion, referencia);
	}

	RecepcionesState copyWith({
		List<Recepcion>? recepciones,
		String? busqueda,
		EstadoRecepcion? filtroEstado,
		bool limpiarFiltroEstado = false,
		bool? verDevueltas,
		int? total,
		int? pagina,
		int? totalPaginas,
		bool? cargando,
		bool? actualizando,
		bool? cargandoMas,
		String? errorListado,
		bool limpiarErrorListado = false,
		String? errorPaginacion,
		bool limpiarErrorPaginacion = false,
		DateTime? fechaReferencia,
	}) {
		return RecepcionesState(
			recepciones: recepciones ?? this.recepciones,
			busqueda: busqueda ?? this.busqueda,
			filtroEstado: limpiarFiltroEstado ? null : (filtroEstado ?? this.filtroEstado),
			verDevueltas: verDevueltas ?? this.verDevueltas,
			total: total ?? this.total,
			pagina: pagina ?? this.pagina,
			totalPaginas: totalPaginas ?? this.totalPaginas,
			cargando: cargando ?? this.cargando,
			actualizando: actualizando ?? this.actualizando,
			cargandoMas: cargandoMas ?? this.cargandoMas,
			errorListado: limpiarErrorListado ? null : (errorListado ?? this.errorListado),
			errorPaginacion:
					limpiarErrorPaginacion ? null : (errorPaginacion ?? this.errorPaginacion),
			fechaReferencia: fechaReferencia ?? this.fechaReferencia,
		);
	}

	@override
	List<Object?> get props => [
				recepciones,
				busqueda,
				filtroEstado,
				verDevueltas,
				total,
				pagina,
				totalPaginas,
				cargando,
				actualizando,
				cargandoMas,
				errorListado,
				errorPaginacion,
				fechaReferencia,
			];
}
