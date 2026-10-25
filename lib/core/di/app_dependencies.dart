import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/cerrar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/restaurar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/descargar_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/encolar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_servicio_guardado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cliente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_documentos_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_enlace_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/quitar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/subir_documento_firmado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/application/obtener_items_liquidacion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/application/obtener_mis_liquidaciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/repositories/i_liquidacion_repository.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/infrastructure/datasources/liquidacion_remote_data_source.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/infrastructure/repositories/liquidacion_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/repositories/i_catalogo_repository.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_componentes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_causas_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_historial_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepciones_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cambiar_estado_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/vincular_servicio_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/devolver_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingresos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/derivar_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_falla_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/cargar_reparacion_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/recibir_de_desarrollo_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_servicio_vinculado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_vinculaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_vinculacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:http/http.dart' as http;

class AppDependencies {
	final SecureStorage secureStorage;
	final ApiClient apiClient;

	final IAuthRepository authRepository;
	final ICatalogoRepository catalogoRepository;
	final IServicioRepository servicioRepository;
	final ILiquidacionRepository liquidacionRepository;
	final IFabricaRepository fabricaRepository;

	final LoginUseCase loginUseCase;
	final RestaurarSesionUseCase restaurarSesionUseCase;
	final CerrarSesionUseCase cerrarSesionUseCase;
	final ObtenerCatalogosUseCase obtenerCatalogosUseCase;
	final CargarServicioUseCase cargarServicioUseCase;
	final ObtenerMisServiciosUseCase obtenerMisServiciosUseCase;
	final BuscarClientesUseCase buscarClientesUseCase;
	final CrearClienteRapidoUseCase crearClienteRapidoUseCase;
	final ObtenerCotizacionActualUseCase obtenerCotizacionActualUseCase;
	final BuscarRepuestosUseCase buscarRepuestosUseCase;
	final GenerarPdfOrdenServicioUseCase generarPdfOrdenServicioUseCase;
	final SubirDocumentoFirmadoUseCase subirDocumentoFirmadoUseCase;
	final EncolarDocumentoPendienteUseCase encolarDocumentoPendienteUseCase;
	final ObtenerDocumentosPendientesUseCase obtenerDocumentosPendientesUseCase;
	final QuitarDocumentoPendienteUseCase quitarDocumentoPendienteUseCase;
	final ObtenerEnlacePdfDocumentoUseCase obtenerEnlacePdfDocumentoUseCase;
	final DescargarPdfDocumentoUseCase descargarPdfDocumentoUseCase;
	final ObtenerClienteUseCase obtenerClienteUseCase;
	final GenerarPdfServicioGuardadoUseCase generarPdfServicioGuardadoUseCase;
	final ObtenerMisLiquidacionesUseCase obtenerMisLiquidacionesUseCase;
	final ObtenerItemsLiquidacionUseCase obtenerItemsLiquidacionUseCase;
	final ObtenerComponentesUseCase obtenerComponentesUseCase;
	final ObtenerCausasUseCase obtenerCausasUseCase;
	final BuscarUnidadesUseCase buscarUnidadesUseCase;
	final ObtenerUnidadUseCase obtenerUnidadUseCase;
	final ObtenerHistorialUnidadUseCase obtenerHistorialUnidadUseCase;
	final AsignarUnidadUseCase asignarUnidadUseCase;
	final CrearRecepcionUseCase crearRecepcionUseCase;
	final ObtenerRecepcionesUseCase obtenerRecepcionesUseCase;
	final ObtenerRecepcionUseCase obtenerRecepcionUseCase;
	final CambiarEstadoRecepcionUseCase cambiarEstadoRecepcionUseCase;
	final VincularServicioRecepcionUseCase vincularServicioRecepcionUseCase;
	final DevolverRecepcionUseCase devolverRecepcionUseCase;
	final CrearIngresoUseCase crearIngresoUseCase;
	final ObtenerIngresosUseCase obtenerIngresosUseCase;
	final ObtenerIngresoUseCase obtenerIngresoUseCase;
	final DerivarIngresoUseCase derivarIngresoUseCase;
	final CargarFallaIngresoUseCase cargarFallaIngresoUseCase;
	final CargarReparacionIngresoUseCase cargarReparacionIngresoUseCase;
	final RecibirDeDesarrolloUseCase recibirDeDesarrolloUseCase;
	final ObtenerServicioVinculadoUseCase obtenerServicioVinculadoUseCase;
	final GuardarVinculacionPendienteUseCase guardarVinculacionPendienteUseCase;
	final ObtenerVinculacionesPendientesUseCase obtenerVinculacionesPendientesUseCase;
	final QuitarVinculacionPendienteUseCase quitarVinculacionPendienteUseCase;

