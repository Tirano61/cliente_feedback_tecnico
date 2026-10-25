import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:equatable/equatable.dart';

/// La recepcion desde la que se ingresa la pieza ("Ingresar pieza retirada").
/// El backend toma de ahi el cliente, el indicador y el servicio.
class PrecargaIngresoRecepcion extends Equatable {
	final String recepcionId;
	final int numero;
	final String clienteNombre;
	final String indicadorNroSerie;

	/// Placas y celdas que figuran en el indicador, para elegir la que se saco.
	final List<Unidad> piezasInstaladas;

	const PrecargaIngresoRecepcion({
		required this.recepcionId,
		required this.numero,
		required this.clienteNombre,
		required this.indicadorNroSerie,
		this.piezasInstaladas = const [],
	});

	@override
	List<Object?> get props => [
				recepcionId,
				numero,
				clienteNombre,
				indicadorNroSerie,
				piezasInstaladas,
			];
}

/// La pieza ya tiene un ingreso abierto (`INGRESO_ABIERTO`).
class IngresoAbiertoExistente extends Equatable {
	final String ingresoId;
	final int? numero;
	final String mensaje;

	const IngresoAbiertoExistente({
		required this.ingresoId,
		this.numero,
		required this.mensaje,
	});

	@override
	List<Object?> get props => [ingresoId, numero, mensaje];
}

class NuevoIngresoState extends Equatable {
	/// Tipos que se pueden ingresar (el indicador entra con la recepcion).
	static const List<TipoUnidad> tiposIngresables = [TipoUnidad.placa, TipoUnidad.celda];

	final PrecargaIngresoRecepcion? recepcion;
	final TipoUnidad? tipo;
	final String nroSerie;
	final String? productoId;

	/// Sin recepcion: de que cliente o sucursal viene.
	final Cliente? clienteOrigen;
	final List<Cliente> clientesEncontrados;
	final bool buscandoClientes;

	/// Sin recepcion: indicador del que salio (opcional).
	final String indicadorNroSerie;
	final String observacionTecnico;
	final bool guardando;
	final bool creandoCliente;

	/// Por que no se pudo dar de alta el cliente. Lo muestra el dialogo del
	/// alta, que queda abierto con lo cargado; se limpia al reintentar.
	final String? errorAltaCliente;

	/// Efectos de un solo uso: no se arrastran al siguiente emit.
	final String? errorMensaje;
	final Ingreso? ingresoCreado;
	final IngresoAbiertoExistente? ingresoAbierto;
	final Cliente? clienteCreado;

	const NuevoIngresoState({
		this.recepcion,
		this.tipo,
		this.nroSerie = '',
		this.productoId,
		this.clienteOrigen,
		this.clientesEncontrados = const [],
		this.buscandoClientes = false,
		this.indicadorNroSerie = '',
		this.observacionTecnico = '',
		this.guardando = false,
		this.creandoCliente = false,
		this.errorAltaCliente,
		this.errorMensaje,
		this.ingresoCreado,
		this.ingresoAbierto,
		this.clienteCreado,
	});

	bool get conRecepcion => recepcion != null;

	/// Con que palabra se buscan en el catalogo los modelos del tipo elegido
	/// (null: todavia no se eligio el tipo).
	String? get palabraModelo {
		return switch (tipo) {
			TipoUnidad.placa => 'placa',
			TipoUnidad.celda => 'celda',
			_ => null,
		};
	}

	/// Piezas del indicador de la recepcion que se pueden ingresar.
	List<Unidad> get piezasInstaladas {
		final piezas = recepcion?.piezasInstaladas ?? const <Unidad>[];
		return piezas.where((p) => tiposIngresables.contains(p.tipo)).toList();
	}

	NuevoIngresoState copyWith({
		TipoUnidad? tipo,
		String? nroSerie,
		String? productoId,
		bool limpiarProducto = false,
		Cliente? clienteOrigen,
		List<Cliente>? clientesEncontrados,
		bool? buscandoClientes,
		String? indicadorNroSerie,
		String? observacionTecnico,
		bool? guardando,
		bool? creandoCliente,
		String? errorAltaCliente,
		bool limpiarErrorAltaCliente = false,
		String? errorMensaje,
		Ingreso? ingresoCreado,
		IngresoAbiertoExistente? ingresoAbierto,
		Cliente? clienteCreado,
	}) {
		return NuevoIngresoState(
			recepcion: recepcion,
			tipo: tipo ?? this.tipo,
			nroSerie: nroSerie ?? this.nroSerie,
			productoId: limpiarProducto ? null : (productoId ?? this.productoId),
			clienteOrigen: clienteOrigen ?? this.clienteOrigen,
			clientesEncontrados: clientesEncontrados ?? this.clientesEncontrados,
			buscandoClientes: buscandoClientes ?? this.buscandoClientes,
			indicadorNroSerie: indicadorNroSerie ?? this.indicadorNroSerie,
			observacionTecnico: observacionTecnico ?? this.observacionTecnico,
			guardando: guardando ?? this.guardando,
			creandoCliente: creandoCliente ?? this.creandoCliente,
			errorAltaCliente:
					limpiarErrorAltaCliente ? null : (errorAltaCliente ?? this.errorAltaCliente),
			errorMensaje: errorMensaje,
			ingresoCreado: ingresoCreado,
			ingresoAbierto: ingresoAbierto,
			clienteCreado: clienteCreado,
		);
	}

	@override
	List<Object?> get props => [
				recepcion,
				tipo,
				nroSerie,
				productoId,
				clienteOrigen,
				clientesEncontrados,
				buscandoClientes,
				indicadorNroSerie,
				observacionTecnico,
				guardando,
				creandoCliente,
				errorAltaCliente,
				errorMensaje,
				ingresoCreado,
				ingresoAbierto,
				clienteCreado,
			];
}
