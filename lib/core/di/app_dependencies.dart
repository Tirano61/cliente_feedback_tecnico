import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/repositories/i_servicio_repository.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
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

	final LoginUseCase loginUseCase;
	final ObtenerCatalogosUseCase obtenerCatalogosUseCase;
	final CargarServicioUseCase cargarServicioUseCase;
	final ObtenerMisServiciosUseCase obtenerMisServiciosUseCase;

	AppDependencies._({
		required this.secureStorage,
		required this.apiClient,
		required this.authRepository,
		required this.catalogoRepository,
		required this.servicioRepository,
		required this.loginUseCase,
		required this.obtenerCatalogosUseCase,
		required this.cargarServicioUseCase,
		required this.obtenerMisServiciosUseCase,
	});

	factory AppDependencies.create() {
		final secureStorage = SecureStorage();
		final apiClient = ApiClient(http.Client(), secureStorage);

		final authRepository = AuthRepositoryImpl(apiClient, secureStorage);
		final catalogoRepository = CatalogoRepositoryImpl(apiClient);
		final servicioRepository = ServicioRepositoryImpl(apiClient);

		return AppDependencies._(
			secureStorage: secureStorage,
			apiClient: apiClient,
			authRepository: authRepository,
			catalogoRepository: catalogoRepository,
			servicioRepository: servicioRepository,
			loginUseCase: LoginUseCase(authRepository),
			obtenerCatalogosUseCase: ObtenerCatalogosUseCase(catalogoRepository),
			cargarServicioUseCase: CargarServicioUseCase(servicioRepository),
			obtenerMisServiciosUseCase:
					ObtenerMisServiciosUseCase(servicioRepository),
		);
	}
}

