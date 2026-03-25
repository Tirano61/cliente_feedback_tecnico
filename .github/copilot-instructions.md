# Contexto del proyecto — Feedback Técnico

## Descripción general

App Flutter para registro de casos de servicio técnico de balanzas electrónicas para uso agropecuario. El técnico carga casos desde el celular (APK Android) o desde la PC (Flutter Web). Un panel separado de desarrollo (Flutter Web, mismo proyecto, distinto rol) permite analizar los datos.

---

## Stack

- **Flutter** — un solo proyecto, tres targets: APK Android, Web técnico, Web admin
- **Backend** — NestJS corriendo en `http://localhost:3000` (cambiar a URL de producción cuando corresponda)
- **Estado** — flutter_bloc + equatable
- **HTTP** — http (no Dio). JWT agregado en ApiClient wrapper
- **Storage** — flutter_secure_storage para el token JWT
- **DI** — clase `AppDependencies` instanciada en main, sin get_it
- **BLoCs** — provistos con `MultiBlocProvider` en main.dart
- **Errores** — excepciones tipadas, estados de error en cada BLoC. Sin dartz ni Either
- **Routing** — Navigator 2.0 nativo via BlocBuilder en MaterialApp. Sin go_router ni beamer

---

## Regla fundamental de arquitectura

**Las vistas no tienen lógica.** Las páginas y widgets solo:
- Renderizan el estado con `BlocBuilder`
- Escuchan efectos secundarios con `BlocListener`
- Despachan eventos con `context.read<XBloc>().add(XEvent())`

Cero lógica de negocio, cero llamadas a repositorios, cero condicionales de estado fuera de BlocBuilder.

---

## Arquitectura — DDD estricto

Cada feature tiene cuatro capas. Las dependencias van siempre hacia adentro:
`presentation → application → domain ← infrastructure`

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart          # wrapper de http.Client con JWT header automático
│   │   └── api_constants.dart       # baseUrl y paths de endpoints
│   ├── auth/
│   │   └── secure_storage.dart      # guardar/leer/borrar token
│   ├── error/
│   │   └── failures.dart            # excepciones tipadas: ServerException, AuthException, etc.
│   ├── di/
│   │   └── app_dependencies.dart    # instancia y conecta todas las dependencias
│   └── widgets/                     # widgets compartidos entre features
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/usuario.dart
│   │   │   └── repositories/i_auth_repository.dart
│   │   ├── application/
│   │   │   └── login_use_case.dart
│   │   ├── infrastructure/
│   │   │   ├── dtos/usuario_dto.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart
│   │       ├── bloc/auth_event.dart
│   │       ├── bloc/auth_state.dart
│   │       └── pages/login_page.dart
│   │
│   ├── catalogos/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── categoria_producto.dart
│   │   │   │   ├── producto.dart
│   │   │   │   ├── cat_diagnostico.dart
│   │   │   │   ├── cat_resolucion.dart
│   │   │   │   └── zona.dart
│   │   │   └── repositories/i_catalogo_repository.dart
│   │   ├── application/
│   │   │   └── obtener_catalogos_use_case.dart
│   │   ├── infrastructure/
│   │   │   ├── dtos/
│   │   │   └── repositories/catalogo_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/catalogo_bloc.dart
│   │       ├── bloc/catalogo_event.dart
│   │       └── bloc/catalogo_state.dart
│   │
│   └── servicios/
│       ├── domain/
│       │   ├── entities/servicio.dart
│       │   └── repositories/i_servicio_repository.dart
│       ├── application/
│       │   ├── cargar_servicio_use_case.dart
│       │   └── obtener_mis_servicios_use_case.dart
│       ├── infrastructure/
│       │   ├── dtos/caso_dto.dart
│       │   └── repositories/servicio_repository_impl.dart
│       └── presentation/
│           ├── bloc/caso_bloc.dart
│           ├── bloc/caso_event.dart
│           ├── bloc/caso_state.dart
│           ├── pages/nuevo_servicio_page.dart
│           ├── pages/mis_servicios_page.dart
│           └── widgets/formulario_servicio.dart
│
└── main.dart
```

---

## Dependencias — pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5
  http: ^1.2.1
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## Inyección de dependencias — AppDependencies

Una sola clase que instancia todo en cadena. Se crea en main antes de runApp. Sin get_it.

```dart
// core/di/app_dependencies.dart
class AppDependencies {
  final SecureStorage secureStorage;
  final ApiClient apiClient;

