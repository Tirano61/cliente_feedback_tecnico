// Valores del modulo fabrica. Los codigos que viaja el backend
// (`en_servicio_tecnico`, `retira_cliente`, ...) se traducen en
// `CodigosFabrica` (infraestructura).
//
// `desconocido` cubre un valor nuevo del backend que esta version de la app
// todavia no conoce: la pantalla lo muestra sin romper el parseo.

enum TipoUnidad { indicador, placa, celda, desconocido }

enum EstadoUnidad {
	instalada,
	retirada,
	enServicioTecnico,
	enDesarrollo,
	reacondicionadaDisponible,
	descartada,
	desconocido,
}

/// `recibido -> en_reparacion ⇄ esperando_presupuesto -> listo_para_devolver
/// -> devuelto`. `devuelto` solo se alcanza con la devolucion.
enum EstadoRecepcion {
	recibido,
	enReparacion,
	esperandoPresupuesto,
	listoParaDevolver,
	devuelto,
	desconocido,
}

enum EstadoIngreso {
	enServicioTecnico,
	derivadoDesarrollo,
	reparado,
	descartado,
	devueltoAServicioTecnico,
	desconocido,
}

enum FormaDevolucion { envio, retiraCliente, llevaTecnico }

enum ResultadoReparacion { reparada, irreparable, desconocido }

enum TipoMovimiento {
	alta,
	instalacion,
	retiro,
	recepcion,
	devolucionCliente,
	ingresoFabrica,
	derivacionDesarrollo,
	reparada,
	descartada,
	vueltaAServicioTecnico,
	desconocido,
}
