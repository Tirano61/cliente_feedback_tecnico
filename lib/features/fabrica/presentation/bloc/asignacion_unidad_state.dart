import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/resultado_asignacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:equatable/equatable.dart';

/// La recepcion desde la que se pone la pieza ("Poner placa/celda"): el
/// indicador al que va y la recepcion que queda en el historial.
class PrecargaAsignacionRecepcion extends Equatable {
	final String recepcionId;
	final int numero;
	final String clienteNombre;
	final String indicadorId;
	final String indicadorNroSerie;

	/// Placas y celdas que figuran en el indicador, para elegir la que sale.
	final List<Unidad> piezasInstaladas;

	const PrecargaAsignacionRecepcion({
		required this.recepcionId,
		required this.numero,
		required this.clienteNombre,
		required this.indicadorId,
		required this.indicadorNroSerie,
		this.piezasInstaladas = const [],
	});

	@override
	List<Object?> get props => [
				recepcionId,
				numero,
				clienteNombre,
				indicadorId,
				indicadorNroSerie,
				piezasInstaladas,
			];
}

class AsignacionUnidadState extends Equatable {
	/// Lo que se pone en un indicador (el indicador no).
	static const List<TipoUnidad> tiposAsignables = [TipoUnidad.placa, TipoUnidad.celda];

	final PrecargaAsignacionRecepcion? precarga;

	/// Piezas del indicador. Arrancan con las de la recepcion y se vuelven a
	/// pedir si el backend dice que cambiaron.
	final List<Unidad> piezasInstaladas;

	final TipoUnidad? tipo;

	/// La pieza que se pone: nueva (se registra con este numero) o una
	/// reacondicionada disponible.
	final String nroSerie;
	final String? productoId;

	/// La que se saca. Vacia: en placa sale la que tenia el indicador; en
	/// celda no sale ninguna.
	final String retiradaNroSerie;
	final String observacion;

	/// Reacondicionadas disponibles del tipo elegido, para elegir de la lista.
	final List<Unidad> reacondicionadas;
	final int totalReacondicionadas;
	final bool cargandoReacondicionadas;
	final String? errorReacondicionadas;

	final bool guardando;

	/// Por que el backend rechazo la asignacion, tal cual. Queda a la vista
	/// con todo lo cargado hasta el proximo intento.
	final String? errorAsignacion;

	/// La pieza quedo puesta: instalada y retiradas.
	final ResultadoAsignacion? resultado;

	/// Aviso de un solo uso (validacion antes de llamar al backend).
	final String? errorMensaje;

	const AsignacionUnidadState({
		this.precarga,
		this.piezasInstaladas = const [],
		this.tipo,
		this.nroSerie = '',
		this.productoId,
		this.retiradaNroSerie = '',
		this.observacion = '',
		this.reacondicionadas = const [],
		this.totalReacondicionadas = 0,
		this.cargandoReacondicionadas = false,
		this.errorReacondicionadas,
		this.guardando = false,
		this.errorAsignacion,
		this.resultado,
		this.errorMensaje,
	});

	bool get asignada => resultado != null;

	/// Con que palabra se buscan en el catalogo los modelos del tipo elegido
	/// (null: todavia no se eligio el tipo).
	String? get palabraModelo {
		return switch (tipo) {
			TipoUnidad.placa => 'placa',
			TipoUnidad.celda => 'celda',
			_ => null,
		};
	}

	/// Piezas del indicador del tipo elegido: entre ellas se elige la que sale.
	List<Unidad> get piezasParaRetirar {
		final elegido = tipo;
		return elegido == null
				? const []
				: piezasInstaladas.where((p) => p.tipo == elegido).toList();
	}

	/// La reacondicionada de la lista que coincide con el numero cargado.
	Unidad? get reacondicionadaElegida {
		final buscado = normalizarSerie(nroSerie);
		if (buscado.isEmpty) {
			return null;
		}
		return reacondicionadas.where((u) => normalizarSerie(u.nroSerie) == buscado).firstOrNull;
	}

	/// Hay mas reacondicionadas que las que se muestran.
	bool get hayMasReacondicionadas => totalReacondicionadas > reacondicionadas.length;