  final IAuthRepository authRepository;
  final ICatalogoRepository catalogoRepository;
  final IServicioRepository casoRepository;

  final LoginUseCase loginUseCase;
  final ObtenerCatalogosUseCase obtenerCatalogosUseCase;
  final CargarServicioUseCase cargarServicioUseCase;
  final ObtenerMisServiciosUseCase obtenerMisServiciosUseCase;

  AppDependencies._({
    required this.secureStorage,
    required this.apiClient,
    required this.authRepository,
    required this.catalogoRepository,
    required this.casoRepository,
    required this.loginUseCase,
    required this.obtenerCatalogosUseCase,
    required this.cargarServicioUseCase,
    required this.obtenerMisServiciosUseCase,
  });

  factory AppDependencies.create() {
    final secureStorage = SecureStorage();
    final apiClient = ApiClient(http.Client(), secureStorage);

    final authRepository = AuthRepositoryImpl(apiClient);
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
      cargarServicioUseCase: CargarServicioUseCase(casoRepository),
      obtenerMisServiciosUseCase: ObtenerMisServiciosUseCase(casoRepository),
    );
  }
}
```

---

## main.dart — MultiBlocProvider

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = AppDependencies.create();
  runApp(App(deps: deps));
}

class App extends StatelessWidget {
  final AppDependencies deps;
  const App({required this.deps, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(deps.loginUseCase)..add(AppStarted()),
        ),
        BlocProvider(
          create: (_) => CatalogoBloc(deps.obtenerCatalogosUseCase),
        ),
        BlocProvider(
          create: (_) => ServicioBloc(
            deps.cargarServicioUseCase,
            deps.obtenerMisServiciosUseCase,
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<CatalogoBloc>().add(CargarCatalogos());
          }
        },
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) return const SplashPage();
              if (state is AuthAuthenticated) return const NuevoServicioPage();
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
```

---

## API — endpoints del backend

Base URL: `http://localhost:3000/api/v1`

Todos los endpoints salvo auth requieren:
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

### Auth
```
POST /auth/login       body: { email, password }       → { access_token }
POST /auth/register    body: { nombre, email, password, rol }
```

### Catálogos
```
GET   /cat/diagnosticos
POST  /cat/diagnosticos          body: { nombre }
PATCH /cat/diagnosticos/:id      body: { nombre?, activo? }

GET   /cat/resoluciones
POST  /cat/resoluciones          body: { nombre }
PATCH /cat/resoluciones/:id      body: { nombre?, activo? }

GET   /zonas
POST  /zonas                     body: { nombre, provincia }
PATCH /zonas/:id                 body: { nombre?, provincia?, activo? }

GET   /categorias-producto
POST  /categorias-producto       body: { nombre }
PATCH /categorias-producto/:id   body: { nombre?, activo? }

GET   /productos
POST  /productos                 body: { nombre, categoriaId }
PATCH /productos/:id             body: { nombre?, activo? }
```

### Casos
```
POST  /casos           body: ServicioDto
GET   /servicios/mios
GET   /casos           query params: canal, diagnostico_cat_id,
                       producto_id, zona_id, fecha_desde, fecha_hasta
GET   /servicios/:id
PATCH /servicios/:id       body: Partial<ServicioDto>
```

---

## ApiClient — patrón a seguir

