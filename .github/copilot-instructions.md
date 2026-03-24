# Project Guidelines

## Code Style
- Usar Dart/Flutter con `flutter_lints` activo (ver `analysis_options.yaml`).
- Mantener nombres de archivos en `snake_case` y clases en `PascalCase`.
- Usar espanol para nombres de clases, metodos, variables y comentarios del dominio.
- Preferir codigo simple y legible; evitar mover o reestructurar archivos sin necesidad.

## Architecture
- Este proyecto sigue DDD por feature con capas: `presentation -> application -> domain <- infrastructure`.
- Regla principal: las vistas no contienen logica de negocio; solo renderizan estado y despachan eventos BLoC.
- Estado con `flutter_bloc` + `equatable`; HTTP con `http`; token JWT en `flutter_secure_storage`; DI via `AppDependencies`.
- Routing esperado: Navigator 2.0 nativo (sin `go_router`/`beamer`).

Referencia de arquitectura, entidades, eventos/estados y endpoints:
- Ver `copilot-instructions.md` en la raiz del repo.
- Reglas especificas para codigo Dart: `.github/instructions/flutter-architecture.instructions.md`.

## Build and Test
- Instalar dependencias: `flutter pub get`
- Analisis estatico: `flutter analyze`
- Tests: `flutter test`
- Ejecutar app: `flutter run`
- Build Android release: `flutter build apk --release`
- Build Web: `flutter build web`

## Conventions
- No agregar logica de negocio en widgets/paginas.
- Los use cases deben exponer un unico metodo publico llamado `ejecutar(...)`.
- Repositorios `impl` reciben `ApiClient` por constructor.
- Eventos/estados de BLoC deben extender su base abstracta y definir `props` de Equatable.
- DTOs con `fromJson(Map<String, dynamic>)` y `toJson()`.

## Pitfalls
- Si falla Android release con `classes.dex ... being used by another process`, ejecutar `./android/gradlew --stop`, cerrar procesos Java/Gradle y reintentar build.
- Si el backend NestJS no arranca por `EADDRINUSE 3000`, liberar el puerto antes de probar login/carga de servicios.

## Key Files
- `copilot-instructions.md`: especificacion funcional y tecnica completa del proyecto.
- `pubspec.yaml`: dependencias y version de SDK.
- `lib/main.dart`: bootstrap de app (actualmente base/template).
- `analysis_options.yaml`: lints activos.
