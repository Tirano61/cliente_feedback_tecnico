import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_state.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:equatable/equatable.dart';

abstract class NuevoIngresoEvent extends Equatable {
	const NuevoIngresoEvent();

	@override
	List<Object?> get props => [];
}

/// Al entrar al alta: formulario vacio. Con `recepcion` ("Ingresar pieza
/// retirada") el cliente y el indicador salen de la recepcion.
class NuevoIngresoIniciado extends NuevoIngresoEvent {
	final PrecargaIngresoRecepcion? recepcion;

	const NuevoIngresoIniciado({this.recepcion});

	@override
	List<Object?> get props => [recepcion];
}

class NuevoIngresoBuscarClienteSolicitado extends NuevoIngresoEvent {
	final String query;

	const NuevoIngresoBuscarClienteSolicitado({required this.query});

	@override
	List<Object?> get props => [query];
}

class NuevoIngresoClienteSeleccionado extends NuevoIngresoEvent {
	final Cliente cliente;

	const NuevoIngresoClienteSeleccionado({required this.cliente});

	@override
	List<Object?> get props => [cliente];
}

/// Alta rapida de cliente o sucursal (`POST /clientes`): queda creado y
/// seleccionado como origen.
class NuevoIngresoClienteRapidoSolicitado extends NuevoIngresoEvent {
	final String cuit;
	final String nombre;
	final String contacto;
	final String telefono;
	final String localidad;

	const NuevoIngresoClienteRapidoSolicitado({
		required this.cuit,
		required this.nombre,
		this.contacto = '',
		this.telefono = '',
		this.localidad = '',
	});

	@override
	List<Object?> get props => [cuit, nombre, contacto, telefono, localidad];
}

/// Solo cambian los campos que vienen; `limpiarProducto` quita el modelo.
class NuevoIngresoCambiado extends NuevoIngresoEvent {
	final TipoUnidad? tipo;
	final String? nroSerie;
	final String? productoId;
	final bool limpiarProducto;
	final String? indicadorNroSerie;
	final String? observacionTecnico;

	const NuevoIngresoCambiado({
		this.tipo,
		this.nroSerie,
		this.productoId,
		this.limpiarProducto = false,
		this.indicadorNroSerie,
		this.observacionTecnico,
	});

	@override
	List<Object?> get props => [
				tipo,
				nroSerie,
				productoId,
				limpiarProducto,
				indicadorNroSerie,
				observacionTecnico,
			];
}

/// Con recepcion: el tecnico eligio una de las piezas que figuran instaladas
/// en el indicador; completa tipo, numero de serie y modelo.
class NuevoIngresoPiezaInstaladaElegida extends NuevoIngresoEvent {
	final Unidad pieza;

	const NuevoIngresoPiezaInstaladaElegida({required this.pieza});

	@override
	List<Object?> get props => [pieza];
}

class NuevoIngresoGuardado extends NuevoIngresoEvent {
	const NuevoIngresoGuardado();
}
