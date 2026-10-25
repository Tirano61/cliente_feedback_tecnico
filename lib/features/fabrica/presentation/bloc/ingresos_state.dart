import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_ingreso.dart';
import 'package:equatable/equatable.dart';

/// Listado de "Piezas ingresadas".
class IngresosState extends Equatable {
	/// Chips del filtro por tipo (null: placas y celdas).
	static const List<TipoUnidad> tiposFiltrables = [TipoUnidad.placa, TipoUnidad.celda];

	final List<Ingreso> ingresos;
	final String busqueda;

	/// null: placas y celdas.
	final TipoUnidad? filtroTipo;

	/// null: todos los estados.
	final EstadoIngreso? filtroEstado;
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

	const IngresosState({
		this.ingresos = const [],
		this.busqueda = '',
		this.filtroTipo,
		this.filtroEstado,
		this.total = 0,
		this.pagina = 0,
		this.totalPaginas = 0,
		this.cargando = false,
		this.actualizando = false,
		this.cargandoMas = false,
		this.errorListado,
		this.errorPaginacion,
	});

	bool get hayMasPaginas => pagina < totalPaginas;

	bool get hayFiltrosActivos =>
			busqueda.trim().isNotEmpty || filtroTipo != null || filtroEstado != null;

	/// Chips del filtro por estado: las celdas no pasan por desarrollo.
	List<EstadoIngreso> get estadosFiltrables => ReglasIngreso.estadosPosibles(filtroTipo);

	IngresosState copyWith({
		List<Ingreso>? ingresos,
		String? busqueda,
		TipoUnidad? filtroTipo,
		bool limpiarFiltroTipo = false,
		EstadoIngreso? filtroEstado,
		bool limpiarFiltroEstado = false,
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
	}) {
		return IngresosState(
			ingresos: ingresos ?? this.ingresos,
			busqueda: busqueda ?? this.busqueda,
			filtroTipo: limpiarFiltroTipo ? null : (filtroTipo ?? this.filtroTipo),
			filtroEstado: limpiarFiltroEstado ? null : (filtroEstado ?? this.filtroEstado),
			total: total ?? this.total,
			pagina: pagina ?? this.pagina,
			totalPaginas: totalPaginas ?? this.totalPaginas,
			cargando: cargando ?? this.cargando,
			actualizando: actualizando ?? this.actualizando,
			cargandoMas: cargandoMas ?? this.cargandoMas,
			errorListado: limpiarErrorListado ? null : (errorListado ?? this.errorListado),
			errorPaginacion:
					limpiarErrorPaginacion ? null : (errorPaginacion ?? this.errorPaginacion),
		);
	}

	@override
	List<Object?> get props => [
				ingresos,
				busqueda,
				filtroTipo,
				filtroEstado,
				total,
				pagina,
				totalPaginas,
				cargando,
				actualizando,
				cargandoMas,
				errorListado,
				errorPaginacion,
			];
}
