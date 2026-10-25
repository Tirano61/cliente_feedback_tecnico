import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:equatable/equatable.dart';

/// Pestaña "Piezas": busqueda por numero de serie y atajo de placas
/// reacondicionadas disponibles.
class PiezasState extends Equatable {
	final List<Unidad> piezas;
	final String busqueda;

	/// Atajo "Placas reacondicionadas disponibles"
	/// (`tipo=placa&estado=reacondicionada_disponible`).
	final bool soloReacondicionadas;
	final int total;
	final int pagina;
	final int totalPaginas;

	/// Primera carga: todavia no hay listado que mostrar.
	final bool cargando;

	/// Consulta nueva (busqueda, atajo, refresco) con el listado a la vista.
	final bool actualizando;
	final bool cargandoMas;
	final String? errorListado;
	final String? errorPaginacion;

	const PiezasState({
		this.piezas = const [],
		this.busqueda = '',
		this.soloReacondicionadas = false,
		this.total = 0,
		this.pagina = 0,
		this.totalPaginas = 0,
		this.cargando = false,
		this.actualizando = false,
		this.cargandoMas = false,
		this.errorListado,
		this.errorPaginacion,
	});

	/// Sin numero de serie ni atajo no se lista nada: hay que buscar.
	bool get hayConsulta => busqueda.trim().isNotEmpty || soloReacondicionadas;

	bool get hayMasPaginas => pagina < totalPaginas;

	/// Que mostrar cuando el listado esta vacio.
	String get textoVacio {
		if (!hayConsulta) {
			return 'Buscá una pieza por número de serie o mirá las placas '
					'reacondicionadas disponibles.';
		}
		if (actualizando) {
			return 'Buscando piezas...';
		}
		final busquedaLimpia = busqueda.trim();
		if (soloReacondicionadas) {
			return busquedaLimpia.isEmpty
					? 'No hay placas reacondicionadas disponibles.'
					: 'No hay placas reacondicionadas disponibles con "$busquedaLimpia".';
		}
		return 'No se encontraron piezas con "$busquedaLimpia".';
	}

	PiezasState copyWith({
		List<Unidad>? piezas,
		String? busqueda,
		bool? soloReacondicionadas,
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
		return PiezasState(
			piezas: piezas ?? this.piezas,
			busqueda: busqueda ?? this.busqueda,
			soloReacondicionadas: soloReacondicionadas ?? this.soloReacondicionadas,
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
				piezas,
				busqueda,
				soloReacondicionadas,
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