```dart
class ApiClient {
  final http.Client _client;
  final SecureStorage _storage;

  ApiClient(this._client, this._storage);

  Future<http.Response> get(String path) async {
    final token = await _storage.getToken();
    return _client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _buildHeaders(token),
    );
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await _storage.getToken();
    return _client.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final token = await _storage.getToken();
    return _client.patch(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  Map<String, String> _buildHeaders(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

---

## Entidades domain

### Canal (enum)
```dart
enum Canal { campo, remoto, fabrica }
```

### Usuario
```dart
class Usuario extends Equatable {
  final String id;
  final String nombre;
  final String email;
  final String rol; // 'tecnico' | 'admin'

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  @override
  List<Object> get props => [id, nombre, email, rol];
}
```

### Servicio
```dart
class Servicio extends Equatable {
  final String id;
  final String tecnicoId;
  final String productoId;
  final String zonaId;
  final Canal canal;
  final DateTime fecha;
  final String sintoma;
  final String diagnosticoCatId;
  final String diagnosticoDetalle;
  final String resolucionId;
  final bool resuelto;
  final String? observaciones;

  const Servicio({
    required this.id,
    required this.tecnicoId,
    required this.productoId,
    required this.zonaId,
    required this.canal,
    required this.fecha,
    required this.sintoma,
    required this.diagnosticoCatId,
    required this.diagnosticoDetalle,
    required this.resolucionId,
    required this.resuelto,
    this.observaciones,
  });

  @override
  List<Object?> get props => [
    id, tecnicoId, productoId, zonaId, canal,
    fecha, sintoma, diagnosticoCatId, diagnosticoDetalle,
    resolucionId, resuelto, observaciones,
  ];
}
```

### Catálogos — mismo patrón para todos
```dart
class CatDiagnostico extends Equatable {
  final String id;
  final String nombre;
  final bool activo;
  const CatDiagnostico({required this.id, required this.nombre, required this.activo});
  @override List<Object> get props => [id, nombre, activo];
}

// Mismo patrón para: CatResolucion, CategoriaProducto
// Zona agrega: final String provincia
// Producto agrega: final String categoriaId
```

---

## Estados de los BLoCs

### AuthBloc
```dart
// Events
class AppStarted extends AuthEvent {}
class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted({required this.email, required this.password});
}
class LogoutRequested extends AuthEvent {}

// States
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final Usuario usuario;
  const AuthAuthenticated({required this.usuario});
  @override List<Object> get props => [usuario];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String mensaje;
  const AuthError({required this.mensaje});
  @override List<Object> get props => [mensaje];
}
```

### CatalogoBloc
```dart
// Events
class CargarCatalogos extends CatalogoEvent {}

// States
class CatalogoInitial extends CatalogoState {}
class CatalogoLoading extends CatalogoState {}
class CatalogoLoaded extends CatalogoState {
  final List<CatDiagnostico> diagnosticos;
  final List<CatResolucion> resoluciones;
  final List<Zona> zonas;
  final List<CategoriaProducto> categorias;
  final List<Producto> productos;
  const CatalogoLoaded({
    required this.diagnosticos,
    required this.resoluciones,
    required this.zonas,
    required this.categorias,
    required this.productos,
  });
  @override List<Object> get props =>
    [diagnosticos, resoluciones, zonas, categorias, productos];
}
class CatalogoError extends CatalogoState {
  final String mensaje;
  const CatalogoError({required this.mensaje});
  @override List<Object> get props => [mensaje];
}
```

### ServicioBloc
```dart
// Events
class ServicioFormularioCambiado extends CasoEvent {
  final Canal? canal;
  final String? zonaId;
  final String? categoriaId;
  final String? productoId;
  final String? sintoma;
  final String? diagnosticoCatId;
  final String? diagnosticoDetalle;
  final String? resolucionId;
  final String? observaciones;
}
class ServicioGuardarPressed extends CasoEvent {}
class MisServiciosSolicitados extends CasoEvent {}
class ServicioFormularioReiniciado extends CasoEvent {}

