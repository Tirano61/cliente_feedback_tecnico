# Estado del proyecto — App Flutter Técnico

> Documento generado a partir de una revisión del código fuente real del repo
> (`lib/`, `test/`, `pubspec.yaml`, `docs/`) el **27/09/2026**, sobre `main`
> (último commit `bae6233`), contra la arquitectura declarada en
> [CLAUDE.md](../CLAUDE.md) y el contrato **al día** del backend:
> [docs/endpoints.md](endpoints.md) y
> [docs/backend_feedback_postman_collection.json](backend_feedback_postman_collection.json)
> ahora son symlinks a `backend_feedback/docs/`. Donde el contrato y el código
> del backend no coinciden, se miró también el código del backend
> (`src/liquidacion/`, `src/servicios/`).
>
> Reemplaza al relevamiento anterior del mismo día (commit `846f1e4`). Entre ese
> relevamiento y éste **no cambió ningún archivo de `lib/` ni de `test/`**:
> cambió el contrato. Cada punto se volvió a verificar contra el código; los
> hallazgos nuevos salen de contrastarlo con el contrato actualizado y de
> revisar la paginación de los listados.

---

## 1. Resumen

App Flutter del técnico para el sistema de servicio técnico de balanzas
electrónicas. Es el cliente móvil/web que consume la API NestJS del repo
`backend`: permite al técnico loguearse, cargar una orden de servicio completa
(canal, cliente, equipo, falla, diagnóstico, resolución, repuestos,
facturación), generar el PDF de la orden localmente, firmarlo y subirlo, ver sus
servicios cargados y consultar sus liquidaciones.

**Etapa: funcional, en consolidación.** El flujo principal del técnico
(login → carga de orden → POST /servicios → PDF → firma → subida del documento)
está implementado de punta a punta contra un backend real
(`https://backend-feedback-11c2.onrender.com/api/v1`), con idempotencia, cola
offline de documentos pendientes y manejo de errores tipado.

Siguen resueltos, y verificados contra el código, los puntos que el relevamiento
original marcaba como críticos: restauración de sesión al arrancar, logout real,
cierre de sesión global ante 401, `mis_servicios_page.dart` sin HTTP directo,
`resolucionId` como array, parte `web` y reglas por canal en vista, validación y
payload.

**Hallazgos nuevos de este relevamiento:**

- **Los dos listados del técnico muestran sólo los 20 registros más recientes.**
  "Mis servicios" llama a `GET /servicios/mios` sin `page`/`limit` y descarta la
  paginación; "Liquidaciones" pide siempre `page=1&limit=20`. Con más de 20
  órdenes o liquidaciones, el resto no aparece, y los filtros, contadores y el
  total aprobado se calculan sobre esa primera página (§3.1, §3.2).
- El **fallback sin paginación** de liquidaciones, que esquivaba el 400 que daba
  el backend con `page`/`limit`, quedó muerto: el backend ya acepta esos params.
  Ese bug **no** era la causa de que la pantalla no pagine (§3.2).
- Los symlinks del contrato apuntan a una **ruta absoluta** de esta máquina y
  conviven con una copia vieja del postman (§7.7).
- El PDF **descarga la fuente de Google Fonts en cada arranque**: sin conexión
  cae a Helvetica sin soporte Unicode (§7.5).

Fuera de liquidaciones, el contrato actualizado no trajo cambios para este repo:
los demás cambios de `endpoints.md` son de endpoints de administración/analytics
(`GET /servicios` con `servicioDesde`/`servicioHasta`, `/stats/*`, `/export`).

Tamaño actual: **79 archivos Dart, ~11.900 líneas** en `lib/` y **11 archivos,
~1.500 líneas** en `test/`. `flutter test`: **51 tests, todos pasan**.
`flutter analyze`: 3 avisos `info` (ningún error ni warning).

---

## 2. Qué está implementado y funcionando

### 2.1 Infraestructura base (`lib/core/`)

