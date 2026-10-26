import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/asignacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/resultado_asignacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_state.dart'
		show normalizarSerie;
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:equatable/equatable.dart';

// "Cambio de placa/celda" del servicio de campo: lo que se carga en el
// formulario y lo que paso con cada cambio al guardar. Cada cambio se
// registra con `POST /fabrica/unidades/asignaciones` en el indicador del
// equipo del formulario.

/// Un cambio cargado en el formulario: la pieza que se pone (nueva o una
/// reacondicionada disponible) y, opcional, la que se saca.
class CambioPiezaFormulario extends Equatable {
	/// Lo que se pone en un indicador.
	static const List<TipoUnidad> tipos = [TipoUnidad.placa, TipoUnidad.celda];

	/// Identifica la fila en el formulario (no viaja al backend).
	final int id;
	final TipoUnidad tipo;
	final String nroSerie;
	final String? productoId;

	/// Vacia: en placa sale la que tenia el indicador; en celda no sale ninguna.
	final String retiradaNroSerie;

	const CambioPiezaFormulario({
		required this.id,
		required this.tipo,
		this.nroSerie = '',
		this.productoId,
		this.retiradaNroSerie = '',
	});

	/// Con que palabra se buscan en el catalogo los modelos del tipo.
	String get palabraModelo => tipo == TipoUnidad.placa ? 'placa' : 'celda';

	String get nombreTipo => nombreTipoUnidad(tipo).toLowerCase();

	/// La pieza que se pone es esa reacondicionada.
	bool usa(Unidad unidad) {
		final serie = normalizarSerie(nroSerie);
		return serie.isNotEmpty && serie == normalizarSerie(unidad.nroSerie);
	}

	/// Que pasa si no se carga la pieza que se saca.
	String get avisoRetirada {
		return tipo == TipoUnidad.placa
				? 'Si no la cargás, sale la placa que tenía el indicador.'
				: 'Si no la cargás, la celda se agrega sin sacar otra.';
	}

	CambioPiezaFormulario copyWith({
		TipoUnidad? tipo,
		String? nroSerie,
		String? productoId,
		bool limpiarProducto = false,
		String? retiradaNroSerie,
	}) {
		return CambioPiezaFormulario(
			id: id,
			tipo: tipo ?? this.tipo,
			nroSerie: nroSerie ?? this.nroSerie,
			productoId: limpiarProducto ? null : (productoId ?? this.productoId),
			retiradaNroSerie: retiradaNroSerie ?? this.retiradaNroSerie,
		);
	}

	@override
	List<Object?> get props => [id, tipo, nroSerie, productoId, retiradaNroSerie];
}

/// Reacondicionadas disponibles de un tipo, para elegir la que se pone.
class ReacondicionadasPieza extends Equatable {
	final List<Unidad> unidades;
	final int total;
	final bool cargando;
	final String? error;

	const ReacondicionadasPieza({
		this.unidades = const [],
		this.total = 0,
		this.cargando = false,
		this.error,
	});

	const ReacondicionadasPieza.cargando() : this(cargando: true);

	/// Debajo de la lista: si no hay o si hay mas que las que se muestran.
	String? aviso(TipoUnidad tipo) {
		if (cargando || error != null) {
			return null;
		}
		final plural = tipo == TipoUnidad.placa ? 'placas' : 'celdas';
		if (unidades.isEmpty) {
			return 'No hay $plural reacondicionadas disponibles: cargá el número de serie de la nueva.';
		}
		if (total > unidades.length) {
			return 'Se muestran ${unidades.length} de $total: si no está en la lista, escribí su número de serie.';
		}
		return null;
	}

	@override
	List<Object?> get props => [unidades, total, cargando, error];
}

/// Que paso con un cambio al guardar el servicio (o al reintentarlo).
class ResultadoCambioPieza extends Equatable {
	final SolicitudAsignacion solicitud;

	/// La respuesta del backend si quedo registrado en este intento.
	final ResultadoAsignacion? asignacion;

	/// El `mensaje` del backend si no se pudo: quedo pendiente en el
	/// dispositivo. Sin `asignacion` ni `error`, ya figuraba registrado (un
	/// intento anterior llego al backend aunque no su respuesta).
	final String? error;

	const ResultadoCambioPieza({required this.solicitud, this.asignacion, this.error});

	bool get pendiente => error != null;

	String get clave => AsignacionPendiente(solicitud: solicitud).clave;

	String get textoPieza => '${nombreTipoUnidad(solicitud.tipo)} ${solicitud.nroSerie}';

	String get texto {
		if (pendiente) {
			return '$textoPieza: no quedó registrada.';
		}
		final indicador = asignacion?.indicador.nroSerie ?? solicitud.indicadorNroSerie;
		return asignacion == null
				? '$textoPieza ya figuraba puesta en el indicador $indicador.'
				: '$textoPieza puesta en el indicador $indicador.';
	}

	/// Lo que salio del indicador.
	List<String> get textosRetiradas {
		return (asignacion?.retiradas ?? const <Unidad>[])
				.map((p) => '${nombreTipoUnidad(p.tipo)} ${p.nroSerie}')
				.toList();
	}

	@override
	List<Object?> get props => [solicitud, asignacion, error];
}

/// Los cambios del ultimo servicio guardado. Queda a la vista en el aviso de
/// exito para reintentar los que no se registraron.
class ResultadoCambiosPieza extends Equatable {
	static const String recordatorioRetiradas =
			'La pieza que sale queda retirada. Cuando la lleves a fábrica, dale ingreso '
			'desde Fábrica › Piezas ingresadas.';

	final String servicioId;
	final List<ResultadoCambioPieza> cambios;
	final bool reintentando;

	const ResultadoCambiosPieza({
		required this.servicioId,
		required this.cambios,
		this.reintentando = false,
	});

	int get pendientes => cambios.where((c) => c.pendiente).length;

	bool get hayRetiradas => cambios.any((c) => c.textosRetiradas.isNotEmpty);

	/// Reemplaza los cambios que se volvieron a intentar.
	ResultadoCambiosPieza conReintentos(List<ResultadoCambioPieza> reintentos) {
		final porClave = {for (final r in reintentos) r.clave: r};
		return ResultadoCambiosPieza(
			servicioId: servicioId,
			cambios: cambios.map((c) => porClave[c.clave] ?? c).toList(),
		);
	}

	ResultadoCambiosPieza copyWith({bool? reintentando}) {
		return ResultadoCambiosPieza(
			servicioId: servicioId,
			cambios: cambios,
			reintentando: reintentando ?? this.reintentando,
		);
	}

	@override
	List<Object?> get props => [servicioId, cambios, reintentando];
}

/// Como se lista un cambio pendiente en Mis servicios.
String descripcionAsignacionPendiente(AsignacionPendiente pendiente) {
	final solicitud = pendiente.solicitud;
	return '${nombreTipoUnidad(solicitud.tipo)} ${solicitud.nroSerie} '
			'en el indicador ${solicitud.indicadorNroSerie}';
}
