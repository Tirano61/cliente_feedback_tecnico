import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/encolar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_documentos_pendientes_use_case.dart';
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
import 'package:http/http.dart' as http;

class AppDependencies {
	final SecureStorage secureStorage;
	final ApiClient apiClient;

	final IAuthRepository authRepository;
	final ICatalogoRepository catalogoRepository;
	final IServicioRepository servicioRepository;
	final ILiquidacionRepository liquidacionRepository;

	final LoginUseCase loginUseCase;
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
	final ObtenerMisLiquidacionesUseCase obtenerMisLiquidacionesUseCase;
	final ObtenerItemsLiquidacionUseCase obtenerItemsLiquidacionUseCase;

	AppDependencies._({
		required this.secureStorage,
		required this.apiClient,
		required this.authRepository,
		required this.catalogoRepository,
		required this.servicioRepository,
		required this.liquidacionRepository,
		required this.loginUseCase,
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
		required this.obtenerMisLiquidacionesUseCase,
		required this.obtenerItemsLiquidacionUseCase,
	});

	factory AppDependencies.create() {
		final secureStorage = SecureStorage();
		final apiClient = ApiClient(http.Client(), secureStorage);

		final authRepository = AuthRepositoryImpl(apiClient, secureStorage);
		final catalogoRepository = CatalogoRepositoryImpl(apiClient);
		final servicioRepository = ServicioRepositoryImpl(apiClient, secureStorage);
		final liquidacionRemoteDataSource = LiquidacionRemoteDataSource(apiClient);
		final liquidacionRepository = LiquidacionRepositoryImpl(liquidacionRemoteDataSource);

		return AppDependencies._(
			secureStorage: secureStorage,
			apiClient: apiClient,
			authRepository: authRepository,
			catalogoRepository: catalogoRepository,
			servicioRepository: servicioRepository,
			liquidacionRepository: liquidacionRepository,
			loginUseCase: LoginUseCase(authRepository),
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
			generarPdfOrdenServicioUseCase: GenerarPdfOrdenServicioUseCase(),
			subirDocumentoFirmadoUseCase:
					SubirDocumentoFirmadoUseCase(servicioRepository),
			encolarDocumentoPendienteUseCase:
					EncolarDocumentoPendienteUseCase(servicioRepository),
			obtenerDocumentosPendientesUseCase:
					ObtenerDocumentosPendientesUseCase(servicioRepository),
			quitarDocumentoPendienteUseCase:
					QuitarDocumentoPendienteUseCase(servicioRepository),
			obtenerMisLiquidacionesUseCase:
					ObtenerMisLiquidacionesUseCase(liquidacionRepository),
			obtenerItemsLiquidacionUseCase:
					ObtenerItemsLiquidacionUseCase(liquidacionRepository),
		);
	}
}