| Pieza | Archivo | Estado |
|---|---|---|
| Cliente HTTP con JWT | [lib/core/api/api_client.dart](../lib/core/api/api_client.dart) | Completo: `get`, `post`, `patch`, `postMultipart`, header `Authorization: Bearer` inyectado desde storage. Stream `sesionExpirada` que emite ante cualquier 401 fuera de `/auth/login` ([api_client.dart:80-88](../lib/core/api/api_client.dart#L80)) |
| Lectura de JWT | [lib/core/auth/jwt_helper.dart](../lib/core/auth/jwt_helper.dart) | Decodifica el claim `exp` sin dependencias externas; un token ilegible se trata como vencido, con margen de 30 s |
| Constantes de endpoints | [lib/core/api/api_constants.dart](../lib/core/api/api_constants.dart) | Completo, con helpers por id (`servicioDocumentoPdf`, `liquidacionItems`, …) |
| Storage seguro | [lib/core/auth/secure_storage.dart](../lib/core/auth/secure_storage.dart) | Token, usuario de la sesión y clave/valor genérico para la cola offline |
| Excepciones tipadas | [lib/core/error/failures.dart](../lib/core/error/failures.dart) | `ServerException`, `AuthException`, `NetworkException` — sin dartz/Either |
| Inyección de dependencias | [lib/core/di/app_dependencies.dart](../lib/core/di/app_dependencies.dart) | 4 repositorios + 19 use cases en `AppDependencies.create()`, sin get_it |
| Bootstrap de BLoCs | [lib/main.dart](../lib/main.dart) | `MultiBlocProvider` con `AuthBloc` (recibe el stream `sesionExpirada`), `CatalogoBloc`, `ServicioBloc`, `LiquidacionesBloc`. Routing con `BlocConsumer<AuthBloc>` que al desloguear hace `popUntil(isFirst)` y muestra el motivo en un `SnackBar` ([main.dart:101-130](../lib/main.dart#L101)) |

### 2.2 Auth (`lib/features/auth/`)

- `POST /auth/login` con el shape del contrato (`access_token` + `user`):
  [login_response_dto.dart](../lib/features/auth/infrastructure/dtos/login_response_dto.dart).
  Si falta cualquiera de los dos, falla y no guarda sesión
  ([auth_repository_impl.dart:34-45](../lib/features/auth/infrastructure/repositories/auth_repository_impl.dart#L34)).
  Se persisten token y usuario.
- **Restauración de sesión** — `RestaurarSesionUseCase` →
  `obtenerSesionGuardada()`
  ([auth_repository_impl.dart:77-112](../lib/features/auth/infrastructure/repositories/auth_repository_impl.dart#L77)):
  exige token vigente según `exp` + usuario legible con `id` y `email`; ante
  cualquier inconsistencia limpia ambas claves y pide login.
- **Logout real** — `CerrarSesionUseCase` → `logout()` borra token y usuario.
  Botón con confirmación en el `AppBar` de
  [nueva_orden_servicio_page.dart:37-79](../lib/features/servicios/presentation/pages/nueva_orden_servicio_page.dart#L37).
- **Sesión expirada global** — `AuthBloc` escucha `ApiClient.sesionExpirada` y
  despacha `SesionExpiradaDetectada`; ignora 401 tardíos si ya no hay sesión
  ([auth_bloc.dart:75-90](../lib/features/auth/presentation/bloc/auth_bloc.dart#L75)).
- [login_page.dart](../lib/features/auth/presentation/pages/login_page.dart):
  sin lógica de negocio en la vista.

### 2.3 Catálogos (`lib/features/catalogos/`)

Los 5 catálogos del formulario se consumen y parsean (`/cat/diagnosticos`,
`/cat/resoluciones`, `/zonas`, `/categorias-producto`, `/productos?categoriaId=`)
en
[catalogo_repository_impl.dart](../lib/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart),
con carga perezosa y caché en
[catalogo_bloc.dart](../lib/features/catalogos/presentation/bloc/catalogo_bloc.dart)
(`forzar: true` para recargar). El param `activo` que agregó el contrato a
`/zonas`, `/categorias-producto` y `/productos` tiene como default "sólo
activos", que es lo que el formulario necesita: no hace falta mandarlo.

### 2.4 Servicios — el núcleo de la app (`lib/features/servicios/`)

**Formulario de carga** — [formulario_servicio.dart](../lib/features/servicios/presentation/widgets/formulario_servicio.dart) (2.867 líneas),
5 pasos navegables por chips: `Tipo · Datos · Falla · Facturación · Observaciones`.

- **Canal**: chips de selección única.
- **Reglas por canal**: zona y lugar sólo se muestran en `campo`
  ([formulario_servicio.dart:1256](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1256)),
  igual que el campo km ([formulario_servicio.dart:1713](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1713));
  al cambiar a remoto/fábrica el BLoC limpia esos valores
  (`_aplicarReglasDeCanal`, [servicio_bloc.dart:1256](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1256)),
  la validación sólo los exige en campo y el DTO omite las claves si vienen
  vacías ([servicio_dto.dart:251-263](../lib/features/servicios/infrastructure/dtos/servicio_dto.dart#L251)).
  Coincide con la tabla de reglas de [endpoints.md](endpoints.md).
- **Cliente**: búsqueda por nombre/CUIT (`GET /clientes/buscar?q=`, término
  URL-encodeado), tarjeta de resumen y alta rápida (`POST /clientes`) con
  mensaje específico si el CUIT ya existe.
- **Equipo**: modelo desde el catálogo de indicadores + serie, ubicación, año.
- **Falla/diagnóstico/resolución**: categorías de diagnóstico y resoluciones en
  selección múltiple ([formulario_servicio.dart:1579-1601](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1579)),
  productos que fallaron por parte, label de resolución según canal. `web` es
  una parte válida ([servicio_bloc.dart:32-40](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L32)).
- **Repuestos**: búsqueda (`GET /repuestos?q=`) y selección en combo, con cantidad.
- **Facturación**: `GET /cotizacion` + `GET /tarifa-km` con "Actualizar valores";
  subtotales, IVA y descuento en vivo; en remoto/fábrica no se factura viático.

**Alta de la orden** — [servicio_bloc.dart](../lib/features/servicios/presentation/bloc/servicio_bloc.dart) (1.640 líneas):

- Validación completa en el BLoC (`_validarFormulario`,
  [servicio_bloc.dart:1268](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1268)).
- Idempotencia real: `idempotencyKey` uuid v4 por orden, validado y reutilizado
  en reintentos; el mensaje de éxito distingue `replayed`.
- `fechaHoraServicio` ISO-8601 + `timezoneIana` + `utcOffsetMinutos`.
- `facturacionItems` (`mano_obra`, `viatico`, `repuesto`) y `facturacion` sin
  mandar los snapshots que completa el backend.
- **Contrato cubierto por tests**: `resolucionId`, `diagnosticoCatId` y
  `partesFallaron` viajan como arrays; reglas por canal para campo/remoto/fábrica
  ([payload_servicio_contrato_test.dart](../test/features/servicios/payload_servicio_contrato_test.dart)).

**PDF y firma** — [generar_pdf_orden_servicio_use_case.dart](../lib/features/servicios/application/generar_pdf_orden_servicio_use_case.dart):
PDF A4 generado localmente con la respuesta del POST, vista previa, firma
manuscrita (sólo `campo`, vía `PoliticaFirmaCanal`), regeneración del PDF con el
trazo y subida multipart a `POST /servicios/:id/documento/firmado`, con
reintento sin firma si el backend la rechaza.

**Cola offline de documentos**: si la subida falla, la solicitud (PDF en base64
incluido) se persiste en secure storage bajo `servicios_documentos_pendientes_v1`
y se reintenta desde el formulario o desde "Mis servicios".

**Mis servicios** — [mis_servicios_page.dart](../lib/features/servicios/presentation/pages/mis_servicios_page.dart) (586 líneas):

- Sin HTTP en la vista: sólo importa el BLoC, sus eventos/estados y `printing`.
  La verificación de PDF, la descarga y el enlace pasan por
  `ObtenerEnlacePdfDocumentoUseCase` / `DescargarPdfDocumentoUseCase` →
  `ServicioRepositoryImpl` → `ApiClient`
  ([servicio_repository_impl.dart:250-300](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L250)).
- Filtro por estado y búsqueda resueltos en el BLoC
  (`MisServiciosFiltroEstadoCambiado`, `MisServiciosBusquedaCambiada`).
- Verificación de PDF limitada a 20 consultas por carga
  (`_maximoVerificacionesPdf`) y omitida si el listado ya trae el documento.
- Cubierto por [mis_servicios_pdf_test.dart](../test/features/servicios/mis_servicios_pdf_test.dart)
  (disponibilidad, ver, copiar enlace, 401, Bearer).
- **Sin paginación**: ver §3.1.

### 2.5 Liquidaciones (`lib/features/liquidaciones/`)

- `GET /liquidaciones/mias?estado=todas&page=1&limit=20`
  ([liquidacion_remote_data_source.dart:12-21](../lib/features/liquidaciones/infrastructure/datasources/liquidacion_remote_data_source.dart#L12)),
  parseo de `{ data, meta }` en
  [liquidacion_dto.dart:246](../lib/features/liquidaciones/infrastructure/dtos/liquidacion_dto.dart#L246).
- `GET /liquidaciones/:id/items` para refrescar los items de una liquidación
  desde el detalle.
- 3 tabs (Pendientes / Aprobadas / Reabiertas) en
  [liquidaciones_screen.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart),
  recarga al entrar a la pantalla y pull-to-refresh.
- **Sólo muestra la primera página**: ver §3.2.

### 2.6 Tests (`test/`)

| Archivo | Qué cubre |
|---|---|
| [api_client_test.dart](../test/core/api/api_client_test.dart) | 401 dispara `sesionExpirada`; el 401 del login no |
| [jwt_helper_test.dart](../test/core/auth/jwt_helper_test.dart) | `exp` vigente / vencido / margen / ilegible / sin `exp` |
| [auth_bloc_test.dart](../test/features/auth/auth_bloc_test.dart) | Arranque con/sin sesión, logout, 401 global y tardío |
| [auth_repository_impl_test.dart](../test/features/auth/auth_repository_impl_test.dart) | Shape del login, varios roles, Bearer, errores |
| [auth_sesion_test.dart](../test/features/auth/auth_sesion_test.dart) · [ciclo_sesion_test.dart](../test/features/auth/ciclo_sesion_test.dart) | Restauración y ciclo completo de sesión |
| [mis_servicios_pdf_test.dart](../test/features/servicios/mis_servicios_pdf_test.dart) | Flujos de PDF del listado vía BLoC |
| [payload_servicio_contrato_test.dart](../test/features/servicios/payload_servicio_contrato_test.dart) | Arrays del contrato, parte `web`, reglas por canal |

Usan fakes escritos a mano (`test/support/`) y `http/testing`, sin `bloc_test`
ni `mocktail`. Ningún test cubre liquidaciones ni la paginación de ningún
listado.

---

## 3. Qué está a medias

Sigue sin haber `TODO`, `FIXME` ni mocks en `lib/`. Lo que está a medias lo
está por omisión:

1. **"Mis servicios" trunca a los 20 más recientes** *(nuevo)*.
   `obtenerMisServicios()` hace `GET /servicios/mios` sin query params
   ([servicio_repository_impl.dart:59-76](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L59)),
   el backend aplica `page=1&limit=20` por defecto
   (`servicios.controller.ts:35-47`) y la app se queda con la lista de `data`
   y descarta `meta`. No hay "cargar más" ni scroll infinito. El filtro por
   estado y la búsqueda del BLoC operan sólo sobre esas 20 órdenes: un técnico
   con historial no puede encontrar una orden vieja, ni reintentar/ver su PDF
   desde el listado.

2. **Liquidaciones trunca a la primera página** *(nuevo; revisado por el cambio
   de `page`/`limit`)*.
   - `LiquidacionesBloc._cargarLiquidaciones` llama a
     `_obtenerMisLiquidacionesUseCase.ejecutar()` sin argumentos
     ([liquidaciones_bloc.dart:37-45](../lib/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart#L37)),
     o sea `estado=todas&page=1&limit=20` siempre. No existe evento de página
     siguiente y `meta` (con `total`/`totalPages`) se guarda en el estado pero
     nadie lo lee.
   - Las tres pestañas, los contadores y el **"total aprobadas" en USD** se
     calculan en la vista filtrando esas 20
     ([liquidaciones_screen.dart:63-79](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart#L63)).
     Con más de 20 liquidaciones el total mostrado es menor que el real y las
     pestañas de estados viejos (típicamente "Aprobadas") quedan incompletas o
     vacías.
   - **Relación con el bug del backend**: hasta ahora `GET /liquidaciones/mias`
     con `page`/`limit` devolvía 400 (`property page should not exist`). La app
     lo esquivaba reintentando sin esos params
     ([liquidacion_repository_impl.dart:25-29 y 92-116](../lib/features/liquidaciones/infrastructure/repositories/liquidacion_repository_impl.dart#L25)),
     pero sin params el backend aplica igual `page=1&limit=20`: con o sin
     fallback la app veía la misma primera página. El bug explica por qué nunca
     se pudo pedir la página 2 ni probar la paginación, pero **la pantalla no
     pagina porque el BLoC nunca pide otra página**. El backend ya declara
     `page` y `limit` en `QueryMisLiquidacionesDto`, así que el fallback no se
     dispara más (código muerto, §7.3) y paginar ya es posible.

3. **`km` sigue siendo `int`.** `Servicio.km` es `int?`
   ([servicio.dart:35](../lib/features/servicios/domain/entities/servicio.dart#L35))
   y el BLoC redondea (`kmCantidad.round()`,
   [servicio_bloc.dart:1382](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1382)),
   mientras el campo acepta decimales y `facturacion.kmCantidad` viaja con el
   valor decimal: con 12,5 km la orden guarda `km = 13` y factura 12,5.

4. **`km = 0` pasa la validación en campo.** `_validarFormulario` sólo exige que
   el campo no esté vacío y que no sea negativo
   ([servicio_bloc.dart:1299-1305](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1299)).
   El contrato dice que en `campo` `km` debe ser **mayor a 0** porque la
   liquidación automática lo exige: la app deja enviar una orden que el backend
   rechaza con 400.

5. **Rol del usuario sin verificar.** `Usuario.roles` se parsea y se persiste,
   pero nadie lo consulta: un usuario sin rol `tecnico` entra a la app igual y
   después recibe 403 en `POST /servicios`, `/servicios/mios` y
   `/liquidaciones/mias`. CLAUDE.md dice que esta app es sólo para `tecnico`.

6. **403 tratado distinto según la feature.** El 401 es global, pero
   `LiquidacionRepositoryImpl` traduce **401 y 403** a `AuthException`
   ([liquidacion_repository_impl.dart:31 y 55](../lib/features/liquidaciones/infrastructure/repositories/liquidacion_repository_impl.dart#L31))
   y la pantalla despacha su propio `LogoutRequested`
   ([liquidaciones_screen.dart:32-37](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart#L32)).
   Resultado: un 403 desloguea en liquidaciones y en el resto de la app no; y un
   401 en liquidaciones dispara el cierre de sesión por dos caminos.

7. **Cola de pendientes no atada al usuario.** La clave
   `servicios_documentos_pendientes_v1` es global
   ([servicio_repository_impl.dart:29](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L29))
   y `logout()` sólo borra token y usuario: si otro técnico inicia sesión en el
   mismo dispositivo, ve y reintenta los documentos pendientes del anterior con
   su propio token.

8. **Equipo obligatorio en todos los canales.** La app exige serie, modelo,
   ubicación y año para remoto y fábrica
   ([servicio_bloc.dart:1283-1295](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1283));
   el contrato permite omitir el equipo en remoto (body mínimo de
   [endpoints.md](endpoints.md)) y CLAUDE.md modela
   `equipoUbicacion`/`equipoAnio` como opcionales. No rompe nada, pero obliga al
   técnico de soporte remoto a inventar datos.

9. **Pendiente anotado por el autor** en [Progreso_app.md](../Progreso_app.md):
   "Quitar los filtros en mis servicios aprobados/pendientes". Los filtros
   siguen
   ([mis_servicios_page.dart:177](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L177)),
   resueltos en el BLoC. Conviene decidirlo junto con la paginación (§3.1): con
   paginación del servidor, un filtro local sólo filtra la página cargada.

10. **Cobertura parcial.** Hay tests reales, pero no cubren `_validarFormulario`,
    `_recalcularFacturacion`, liquidaciones (BLoC, repositorio ni
    `LiquidacionDto`), catálogos, paginación ni ningún widget;
    [test/widget_test.dart](../test/widget_test.dart) sigue siendo el smoke test
    que no importa la app.

---

## 4. Qué falta por completo

### 4.1 Carpetas de la arquitectura que no existen

| Declarado en CLAUDE.md | Estado real |
|---|---|
| `lib/core/theme/app_theme.dart` | **No existe.** El tema sigue inline en [main.dart:73-100](../lib/main.dart#L73), sólo claro, sin `darkTheme` ni `themeMode: ThemeMode.system` |
| `lib/core/widgets/` | **No existe.** |
| `lib/features/clientes/` | **No existe.** Cliente vive dentro de `servicios/` |
| `lib/features/repuestos/` | **No existe.** Repuesto vive dentro de `servicios/` |
| `SplashPage` | **No existe.** `AuthInitial`/`AuthLoading` muestran un `CircularProgressIndicator` suelto |

### 4.2 Endpoints listados para este repo y nunca invocados

- `GET /clientes/:id` — al seleccionar el cliente se usan los datos del resultado
  de búsqueda, sin segunda llamada.
- `GET /servicios/:id` — no hay pantalla de detalle de una orden.
- `PATCH /servicios/:id` — `ApiClient.patch` existe pero nadie lo llama: no se
  puede editar una orden cargada.
- `POST /servicios/:id/repuestos` y `GET /servicios/:id/repuestos` — los
  repuestos sólo viajan en `facturacionItems` del POST inicial.
- `/auth/register` — constante sin uso (correcto: el técnico no se
  auto-registra; conviene borrarla).

Los params `page`/`limit` de `GET /servicios/mios` y `GET /liquidaciones/mias`
están en el contrato pero la app no los usa de forma efectiva (§3.1, §3.2).

### 4.3 Otras ausencias

- **CI**: `.github/workflows/` no existe; ni `flutter analyze` ni `flutter test`
  corren automáticamente, aunque hay 51 tests que valdría la pena proteger.
- **Configuración por entorno**: `baseUrl` sigue hardcodeada en
  [api_constants.dart:3](../lib/core/api/api_constants.dart#L3), sin
  `--dart-define` ni flavors (CLAUDE.md documenta `localhost:3000`, el código
  apunta a Render).
- **Fuente del PDF empaquetada**: no hay `assets/fonts/`; la fuente se baja en
  runtime (§7.5).
- **Dependencias de test**: sin `bloc_test` ni `mocktail`; los tests actuales
  usan fakes a mano, que funciona pero escala peor.
- **README real**: [README.md](../README.md) y la `description` de
  `pubspec.yaml` siguen siendo el template de Flutter.

---

## 5. Estructura actual del proyecto

```
cliente_feedback_tecnico/
├── CLAUDE.md                       # arquitectura de referencia (titulado "AGENTS.md")
├── Progreso_app.md                 # notas de avance del autor
├── copilot-instructions.md         # difiere del de .github/
├── plan_backend.html
├── pubspec.yaml
├── analysis_options.yaml
├── .github/
│   ├── copilot-instructions.md
│   ├── instructions/flutter-architecture.instructions.md
│   └── modernize/java-upgrade/hooks/   # ajeno al proyecto Flutter
├── docs/
│   ├── endpoints.md                            # SYMLINK → backend_feedback/docs/endpoints.md (sin commitear)
│   ├── backend_feedback_postman_collection.json # SYMLINK → backend_feedback/docs/postman/… (sin trackear)
│   ├── backend_feedback.postman_collection.json # copia vieja del 12/09, trackeada, desactualizada
│   ├── sistema_feedback_arquitectura.md
│   ├── flutter-tecnico-copilot-handoff.md
│   └── ESTADO.md                               # este documento
├── test/
│   ├── core/api/api_client_test.dart                 (62)
│   ├── core/auth/jwt_helper_test.dart                (50)
│   ├── features/auth/  auth_bloc_test (171) · auth_repository_impl_test (180) ·
│   │                   auth_sesion_test (109) · ciclo_sesion_test (98)
│   ├── features/servicios/  mis_servicios_pdf_test (538) ·
│   │                        payload_servicio_contrato_test (206)
│   ├── support/        jwt_de_prueba.dart · secure_storage_en_memoria.dart
│   └── widget_test.dart                              (16, no toca la app)
├── android/ · ios/ · web/ · windows/ · linux/ · macos/
└── lib/
    ├── main.dart                                    (139)
    ├── core/
    │   ├── api/            api_client.dart (106) · api_constants.dart (38)
    │   ├── auth/           jwt_helper.dart (64) · secure_storage.dart (46)
    │   ├── di/             app_dependencies.dart (140)
    │   └── error/          failures.dart (18)
    └── features/
        ├── auth/
        │   ├── application/         login · restaurar_sesion · cerrar_sesion (use cases)
        │   ├── domain/              entities/usuario.dart · repositories/i_auth_repository.dart
        │   ├── infrastructure/      dtos/{login_response_dto,usuario_dto}.dart ·
        │   │                        repositories/auth_repository_impl.dart (119)
        │   └── presentation/        bloc/{auth_bloc (106),auth_event,auth_state}.dart
        │                            pages/login_page.dart (192)
        ├── catalogos/
        │   ├── application/         obtener_catalogos_use_case.dart (94)
        │   ├── domain/              entities/{cat_diagnostico,cat_resolucion,categoria_producto,
        │   │                                  producto,zona}.dart · repositories/
        │   ├── infrastructure/      repositories/catalogo_repository_impl.dart (163)
        │   └── presentation/        bloc/{catalogo_bloc,catalogo_event,catalogo_state}.dart
        ├── servicios/
        │   ├── application/         13 use cases (buscar_clientes, buscar_repuestos,
        │   │                        cargar_servicio, crear_cliente_rapido,
        │   │                        descargar_pdf_documento, generar_pdf_orden_servicio (214),
        │   │                        obtener_cotizacion_actual, obtener_enlace_pdf_documento,
        │   │                        obtener_mis_servicios, subir_documento_firmado,
        │   │                        encolar/obtener/quitar_documento_pendiente)
        │   ├── domain/
        │   │   ├── entities/        servicio.dart (129) · cliente · repuesto · facturacion ·
        │   │   │                    facturacion_item · producto_falla · documento_orden ·
        │   │   │                    orden_servicio_respuesta · cotizacion_actual ·
        │   │   │                    solicitud_documento_firmado · politica_firma_canal
        │   │   └── repositories/    i_servicio_repository.dart
        │   ├── infrastructure/
        │   │   ├── dtos/            servicio_dto.dart (582) · orden_servicio_respuesta_dto (182) ·
        │   │   │                    cotizacion_actual_dto · repuesto_dto · cliente_dto
        │   │   └── repositories/    servicio_repository_impl.dart (687)
        │   └── presentation/
        │       ├── bloc/            servicio_bloc.dart (1640) · servicio_state.dart (553) ·
        │       │                    servicio_event.dart (270) · filtro_estado_servicio.dart
        │       ├── pages/           nueva_orden_servicio_page.dart (80) ·
        │       │                    mis_servicios_page.dart (586)
        │       └── widgets/         formulario_servicio.dart (2867)
        └── liquidaciones/
            ├── application/         obtener_mis_liquidaciones · obtener_items_liquidacion
            ├── domain/              entities/liquidacion.dart (211) · repositories/
            ├── infrastructure/      datasources/liquidacion_remote_data_source.dart (45) ·
            │                        dtos/liquidacion_dto.dart (327) ·
            │                        repositories/liquidacion_repository_impl.dart (117)
            └── presentation/        bloc/{liquidaciones_bloc,_event,_state}.dart ·
                                     pages/liquidaciones_screen.dart (760)
```

(Números entre paréntesis = líneas. `build/`, `.dart_tool/`, `.idea/` omitidos.)

---

## 6. Próximos pasos sugeridos

En orden de prioridad — de "rompe el uso diario" a "deuda de calidad":

1. **Paginar liquidaciones.** El backend ya acepta `page`/`limit` en
   `GET /liquidaciones/mias` (antes daba 400, y por eso la app tenía un fallback
   sin paginación que igual devolvía sólo la primera página).
   - Agregar un evento `LiquidacionesPaginaSiguienteSolicitada` al BLoC que use
     `meta.page`/`meta.totalPages` y acumule resultados; conectarlo al final de
     la lista de cada pestaña.
   - Pedir por pestaña con `estado=pendiente|aprobada|reabierta` en lugar de
     `todas` + filtro en la vista, para que cada pestaña pagine por separado.
   - Sacar de la vista el cálculo de "total aprobadas": con paginación no se
     puede sumar en el cliente sin cargar todo. Hay que pedirle al backend un
     total o dejar claro que es el total de lo cargado.
   - Borrar `obtenerMisLiquidacionesRawSinPaginacion`,
     `_debeReintentarSinPaginacion` y `_contieneErrorParametroNoPermitido`.
   - Test del BLoC con dos páginas.

2. **Paginar "Mis servicios".** Mandar `page`/`limit` a `GET /servicios/mios`,
   devolver `meta` desde el repositorio y agregar "cargar más" en el BLoC.
   Decidir qué hacer con el filtro por estado y la búsqueda locales (§3.9): hoy
   sólo ven la página cargada y el endpoint no acepta otros filtros.

3. **Cerrar los desvíos de `km`.** Pasar `Servicio.km` a `double?` (entidad, DTO
   y PDF) y exigir `km > 0` en `_validarFormulario` cuando el canal es `campo`,
   con un test en `payload_servicio_contrato_test.dart`. Es chico y hoy genera
   400 del backend y datos inconsistentes.

4. **Arreglar los symlinks del contrato antes de commitearlos** (§7.7): usar
   destino relativo (`../../backend_feedback/docs/endpoints.md`), borrar la
   copia vieja `backend_feedback.postman_collection.json` y decidir cómo lo
   resuelven los clones en Windows sin `core.symlinks`.

5. **Aislar la cola de pendientes por usuario.** Incluir el id del técnico en la
   clave (o vaciar/descartar la cola al cerrar sesión, avisando si había
   documentos sin subir).

6. **Verificar el rol al loguear y al restaurar.** Si `roles` no incluye
   `tecnico`, no guardar sesión y mostrar un error claro.

7. **Unificar 401/403.** Quitar la traducción propia de
   `LiquidacionRepositoryImpl` y el `LogoutRequested` de la pantalla, dejando el
   401 en manos de `ApiClient`; decidir explícitamente qué hacer con 403.

8. **Empaquetar la fuente del PDF** (NotoSans en `assets/fonts/`, cargada con
   `pw.Font.ttf`) para que la orden se genere igual sin conexión.

9. **Relajar el equipo en remoto/fábrica** según el contrato (al menos
   ubicación y año opcionales, como en CLAUDE.md).

10. **Detalle y edición de órdenes** (`GET /servicios/:id` + `PATCH
    /servicios/:id`), empezando por el detalle desde "Mis servicios".

11. **CI** (`.github/workflows/flutter.yml`) con `flutter analyze` + `flutter
    test` en cada PR.

12. **Tests de lo que concentra más riesgo y aún no está cubierto**:
    `_validarFormulario`, `_recalcularFacturacion` (fijar primero la regla del
    descuento, ver §7.5), liquidaciones y `LiquidacionDto` contra los ejemplos
    de [endpoints.md](endpoints.md).

13. **Crear `lib/core/theme/app_theme.dart`** con `temaLight()`/`temaDark()` y
    `themeMode: ThemeMode.system`, y una `SplashPage` para `AuthLoading`.

14. **Parametrizar la `baseUrl`** con `--dart-define=API_BASE_URL=...`.

15. **Partir `formulario_servicio.dart`** (2.867 líneas) en un widget por paso
    y sacar de la vista el cálculo de facturación que duplica al BLoC (§7.1).

16. Avisar al repo backend del desvío en la tabla de roles de
    `endpoints.md` (§7.7), y actualizar [README.md](../README.md) y la
    `description` de `pubspec.yaml`.

---

## 7. Deuda técnica o problemas detectados

### 7.1 Lógica en las vistas

La violación más seria del relevamiento original (HTTP crudo en
`mis_servicios_page.dart`) sigue resuelta. Queda lógica en dos vistas:

- **Filtrado y totales de liquidaciones en la vista** *(nuevo en este
  relevamiento)*: `_filtrarPorEstado` y la suma de `totalLiquidacionUsd`
  ([liquidaciones_screen.dart:63-79 y 152-157](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart#L63))
  son reglas de negocio calculadas en el `builder`. Además, al paginar dejan de
  ser correctas (§3.2).
- **Cálculo de facturación en el formulario**: el paso de facturación recalcula
  subtotal de km, precio en ARS y montos de descuento con su propio
  `_doubleDesdeTextoLocal`
  ([formulario_servicio.dart:1620-1632](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1620)),
  en paralelo a `_recalcularFacturacion` del BLoC.
- **Normalización de partes en el formulario**: `_normalizarParteFalladaBackend`
  ([formulario_servicio.dart:2785](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L2785))
  decide la parte a partir del nombre de la categoría al elegir productos.
- **Armado de la solicitud de firma en la vista**: el bottom sheet captura el
  trazo, decide qué campos de firma mandar según `agregarFirma` e inventa la
  `rutaPdfLocal` ([formulario_servicio.dart:585-605](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L585)).

### 7.2 Código duplicado

| Duplicación | Dónde |
|---|---|
| Normalización de "parte que falló" | `_normalizarParteFallada` en [servicio_bloc.dart:1600](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1600) **y** `_normalizarParteFalladaBackend` en [formulario_servicio.dart:2785](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L2785). Ambas mapean `web` correctamente, pero hay que mantenerlas en sincronía a mano |
| Extracción de `pdfUrl` del documento | `_extraerPdfUrl` en [servicio_dto.dart:483](../lib/features/servicios/infrastructure/dtos/servicio_dto.dart#L483) **y** `_extraerPdfUrlDesdeDocumento` en [servicio_repository_impl.dart:384](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L384) |
| Helpers `_doubleDesdeDynamic` / `_intDesdeDynamic` / `_boolDesdeDynamic` | 7 archivos: `servicio_dto`, `orden_servicio_respuesta_dto`, `repuesto_dto`, `cotizacion_actual_dto`, `liquidacion_dto`, `catalogo_repository_impl`, `servicio_repository_impl` |
| Formateo de fecha dd/MM/yyyy | 5 copias: `servicio_bloc`, `formulario_servicio`, `generar_pdf_orden_servicio_use_case`, `mis_servicios_page`, `liquidaciones_screen` |
| Bucle de reintento de pendientes (`for` + `try` + `_quitarDocumentoPendiente`) | Dos copias casi literales dentro de `_onServicioDocumentoPendientesReintentarSolicitado` ([servicio_bloc.dart:734-830](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L734)) |
| Colección Postman | `docs/backend_feedback.postman_collection.json` (copia del 12/09) **y** el symlink `docs/backend_feedback_postman_collection.json`: dos nombres casi iguales, uno desactualizado (§7.7) |
| `copilot-instructions.md` | En la raíz y en `.github/`, con contenido divergente: no está claro cuál vale |

### 7.3 Código muerto

- **Fallback de liquidaciones sin paginación** *(nuevo)*:
  `obtenerMisLiquidacionesRawSinPaginacion`
  ([liquidacion_remote_data_source.dart:23-28](../lib/features/liquidaciones/infrastructure/datasources/liquidacion_remote_data_source.dart#L23)),
  `_debeReintentarSinPaginacion` y `_contieneErrorParametroNoPermitido`
  ([liquidacion_repository_impl.dart:92-116](../lib/features/liquidaciones/infrastructure/repositories/liquidacion_repository_impl.dart#L92)).
  Sólo se disparaban con el 400 `property page should not exist`, que el backend
  ya no devuelve.
- `LiquidacionesLoaded.meta`: se emite pero ninguna vista ni evento lo lee.
- `ObtenerCatalogosUseCase.ejecutar()` y la clase `CatalogosData`
  ([obtener_catalogos_use_case.dart:8 y 82](../lib/features/catalogos/application/obtener_catalogos_use_case.dart#L8)).
- Evento `CargarCatalogos`: registrado pero nunca despachado.
- `ServicioInitial` ([servicio_state.dart:18](../lib/features/servicios/presentation/bloc/servicio_state.dart#L18)): nunca se emite.
- `ApiClient.patch()`, `ApiConstants.register`, `SecureStorage.borrarValor()`:
  sin uso.
- `NetworkException`: declarada y nunca lanzada; los errores de red caen en
  `ServerException` genéricos.
- `authRepository`, `catalogoRepository`, `servicioRepository` y
  `liquidacionRepository` expuestos como públicos en `AppDependencies` sin que
  nadie los lea desde afuera.
- Condicional redundante en `_asegurarCatalogosParaPaso`: dos `if` seguidos con
  la misma condición `(paso == 1 || paso == 2)`
  ([formulario_servicio.dart:59-67](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L59)).

### 7.4 Inconsistencias de estilo y convención

- **Indentación mezclada**: `servicios/`, `auth/`, `catalogos/` y `core/` usan
  tabuladores; `liquidaciones/` y `main.dart` usan 2 espacios. No hay
  `.editorconfig`.
- **Estructura de liquidaciones distinta**: es la única feature con
  `infrastructure/datasources/` entre el repositorio y `ApiClient`; las demás
  llaman a `ApiClient` desde el repositorio, como indica CLAUDE.md.
- **`failures.dart` no contiene ningún `Failure`**: son excepciones; debería
  llamarse `exceptions.dart`.
- **Nombres respecto de CLAUDE.md**: `features/liquidaciones/` vs
  `liquidacion/`; `NuevaOrdenServicioPage` vs `NuevoServicioPage`;
  `LiquidacionesScreen` con sufijo `Screen` frente a `Page` en el resto.
- **Entidad `Servicio`**: CLAUDE.md usa `diagnosticoCatId`/`resolucionId`; el
  código usa `diagnosticoCatIds`/`resolucionIds` (el JSON sí respeta el
  contrato). Diferencia sólo de nombre, pero conviene documentarla.
- **Estado fuera del estado**: `ServicioBloc` guarda la lista de pendientes en un
  campo mutable `_documentosPendientes` además de en los estados emitidos.

### 7.5 Riesgos funcionales concretos

- **Listados truncados a 20** (§3.1, §3.2): el técnico no ve órdenes ni
  liquidaciones viejas y el total aprobado en USD sale menor que el real, sin
  ningún aviso en pantalla.
- **Fuente del PDF descargada en runtime** *(nuevo)*:
  `PdfGoogleFonts.notoSansRegular()`/`notoSansBold()`
  ([generar_pdf_orden_servicio_use_case.dart:17-18](../lib/features/servicios/application/generar_pdf_orden_servicio_use_case.dart#L17))
  bajan la fuente de `fonts.gstatic.com`. Sin conexión (caso típico en campo,
  justo cuando la cola offline tiene sentido) `printing` cae a Helvetica sin
  soporte Unicode: el propio `flutter test` lo muestra (`Unable to download …
  fallback to Helvetica`). Además agrega una llamada de red a cada primera
  generación.
- **PDF en base64 dentro de `flutter_secure_storage`**
  ([servicio_repository_impl.dart:631](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L631)).
  El keystore no está pensado para blobs; con varias órdenes pendientes puede
  fallar. `rutaPdfLocal` sigue siendo un pseudo-URI `memoria://...` que no apunta
  a nada ([servicio_bloc.dart:1137](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1137)).
- **Cola de pendientes compartida entre usuarios** (§3.7).
- **Búsqueda de cotización "a fuerza bruta"**: `_buscarValorPorClaves`
  ([servicio_repository_impl.dart:566](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L566))
  recorre todo el JSON probando varios nombres de clave, incluido `'valor'`.
- **Detección de errores de firma por texto**: `_esErrorFirmaNoPermitida`
  ([servicio_bloc.dart:1246](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1246))
  busca "firma" + "canal"/"remoto"/"fabrica" en el mensaje. El único texto de
  rechazo que documenta [endpoints.md](endpoints.md) ("Solo las ordenes de campo
  pueden registrarse como firmadas", para `POST /servicios`) **no contiene
  ninguna de esas tres palabras**; para `POST /servicios/:id/documento/firmado`
  el mensaje no está documentado. Si el backend usa el mismo texto, el reintento
  sin firma no se dispara. En la práctica lo mitiga `PoliticaFirmaCanal`, que no
  ofrece firma fuera de campo.
- **Descuento ambiguo**: `_recalcularFacturacion` aplica el descuento sobre el
  total con IVA en ARS ([servicio_bloc.dart:1478-1485](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1478)),
  mientras la vista muestra un `descuentoMontoUsd` calculado sobre el subtotal
  bruto ([formulario_servicio.dart:1631](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1631)).
- **Avisos de `flutter analyze`**: los tres `use_build_context_synchronously`
  del flujo de firma (`formulario_servicio.dart:570, 586, 605`), que pueden
  lanzar si el técnico cierra la hoja mientras se captura la firma.

### 7.6 Dependencias

**Todas las dependencias de `pubspec.yaml` están en uso**: `flutter_bloc`,
`equatable`, `http` + `http_parser`, `flutter_secure_storage`, `pdf` +
`printing`, `uuid`, `signature`, `cupertino_icons`. No hay paquetes huérfanos.
`JwtHelper` decodifica el token sin agregar dependencias.

En `dev_dependencies` siguen faltando `bloc_test` y `mocktail`/`mockito`.

### 7.7 Documentación y contrato *(sección nueva)*

- **Symlinks con ruta absoluta.** `docs/endpoints.md` apunta a
  `/d/NEST + FLUTTER/Feedback Tecnico/backend_feedback/docs/endpoints.md`, y el
  postman a una ruta absoluta equivalente. Sólo resuelven en esta máquina y con
  esta estructura de carpetas. Además `core.symlinks` está en `false` en este
  clon: en Windows, quien clone sin symlinks habilitados va a recibir un archivo
  de texto con la ruta en lugar del contrato. Hoy `endpoints.md` figura como
  `T` (cambio de tipo) sin commitear y el postman nuevo como no trackeado.
- **Postman duplicado.** Coexisten `backend_feedback.postman_collection.json`
  (archivo real del 12/09, trackeado, desactualizado: no tiene, por ejemplo,
  `page`/`limit` en `/liquidaciones/mias`) y
  `backend_feedback_postman_collection.json` (symlink al día). CLAUDE.md
  referencia el segundo nombre; conviene borrar el primero para que nadie
  modele desde la copia vieja.
- **Desvío dentro del contrato del backend.** La tabla de roles de
  [endpoints.md](endpoints.md) lista `GET /liquidaciones/:id/items` sólo para
  `admin-tecnico`, pero el controller lo declara
  `@Auth(ValidRoles.tecnico, ValidRoles.adminTecnico)` y filtra por usuario. La
  app lo usa como técnico y funciona. Lo que está mal es la tabla del backend, y
  se debería corregir allá. Mientras tanto, cualquiera que modele desde la tabla
  va a pensar que la app llama a un endpoint prohibido.
- **Referencias rotas**:
  [flutter-tecnico-copilot-handoff.md](flutter-tecnico-copilot-handoff.md)
  apunta a `docs/postman/backend_feedback.postman_collection.json`, que no
  existe en este repo; CLAUDE.md documenta `localhost:3000` como base URL
  mientras el código usa Render.

---

## Porcentaje aproximado de avance: **≈ 84 %**

**Justificación.** El relevamiento anterior estimó ≈ 86 %. Desde entonces **no
cambió código de la app**, así que no hay avance nuevo que sumar. Lo que cambió
es la medición: al contrastar con el contrato al día y revisar cómo cargan los
listados, aparecieron dos huecos funcionales que el 86 % no contemplaba. "Mis
servicios" y "Liquidaciones" muestran sólo los 20 registros más recientes, y el
total aprobado se calcula sobre esa página. Esto afecta el uso diario de
cualquier técnico con historial, así que se descuentan **2 puntos**. El resto de
lo verificado coincide con el relevamiento anterior: todo lo que figuraba como
resuelto sigue resuelto, y 51 tests pasan.

El ≈ 16 % restante:

- **~7 % — funcionalidad faltante o desviada**: listados sin paginar (servicios
  y liquidaciones), sin detalle ni edición de órdenes (`GET`/`PATCH
  /servicios/:id`), `km` entero y `km = 0` aceptado en campo, rol no verificado,
  cola de pendientes compartida entre usuarios, equipo obligatorio en remoto.
- **~5 % — calidad y verificación**: sin tests de validación, facturación,
  liquidaciones, paginación ni widgets; sin CI; sin configuración por entorno;
  sin `app_theme.dart` ni tema oscuro; PDF dependiente de red para la fuente.
- **~4 % — deuda técnica**: formulario de 2.867 líneas con cálculo propio de
  facturación, lógica de liquidaciones en la vista, focos de duplicación, código
  muerto (incluido el fallback sin paginación), indentación mezclada, los
  riesgos de §7.5 y los symlinks del contrato con ruta absoluta.

La app se puede usar en campo sin re-loguearse y cumple el contrato del alta de
órdenes. Lo más urgente ahora es que el técnico vea **todo** su historial, no
sólo los últimos 20 registros: el backend ya lo permite y el cambio queda del
lado de la app. Después vienen poder corregir una orden cargada y blindar con
tests y CI lo que ya funciona.