	AppDependencies._({
		required this.secureStorage,
		required this.apiClient,
		required this.authRepository,
		required this.catalogoRepository,
		required this.servicioRepository,
		required this.liquidacionRepository,
		required this.fabricaRepository,
		required this.loginUseCase,
		required this.restaurarSesionUseCase,
		required this.cerrarSesionUseCase,
		required this.obtenerCatalogosUseCase,
		required this.cargarServicioUseCase,
		required this.obtenerMisServiciosUseCase,
		required this.buscarClientesUseCase,
		required this.crearClienteRapidoUseCase,
		required this.obtenerCotizacionActualUseCase,
		required this.buscarRepuestosUseCase,
		required this.generarPdfOrdenServicioUseCase,
		required this.subirDocumentoFirmadoUseCase,
		required this.encolarDocumentoPendienteUseCase,
		required this.obtenerDocumentosPendientesUseCase,
		required this.quitarDocumentoPendienteUseCase,
		required this.obtenerEnlacePdfDocumentoUseCase,
		required this.descargarPdfDocumentoUseCase,
		required this.obtenerClienteUseCase,
		required this.generarPdfServicioGuardadoUseCase,
		required this.obtenerMisLiquidacionesUseCase,
		required this.obtenerItemsLiquidacionUseCase,
		required this.obtenerComponentesUseCase,
		required this.obtenerCausasUseCase,
		required this.buscarUnidadesUseCase,
		required this.obtenerUnidadUseCase,
		required this.obtenerHistorialUnidadUseCase,
		required this.asignarUnidadUseCase,
		required this.crearRecepcionUseCase,
		required this.obtenerRecepcionesUseCase,
		required this.obtenerRecepcionUseCase,
		required this.cambiarEstadoRecepcionUseCase,
		required this.vincularServicioRecepcionUseCase,
		required this.devolverRecepcionUseCase,
		required this.crearIngresoUseCase,
		required this.obtenerIngresosUseCase,
		required this.obtenerIngresoUseCase,
		required this.derivarIngresoUseCase,
		required this.cargarFallaIngresoUseCase,
		required this.cargarReparacionIngresoUseCase,
		required this.recibirDeDesarrolloUseCase,
		required this.obtenerServicioVinculadoUseCase,
		required this.guardarVinculacionPendienteUseCase,
		required this.obtenerVinculacionesPendientesUseCase,
		required this.quitarVinculacionPendienteUseCase,
	});

