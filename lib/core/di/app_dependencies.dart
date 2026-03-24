import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/casos/application/cargar_caso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/casos/application/obtener_mis_casos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/repositories/i_caso_repository.dart';
import 'package:cliente_feedback_tecnico/features/casos/infrastructure/repositories/caso_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/application/obtener_catalogos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/repositories/i_catalogo_repository.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart';
import 'package:http/http.dart' as http;

class AppDependencies {
	final SecureStorage secureStorage;
	final ApiClient apiClient;

	final IAuthRepository authRepository;
	final ICatalogoRepository catalogoRepository;
	final ICasoRepository casoRepository;

	final LoginUseCase loginUseCase;
	final ObtenerCatalogosUseCase obtenerCatalogosUseCase;
	final CargarCasoUseCase cargarCasoUseCase;
	final ObtenerMisCasosUseCase obtenerMisCasosUseCase;

	AppDependencies._({
		required this.secureStorage,
		required this.apiClient,
		required this.authRepository,
		required this.catalogoRepository,
		required this.casoRepository,
		required this.loginUseCase,
		required this.obtenerCatalogosUseCase,
		required this.cargarCasoUseCase,
		required this.obtenerMisCasosUseCase,
	});

	factory AppDependencies.create() {
		final secureStorage = SecureStorage();
		final apiClient = ApiClient(http.Client(), secureStorage);

		final authRepository = AuthRepositoryImpl(apiClient, secureStorage);
		final catalogoRepository = CatalogoRepositoryImpl(apiClient);
		final casoRepository = CasoRepositoryImpl(apiClient);

		return AppDependencies._(
			secureStorage: secureStorage,
			apiClient: apiClient,
			authRepository: authRepository,
			catalogoRepository: catalogoRepository,
			casoRepository: casoRepository,
			loginUseCase: LoginUseCase(authRepository),
			obtenerCatalogosUseCase: ObtenerCatalogosUseCase(catalogoRepository),
			cargarCasoUseCase: CargarCasoUseCase(casoRepository),
			obtenerMisCasosUseCase: ObtenerMisCasosUseCase(casoRepository),
		);
	}
}
