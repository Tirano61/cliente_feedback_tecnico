import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';

/// Traduccion entre los enums de fabrica y los codigos que usa el backend.
///
/// Leer un codigo que no se conoce da `desconocido` (o null en
/// `formaDevolucion`); mandar `desconocido` es un error de programacion.
class CodigosFabrica {
	const CodigosFabrica._();

	static const Map<TipoUnidad, String> _tiposUnidad = {
		TipoUnidad.indicador: 'indicador',
		TipoUnidad.placa: 'placa',
		TipoUnidad.celda: 'celda',
	};

	static const Map<EstadoUnidad, String> _estadosUnidad = {
		EstadoUnidad.instalada: 'instalada',
		EstadoUnidad.retirada: 'retirada',
		EstadoUnidad.enServicioTecnico: 'en_servicio_tecnico',
		EstadoUnidad.enDesarrollo: 'en_desarrollo',
		EstadoUnidad.reacondicionadaDisponible: 'reacondicionada_disponible',
		EstadoUnidad.descartada: 'descartada',
	};

	static const Map<EstadoRecepcion, String> _estadosRecepcion = {
		EstadoRecepcion.recibido: 'recibido',
		EstadoRecepcion.enReparacion: 'en_reparacion',
		EstadoRecepcion.esperandoPresupuesto: 'esperando_presupuesto',
		EstadoRecepcion.listoParaDevolver: 'listo_para_devolver',
		EstadoRecepcion.devuelto: 'devuelto',
	};

	static const Map<EstadoIngreso, String> _estadosIngreso = {
		EstadoIngreso.enServicioTecnico: 'en_servicio_tecnico',
		EstadoIngreso.derivadoDesarrollo: 'derivado_desarrollo',
		EstadoIngreso.reparado: 'reparado',
		EstadoIngreso.descartado: 'descartado',
		EstadoIngreso.devueltoAServicioTecnico: 'devuelto_a_servicio_tecnico',
	};

	static const Map<FormaDevolucion, String> _formasDevolucion = {
		FormaDevolucion.envio: 'envio',
		FormaDevolucion.retiraCliente: 'retira_cliente',
		FormaDevolucion.llevaTecnico: 'lleva_tecnico',
	};

	static const Map<ResultadoReparacion, String> _resultadosReparacion = {
		ResultadoReparacion.reparada: 'reparada',
		ResultadoReparacion.irreparable: 'irreparable',
	};

	static const Map<TipoMovimiento, String> _tiposMovimiento = {
		TipoMovimiento.alta: 'alta',
		TipoMovimiento.instalacion: 'instalacion',
		TipoMovimiento.retiro: 'retiro',
		TipoMovimiento.recepcion: 'recepcion',
		TipoMovimiento.devolucionCliente: 'devolucion_cliente',
		TipoMovimiento.ingresoFabrica: 'ingreso_fabrica',
		TipoMovimiento.derivacionDesarrollo: 'derivacion_desarrollo',
		TipoMovimiento.reparada: 'reparada',
		TipoMovimiento.descartada: 'descartada',
		TipoMovimiento.vueltaAServicioTecnico: 'vuelta_a_servicio_tecnico',
	};

	static TipoUnidad tipoUnidad(dynamic codigo) =>
			_desdeCodigo(_tiposUnidad, codigo) ?? TipoUnidad.desconocido;

	static String codigoTipoUnidad(TipoUnidad tipo) => _codigo(_tiposUnidad, tipo);

	static EstadoUnidad estadoUnidad(dynamic codigo) =>
			_desdeCodigo(_estadosUnidad, codigo) ?? EstadoUnidad.desconocido;

	static String codigoEstadoUnidad(EstadoUnidad estado) => _codigo(_estadosUnidad, estado);

	static EstadoRecepcion estadoRecepcion(dynamic codigo) =>
			_desdeCodigo(_estadosRecepcion, codigo) ?? EstadoRecepcion.desconocido;

	static String codigoEstadoRecepcion(EstadoRecepcion estado) =>
			_codigo(_estadosRecepcion, estado);

	static EstadoIngreso estadoIngreso(dynamic codigo) =>
			_desdeCodigo(_estadosIngreso, codigo) ?? EstadoIngreso.desconocido;

	static String codigoEstadoIngreso(EstadoIngreso estado) => _codigo(_estadosIngreso, estado);

	static FormaDevolucion? formaDevolucion(dynamic codigo) =>
			_desdeCodigo(_formasDevolucion, codigo);

	static String codigoFormaDevolucion(FormaDevolucion forma) =>
			_codigo(_formasDevolucion, forma);

	static ResultadoReparacion resultadoReparacion(dynamic codigo) =>
			_desdeCodigo(_resultadosReparacion, codigo) ?? ResultadoReparacion.desconocido;

	static String codigoResultadoReparacion(ResultadoReparacion resultado) =>
			_codigo(_resultadosReparacion, resultado);

	static TipoMovimiento tipoMovimiento(dynamic codigo) =>
			_desdeCodigo(_tiposMovimiento, codigo) ?? TipoMovimiento.desconocido;

	static T? _desdeCodigo<T>(Map<T, String> codigos, dynamic codigo) {
		for (final entrada in codigos.entries) {
			if (entrada.value == codigo) {
				return entrada.key;
			}
		}
		return null;
	}

	static String _codigo<T>(Map<T, String> codigos, T valor) {
		final codigo = codigos[valor];
		if (codigo == null) {
			throw ArgumentError.value(valor, 'valor', 'No tiene codigo en el backend');
		}
		return codigo;
	}
}