	factory AppDependencies.create() {
		final secureStorage = SecureStorage();
		final apiClient = ApiClient(http.Client(), secureStorage);

		final authRepository = AuthRepositoryImpl(apiClient, secureStorage);
		final catalogoRepository = CatalogoRepositoryImpl(apiClient);
		final servicioRepository = ServicioRepositoryImpl(apiClient, secureStorage);
		final liquidacionRemoteDataSource = LiquidacionRemoteDataSource(apiClient);
		final liquidacionRepository = LiquidacionRepositoryImpl(liquidacionRemoteDataSource);
		final fabricaRepository = FabricaRepositoryImpl(apiClient, secureStorage);
		final generarPdfOrdenServicioUseCase = GenerarPdfOrdenServicioUseCase();

		return AppDependencies._(
			secureStorage: secureStorage,
			apiClient: apiClient,
			authRepository: authRepository,
			catalogoRepository: catalogoRepository,
			servicioRepository: servicioRepository,
			liquidacionRepository: liquidacionRepository,
			fabricaRepository: fabricaRepository,
			loginUseCase: LoginUseCase(authRepository),
			restaurarSesionUseCase: RestaurarSesionUseCase(authRepository),
			cerrarSesionUseCase: CerrarSesionUseCase(authRepository),
			obtenerCatalogosUseCase: ObtenerCatalogosUseCase(catalogoRepository),
			cargarServicioUseCase: CargarServicioUseCase(servicioRepository),
			obtenerMisServiciosUseCase:
					ObtenerMisServiciosUseCase(servicioRepository),
			buscarClientesUseCase: BuscarClientesUseCase(servicioRepository),
			crearClienteRapidoUseCase:
					CrearClienteRapidoUseCase(servicioRepository),
			obtenerCotizacionActualUseCase:
					ObtenerCotizacionActualUseCase(servicioRepository),
			buscarRepuestosUseCase: BuscarRepuestosUseCase(servicioRepository),
			generarPdfOrdenServicioUseCase: generarPdfOrdenServicioUseCase,
			subirDocumentoFirmadoUseCase:
					SubirDocumentoFirmadoUseCase(servicioRepository),
			encolarDocumentoPendienteUseCase:
					EncolarDocumentoPendienteUseCase(servicioRepository),
			obtenerDocumentosPendientesUseCase:
					ObtenerDocumentosPendientesUseCase(servicioRepository),
			quitarDocumentoPendienteUseCase:
					QuitarDocumentoPendienteUseCase(servicioRepository),
			obtenerEnlacePdfDocumentoUseCase:
					ObtenerEnlacePdfDocumentoUseCase(servicioRepository),
			descargarPdfDocumentoUseCase:
					DescargarPdfDocumentoUseCase(servicioRepository),
			obtenerClienteUseCase: ObtenerClienteUseCase(servicioRepository),
			generarPdfServicioGuardadoUseCase: GenerarPdfServicioGuardadoUseCase(
				servicioRepository,
				generarPdfOrdenServicioUseCase,
			),
			obtenerMisLiquidacionesUseCase:
					ObtenerMisLiquidacionesUseCase(liquidacionRepository),
			obtenerItemsLiquidacionUseCase:
					ObtenerItemsLiquidacionUseCase(liquidacionRepository),
			obtenerComponentesUseCase: ObtenerComponentesUseCase(fabricaRepository),
			obtenerCausasUseCase: ObtenerCausasUseCase(fabricaRepository),
			buscarUnidadesUseCase: BuscarUnidadesUseCase(fabricaRepository),
			obtenerUnidadUseCase: ObtenerUnidadUseCase(fabricaRepository),
			obtenerHistorialUnidadUseCase: ObtenerHistorialUnidadUseCase(fabricaRepository),
			asignarUnidadUseCase: AsignarUnidadUseCase(fabricaRepository),
			crearRecepcionUseCase: CrearRecepcionUseCase(fabricaRepository),
			obtenerRecepcionesUseCase: ObtenerRecepcionesUseCase(fabricaRepository),
			obtenerRecepcionUseCase: ObtenerRecepcionUseCase(fabricaRepository),
			cambiarEstadoRecepcionUseCase: CambiarEstadoRecepcionUseCase(fabricaRepository),
			vincularServicioRecepcionUseCase: VincularServicioRecepcionUseCase(fabricaRepository),
			devolverRecepcionUseCase: DevolverRecepcionUseCase(fabricaRepository),
			crearIngresoUseCase: CrearIngresoUseCase(fabricaRepository),
			obtenerIngresosUseCase: ObtenerIngresosUseCase(fabricaRepository),
			obtenerIngresoUseCase: ObtenerIngresoUseCase(fabricaRepository),
			derivarIngresoUseCase: DerivarIngresoUseCase(fabricaRepository),
			cargarFallaIngresoUseCase: CargarFallaIngresoUseCase(fabricaRepository),
			cargarReparacionIngresoUseCase: CargarReparacionIngresoUseCase(fabricaRepository),
			recibirDeDesarrolloUseCase: RecibirDeDesarrolloUseCase(fabricaRepository),
			obtenerServicioVinculadoUseCase: ObtenerServicioVinculadoUseCase(fabricaRepository),
			guardarVinculacionPendienteUseCase: GuardarVinculacionPendienteUseCase(fabricaRepository),
			obtenerVinculacionesPendientesUseCase: ObtenerVinculacionesPendientesUseCase(fabricaRepository),
			quitarVinculacionPendienteUseCase: QuitarVinculacionPendienteUseCase(fabricaRepository),
		);
	}
}

