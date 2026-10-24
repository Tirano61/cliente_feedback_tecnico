import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/pagina_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/resultado_asignacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';

/// Modulo fabrica del backend (`/fabrica/...`).
///
/// Todas las operaciones lanzan `ReglaFabricaException` cuando el backend
/// rechaza por una regla de negocio (body con `codigo`) y `ServerException`
/// ante cualquier otro error o una respuesta que no se puede leer.
///
/// En los listados, los filtros en null o vacios no se mandan.
abstract class IFabricaRepository {
	/// Componentes del modelo de la pieza, para cargar la falla.
	Future<List<Componente>> obtenerComponentes({required String productoId});

	Future<List<Causa>> obtenerCausas();

	Future<PaginaFabrica<Unidad>> buscarUnidades({
		TipoUnidad? tipo,
		EstadoUnidad? estado,
		String nroSerie = '',
		String busqueda = '',
		required int pagina,
		required int limite,
	});

	/// Si la unidad es un indicador trae sus `piezasInstaladas`.
	Future<Unidad> obtenerUnidad(String unidadId);

	Future<HistorialUnidad> obtenerHistorialUnidad(String unidadId);

	/// Pone una placa o celda en un indicador.
	Future<ResultadoAsignacion> asignarUnidad(SolicitudAsignacion solicitud);

	Future<Recepcion> crearRecepcion(NuevaRecepcion recepcion);

	Future<PaginaFabrica<Recepcion>> obtenerRecepciones({
		EstadoRecepcion? estado,
		bool? abiertas,
		String? clienteId,
		String busqueda = '',
		required int pagina,
		required int limite,
	});

	Future<Recepcion> obtenerRecepcion(String recepcionId);

	/// `estado`: `enReparacion`, `esperandoPresupuesto` o `listoParaDevolver`.
	/// `devuelto` solo se alcanza con [devolverRecepcion].
	Future<Recepcion> cambiarEstadoRecepcion({
		required String recepcionId,
		required EstadoRecepcion estado,
		String? observacion,
	});

	/// Vincula el servicio de canal fabrica que tiene diagnostico, resolucion
	/// y facturacion.
	Future<Recepcion> vincularServicioRecepcion({
		required String recepcionId,
		required String servicioId,
	});

	Future<Recepcion> devolverRecepcion({
		required String recepcionId,
		required SolicitudDevolucion solicitud,
	});

	Future<Ingreso> crearIngreso(NuevoIngreso ingreso);

	Future<PaginaFabrica<Ingreso>> obtenerIngresos({
		EstadoIngreso? estado,
		TipoUnidad? tipo,
		String busqueda = '',
		required int pagina,
		required int limite,
	});

	Future<Ingreso> obtenerIngreso(String ingresoId);

	/// Placa a desarrollo. Las celdas no se derivan.
	Future<Ingreso> derivarIngreso({
		required String ingresoId,
		String? observacion,
	});

	/// Carga o corrige la falla (solo celdas desde esta app).
	Future<Ingreso> cargarFallaIngreso({
		required String ingresoId,
		required SolicitudFalla solicitud,
	});

	/// Carga la reparacion (solo celdas desde esta app). Requiere la falla.
	Future<Ingreso> cargarReparacionIngreso({
		required String ingresoId,
		required SolicitudReparacion solicitud,
	});
}