// States
class CasoInitial extends CasoState {}
class ServicioGuardando extends CasoState {}
class ServicioGuardadoExito extends CasoState {}
class ServicioError extends CasoState {
  final String mensaje;
  const ServicioError({required this.mensaje});
  @override List<Object> get props => [mensaje];
}
class MisServiciosLoading extends CasoState {}
class MisServiciosLoaded extends CasoState {
  final List<Servicio> casos;
  const MisServiciosLoaded({required this.casos});
  @override List<Object> get props => [casos];
}
```

---

## Formulario del técnico — lógica adaptativa

El label de resolución cambia según el canal seleccionado:

| Canal   | Label resolución       |
|---------|------------------------|
| campo   | Resolución             |
| remoto  | Resultado del contacto |
| fabrica | Trabajo realizado      |

### Orden de campos
1. Canal — chips selección única
2. Zona — dropdown (desde CatalogoLoaded.zonas)
3. Categoría de producto — dropdown (desde CatalogoLoaded.categorias)
4. Modelo — dropdown filtrado por categoría seleccionada (desde CatalogoLoaded.productos)
5. Síntoma — TextField multilínea, texto libre
6. Categoría de diagnóstico — chips selección única (desde CatalogoLoaded.diagnosticos)
7. Detalle técnico — TextField multilínea, texto libre
8. Resolución — chips selección única, label según canal (desde CatalogoLoaded.resoluciones)
9. Observaciones — TextField multilínea, opcional

Todos los campos son obligatorios salvo observaciones.
La validación ocurre en el BLoC al recibir `ServicioGuardarPressed`, nunca en la vista.

### Responsividad
```dart
LayoutBuilder(builder: (context, constraints) {
  final esWeb = constraints.maxWidth > 600;
  // esWeb → fila de dos columnas para zona / categoría / producto
  // mobile → columna única, campos al 100% de ancho
})
```

---

## Manejo de errores

Sin dartz. Los repositorios lanzan excepciones tipadas que el BLoC captura con try/catch.

```dart
// core/error/failures.dart
class ServerException implements Exception {
  final String mensaje;
  final int? statusCode;
  const ServerException(this.mensaje, {this.statusCode});
}

class AuthException implements Exception {
  final String mensaje;
  const AuthException(this.mensaje);
}

class NetworkException implements Exception {
  final String mensaje;
  const NetworkException(this.mensaje);
}
```

```dart
// Patrón en el BLoC
on<LoginSubmitted>((event, emit) async {
  emit(AuthLoading());
  try {
    final usuario = await loginUseCase.ejecutar(event.email, event.password);
    emit(AuthAuthenticated(usuario: usuario));
  } on AuthException catch (e) {
    emit(AuthError(mensaje: e.mensaje));
  } on ServerException catch (e) {
    emit(AuthError(mensaje: e.mensaje));
  } catch (_) {
    emit(AuthError(mensaje: 'Error inesperado. Intentá de nuevo.'));
  }
});
```

---

## Convenciones de código

- Nombres de archivos: snake_case
- Clases: PascalCase
- Todo en español (variables, clases, métodos, comentarios) salvo keywords de Dart/Flutter
- Los use cases tienen un único método público llamado `ejecutar(...)`
- Los repositorios impl reciben `ApiClient` por constructor
- Los use cases reciben el repositorio por constructor
- Los BLoCs reciben los use cases por constructor
- Las páginas no reciben dependencias por constructor — las leen del contexto con `context.read<XBloc>()`
- Los DTOs tienen factory `fromJson(Map<String, dynamic> json)` y método `toJson()`
- Los eventos y estados extienden de su clase base abstract con Equatable
- Props de Equatable siempre declarados, aunque la lista esté vacía