	/// Que pasa si no se elige la pieza que sale.
	String? get avisoRetirada {
		final elegido = tipo;
		if (elegido == null || retiradaNroSerie.trim().isNotEmpty) {
			return null;
		}
		if (elegido == TipoUnidad.celda) {
			return 'Si no elegís ninguna, la celda se agrega sin sacar otra.';
		}
		final actuales = piezasParaRetirar;
		if (actuales.isEmpty) {
			return 'El indicador no tiene una placa registrada: no sale ninguna.';
		}
		return 'Si no elegís, sale la placa que tiene el indicador '
				'(${actuales.map((p) => p.nroSerie).join(', ')}).';
	}

	/// Debajo de la lista de reacondicionadas: si no hay o si hay mas que las
	/// que se muestran.
	String? get avisoReacondicionadas {
		final elegido = tipo;
		if (elegido == null || cargandoReacondicionadas || errorReacondicionadas != null) {
			return null;
		}
		final plural = elegido == TipoUnidad.placa ? 'placas' : 'celdas';
		if (reacondicionadas.isEmpty) {
			return 'No hay $plural reacondicionadas disponibles: cargá el número de serie de la nueva.';
		}
		if (hayMasReacondicionadas) {
			return 'Se muestran ${reacondicionadas.length} de $totalReacondicionadas: '
					'si no está en la lista, escribí su número de serie.';
		}
		return null;
	}

	/// Que quedo puesto, para el resultado.
	String? get textoInstalada {
		final actual = resultado;
		if (actual == null) {
			return null;
		}
		final pieza = actual.instalada;
		return '${nombreTipoUnidad(pieza.tipo)} ${pieza.nroSerie} puesta en el indicador '
				'${actual.indicador.nroSerie}.';
	}

	/// Que salio del indicador, para el resultado.
	List<String> get textosRetiradas {
		final actual = resultado;
		if (actual == null) {
			return const [];
		}
		return actual.retiradas
				.map((p) => '${nombreTipoUnidad(p.tipo)} ${p.nroSerie}')
				.toList();
	}

	/// Texto del boton de la pieza que se pone.
	String get etiquetaGuardar {
		final elegido = tipo;
		return elegido == null ? 'Poner pieza' : 'Poner ${nombreTipoUnidad(elegido).toLowerCase()}';
	}

	/// `errorMensaje` no se arrastra: vale para un emit.
	AsignacionUnidadState copyWith({
		List<Unidad>? piezasInstaladas,
		TipoUnidad? tipo,
		String? nroSerie,
		String? productoId,
		bool limpiarProducto = false,
		String? retiradaNroSerie,
		String? observacion,
		List<Unidad>? reacondicionadas,
		int? totalReacondicionadas,
		bool? cargandoReacondicionadas,
		String? errorReacondicionadas,
		bool limpiarErrorReacondicionadas = false,
		bool? guardando,
		String? errorAsignacion,
		bool limpiarErrorAsignacion = false,
		ResultadoAsignacion? resultado,
		String? errorMensaje,
	}) {
		return AsignacionUnidadState(
			precarga: precarga,
			piezasInstaladas: piezasInstaladas ?? this.piezasInstaladas,
			tipo: tipo ?? this.tipo,
			nroSerie: nroSerie ?? this.nroSerie,
			productoId: limpiarProducto ? null : (productoId ?? this.productoId),
			retiradaNroSerie: retiradaNroSerie ?? this.retiradaNroSerie,
			observacion: observacion ?? this.observacion,
			reacondicionadas: reacondicionadas ?? this.reacondicionadas,
			totalReacondicionadas: totalReacondicionadas ?? this.totalReacondicionadas,
			cargandoReacondicionadas: cargandoReacondicionadas ?? this.cargandoReacondicionadas,
			errorReacondicionadas: limpiarErrorReacondicionadas
					? null
					: (errorReacondicionadas ?? this.errorReacondicionadas),
			guardando: guardando ?? this.guardando,
			errorAsignacion:
					limpiarErrorAsignacion ? null : (errorAsignacion ?? this.errorAsignacion),
			resultado: resultado ?? this.resultado,
			errorMensaje: errorMensaje,
		);
	}

	@override
	List<Object?> get props => [
				precarga,
				piezasInstaladas,
				tipo,
				nroSerie,
				productoId,
				retiradaNroSerie,
				observacion,
				reacondicionadas,
				totalReacondicionadas,
				cargandoReacondicionadas,
				errorReacondicionadas,
				guardando,
				errorAsignacion,
				resultado,
				errorMensaje,
			];
}

/// El backend guarda los numeros de serie sin espacios en los extremos y en
/// mayusculas.
String normalizarSerie(String nroSerie) => nroSerie.trim().toUpperCase();
