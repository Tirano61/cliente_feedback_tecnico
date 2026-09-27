# Estado del proyecto — App Flutter Técnico

> Documento generado a partir de una revisión del código fuente real del repo
> (`lib/`, `test/`, `pubspec.yaml`, `docs/`) el **27/09/2026**, sobre la rama
> `alinearContratoServicios` (último commit `6c96b58`), contra la arquitectura
> declarada en [CLAUDE.md](../CLAUDE.md) y el contrato de
> [docs/endpoints.md](endpoints.md) — incluidos los cambios todavía sin commitear
> de ese archivo (reglas por canal de `lugarProvinciaId`/`lugarDetalle`/`km`).
> Reemplaza al relevamiento del 12/09/2026: cada punto se volvió a verificar
> contra el código, no se arrastró del documento anterior.

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

Desde el relevamiento anterior se cerraron los puntos que más afectaban el uso
diario y el cumplimiento del contrato:

- la sesión **se restaura al arrancar** y el **logout es real** (botón en la UI,
  borra token y usuario);
- un **401 en cualquier llamada** cierra la sesión globalmente;
- `mis_servicios_page.dart` **ya no hace HTTP directo**;
- `resolucionId` es **array**, existe la parte **`web`** y las **reglas por
  canal** (zona/lugar/km sólo en `campo`) se aplican en la vista, la validación
  y el payload;
- hay **51 tests reales** cubriendo auth, sesión, PDF de mis servicios y el
  contrato del payload.

Lo que falta es edición/detalle de órdenes, algunos desvíos finos del contrato
(`km` entero, `km = 0` en campo), verificación de rol, tema compartido, CI y la
deuda técnica del formulario.

Tamaño actual: **79 archivos Dart, ~11.900 líneas** en `lib/` y **11 archivos,
~1.500 líneas** en `test/`. `flutter test`: **51 tests, todos pasan**.
`flutter analyze`: 3 avisos `info` (ningún error ni warning).

---

## 2. Qué está implementado y funcionando

### 2.1 Infraestructura base (`lib/core/`)

| Pieza | Archivo | Estado |
|---|---|---|
| Cliente HTTP con JWT | [lib/core/api/api_client.dart](../lib/core/api/api_client.dart) | Completo: `get`, `post`, `patch`, `postMultipart`, header `Authorization: Bearer` inyectado desde storage. **Nuevo:** stream `sesionExpirada` que emite ante cualquier 401 fuera de `/auth/login` ([api_client.dart:80-88](../lib/core/api/api_client.dart#L80)) |
| Lectura de JWT | [lib/core/auth/jwt_helper.dart](../lib/core/auth/jwt_helper.dart) | **Nuevo.** Decodifica el claim `exp` sin dependencias externas; un token ilegible se trata como vencido, con margen de 30 s |
| Constantes de endpoints | [lib/core/api/api_constants.dart](../lib/core/api/api_constants.dart) | Completo, con helpers por id (`servicioDocumentoPdf`, `liquidacionItems`, …) |
| Storage seguro | [lib/core/auth/secure_storage.dart](../lib/core/auth/secure_storage.dart) | Token, **usuario de la sesión** (nuevo) y clave/valor genérico para la cola offline |
| Excepciones tipadas | [lib/core/error/failures.dart](../lib/core/error/failures.dart) | `ServerException`, `AuthException`, `NetworkException` — sin dartz/Either |
| Inyección de dependencias | [lib/core/di/app_dependencies.dart](../lib/core/di/app_dependencies.dart) | 4 repositorios + **19 use cases** en `AppDependencies.create()`, sin get_it |
| Bootstrap de BLoCs | [lib/main.dart](../lib/main.dart) | `MultiBlocProvider` con `AuthBloc` (recibe el stream `sesionExpirada`), `CatalogoBloc`, `ServicioBloc`, `LiquidacionesBloc`. Routing con `BlocConsumer<AuthBloc>` que al desloguear hace `popUntil(isFirst)` y muestra el motivo en un `SnackBar` ([main.dart:101-130](../lib/main.dart#L101)) |

### 2.2 Auth (`lib/features/auth/`)

- `POST /auth/login` con el shape nuevo (`access_token` + `user`):
  [login_response_dto.dart](../lib/features/auth/infrastructure/dtos/login_response_dto.dart).
  Si falta cualquiera de los dos, falla y **no guarda sesión**
  ([auth_repository_impl.dart:34-45](../lib/features/auth/infrastructure/repositories/auth_repository_impl.dart#L34)).
  Se persisten token **y** usuario.
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
  sin cambios, sin lógica de negocio en la vista.

### 2.3 Catálogos (`lib/features/catalogos/`)

Sin cambios desde el relevamiento anterior. Los 5 catálogos del formulario se
consumen y parsean (`/cat/diagnosticos`, `/cat/resoluciones`, `/zonas`,
`/categorias-producto`, `/productos?categoriaId=`) en
[catalogo_repository_impl.dart](../lib/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart),
con carga perezosa y caché en
[catalogo_bloc.dart](../lib/features/catalogos/presentation/bloc/catalogo_bloc.dart)
(`forzar: true` para recargar).

### 2.4 Servicios — el núcleo de la app (`lib/features/servicios/`)

**Formulario de carga** — [formulario_servicio.dart](../lib/features/servicios/presentation/widgets/formulario_servicio.dart) (2.867 líneas),
5 pasos navegables por chips: `Tipo · Datos · Falla · Facturación · Observaciones`.

- **Canal**: chips de selección única.
- **Reglas por canal aplicadas** (nuevo): zona y lugar sólo se muestran en
  `campo` ([formulario_servicio.dart:1256](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1256)),
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
- **Falla/diagnóstico/resolución**: categorías de diagnóstico **y resoluciones**
  en selección múltiple ([formulario_servicio.dart:1579-1601](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1579)),
  productos que fallaron por parte, label de resolución según canal.
  `web` es una parte válida ([servicio_bloc.dart:32-40](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L32)).
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

**Mis servicios** — [mis_servicios_page.dart](../lib/features/servicios/presentation/pages/mis_servicios_page.dart) (586 líneas, antes 943):

- **Sin HTTP en la vista** (nuevo): sólo importa el BLoC, sus eventos/estados y
  `printing`. La verificación de PDF, la descarga y el enlace pasan por
  `ObtenerEnlacePdfDocumentoUseCase` / `DescargarPdfDocumentoUseCase` →
  `ServicioRepositoryImpl` → `ApiClient`
  ([servicio_repository_impl.dart:250-300](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L250)).
- Filtro por estado y búsqueda ahora los resuelve el BLoC
  (`MisServiciosFiltroEstadoCambiado`, `MisServiciosBusquedaCambiada`).
- Verificación de PDF limitada a 20 consultas por carga
  (`_maximoVerificacionesPdf`) y omitida si el listado ya trae el documento.
- Cubierto por [mis_servicios_pdf_test.dart](../test/features/servicios/mis_servicios_pdf_test.dart)
  (disponibilidad, ver, copiar enlace, 401, Bearer).

### 2.5 Liquidaciones (`lib/features/liquidaciones/`)

Sin cambios funcionales. `GET /liquidaciones/mias` con fallback sin paginación,
`GET /liquidaciones/:id/items` con carga incremental, 3 tabs
(Pendientes / Aprobadas / Reabiertas) en
[liquidaciones_screen.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart),
recarga al entrar a la pantalla.

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
ni `mocktail`.

---

## 3. Qué está a medias

Sigue sin haber `TODO`, `FIXME` ni mocks en `lib/`. Lo que está a medias lo
está por omisión:

1. **`km` sigue siendo `int`.** `Servicio.km` es `int?`
   ([servicio.dart:35](../lib/features/servicios/domain/entities/servicio.dart#L35))
   y el BLoC redondea (`kmCantidad.round()`,
   [servicio_bloc.dart:1382](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1382)),
   mientras el campo acepta decimales y `facturacion.kmCantidad` viaja con el
   valor decimal: con 12,5 km la orden guarda `km = 13` y factura 12,5.

2. **`km = 0` pasa la validación en campo.** `_validarFormulario` sólo exige que
   el campo no esté vacío y que no sea negativo
   ([servicio_bloc.dart:1299-1305](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1299)).
   El contrato actualizado de [endpoints.md](endpoints.md) dice que en `campo`
   `km` debe ser **mayor a 0** porque la liquidación automática lo exige: la app
   deja enviar una orden que el backend va a rechazar con 400.

3. **Rol del usuario sin verificar.** `Usuario.roles` se parsea y se persiste,
   pero nadie lo consulta: un usuario sin rol `tecnico` entra a la app igual.
   CLAUDE.md dice que esta app es sólo para `tecnico`.

4. **403 tratado distinto según la feature.** El 401 ya es global, pero
   `LiquidacionRepositoryImpl` sigue traduciendo **401 y 403** a
   `AuthException` y la pantalla despacha su propio `LogoutRequested`
   ([liquidaciones_screen.dart:32-37](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart#L32)).
   Resultado: un 403 desloguea en liquidaciones y en el resto de la app no; y un
   401 en liquidaciones dispara el cierre de sesión por dos caminos.

5. **Cola de pendientes no atada al usuario.** La clave
   `servicios_documentos_pendientes_v1` es global y `logout()` sólo borra token y
   usuario: si otro técnico inicia sesión en el mismo dispositivo, ve y reintenta
   los documentos pendientes del anterior con su propio token.

6. **Equipo obligatorio en todos los canales.** La app exige serie, modelo,
   ubicación y año para remoto y fábrica; el contrato permite omitir el equipo en
   remoto (body mínimo de [endpoints.md](endpoints.md)) y CLAUDE.md modela
   `equipoUbicacion`/`equipoAnio` como opcionales. No rompe nada, pero obliga al
   técnico de soporte remoto a inventar datos.

7. **Pendiente anotado por el autor** en [Progreso_app.md](../Progreso_app.md):
   "Quitar los filtros en mis servicios aprobados/pendientes". Los filtros siguen
   ([mis_servicios_page.dart:177](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L177)),
   ahora movidos al BLoC.

8. **Cobertura parcial.** Hay tests reales, pero no cubren `_validarFormulario`,
   `_recalcularFacturacion`, `LiquidacionDto`, catálogos ni ningún widget;
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

### 4.3 Otras ausencias

- **CI**: `.github/workflows/` no existe; ni `flutter analyze` ni `flutter test`
  corren automáticamente, aunque ahora hay 51 tests que valdría la pena proteger.
- **Configuración por entorno**: `baseUrl` sigue hardcodeada en
  [api_constants.dart:3](../lib/core/api/api_constants.dart#L3), sin
  `--dart-define` ni flavors (CLAUDE.md documenta `localhost:3000`, el código
  apunta a Render).
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
├── copilot-instructions.md         # casi idéntico al de .github/ (difieren ~130 líneas de diff)
├── plan_backend.html
├── pubspec.yaml
├── analysis_options.yaml
├── .github/
│   ├── copilot-instructions.md
│   ├── instructions/flutter-architecture.instructions.md
│   └── modernize/java-upgrade/hooks/   # ajeno al proyecto Flutter
├── docs/
│   ├── endpoints.md                          # fuente de verdad de la API (con cambios sin commitear)
│   ├── backend_feedback.postman_collection.json
│   ├── sistema_feedback_arquitectura.md
│   ├── flutter-tecnico-copilot-handoff.md
│   └── ESTADO.md                             # este documento
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

1. **Cerrar los desvíos de `km`.** Pasar `Servicio.km` a `double?` (entidad, DTO
   y PDF) y exigir `km > 0` en `_validarFormulario` cuando el canal es `campo`,
   con un test en `payload_servicio_contrato_test.dart`. Es chico y hoy genera
   400 del backend y datos inconsistentes.

2. **Aislar la cola de pendientes por usuario.** Incluir el id del técnico en la
   clave (o vaciar/descartar la cola al cerrar sesión, avisando si había
   documentos sin subir).

3. **Verificar el rol al loguear y al restaurar.** Si `roles` no incluye
   `tecnico`, no guardar sesión y mostrar un error claro.

4. **Unificar 401/403.** Quitar la traducción propia de
   `LiquidacionRepositoryImpl` y el `LogoutRequested` de la pantalla, dejando el
   401 en manos de `ApiClient`; decidir explícitamente qué hacer con 403.

5. **Relajar el equipo en remoto/fábrica** según el contrato (al menos
   ubicación y año opcionales, como en CLAUDE.md).

6. **Detalle y edición de órdenes** (`GET /servicios/:id` + `PATCH
   /servicios/:id`), empezando por el detalle desde "Mis servicios".

7. **CI** (`.github/workflows/flutter.yml`) con `flutter analyze` + `flutter
   test` en cada PR: los 51 tests ya justifican el workflow.

8. **Tests de lo que concentra más riesgo y aún no está cubierto**:
   `_validarFormulario`, `_recalcularFacturacion` (fijar primero la regla del
   descuento, ver §7.5) y `LiquidacionDto` contra los ejemplos de
   [endpoints.md](endpoints.md).

9. **Crear `lib/core/theme/app_theme.dart`** con `temaLight()`/`temaDark()` y
   `themeMode: ThemeMode.system`, y una `SplashPage` para `AuthLoading`.

10. **Parametrizar la `baseUrl`** con `--dart-define=API_BASE_URL=...`.

11. **Partir `formulario_servicio.dart`** (2.867 líneas) en un widget por paso
    y sacar de la vista el cálculo de facturación que duplica al BLoC (§7.1).

12. Resolver la nota de `Progreso_app.md` sobre los filtros de mis servicios, y
    actualizar [README.md](../README.md) y la `description` de `pubspec.yaml`.

---

## 7. Deuda técnica o problemas detectados

### 7.1 Lógica en las vistas

La violación más seria del relevamiento anterior (HTTP crudo en
`mis_servicios_page.dart`) **está resuelta**. Queda lógica menor en
[formulario_servicio.dart](../lib/features/servicios/presentation/widgets/formulario_servicio.dart):

- **Cálculo de facturación en el widget**: el paso de facturación recalcula
  subtotal de km, precio en ARS y montos de descuento con su propio
  `_doubleDesdeTextoLocal`
  ([formulario_servicio.dart:1620-1632](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1620)),
  en paralelo a `_recalcularFacturacion` del BLoC.
- **Normalización de partes en el widget**: `_normalizarParteFalladaBackend`
  ([formulario_servicio.dart:2785](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L2785))
  decide la parte a partir del nombre de la categoría al elegir productos.
- **Armado de la solicitud de firma en la vista**: el bottom sheet captura el
  trazo, decide qué campos de firma mandar según `agregarFirma` e inventa la
  `rutaPdfLocal` ([formulario_servicio.dart:585-605](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L585)).

### 7.2 Código duplicado

| Duplicación | Dónde |
|---|---|
| Normalización de "parte que falló" | `_normalizarParteFallada` en [servicio_bloc.dart:1600](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1600) **y** `_normalizarParteFalladaBackend` en [formulario_servicio.dart:2785](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L2785). Ambas ya mapean `web` correctamente, pero hay que mantenerlas en sincronía a mano |
| Extracción de `pdfUrl` del documento | `_extraerPdfUrl` en [servicio_dto.dart:483](../lib/features/servicios/infrastructure/dtos/servicio_dto.dart#L483) **y** `_extraerPdfUrlDesdeDocumento` en [servicio_repository_impl.dart:384](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L384) — se movió de la vista al repositorio, pero sigue duplicada |
| Helpers `_doubleDesdeDynamic` / `_intDesdeDynamic` / `_boolDesdeDynamic` | 7 archivos: `servicio_dto`, `orden_servicio_respuesta_dto`, `repuesto_dto`, `cotizacion_actual_dto`, `liquidacion_dto`, `catalogo_repository_impl`, `servicio_repository_impl` |
| Formateo de fecha dd/MM/yyyy | 5 copias: `servicio_bloc`, `formulario_servicio`, `generar_pdf_orden_servicio_use_case`, `mis_servicios_page`, `liquidaciones_screen` |
| Bucle de reintento de pendientes (`for` + `try` + `_quitarDocumentoPendiente`) | Dos copias casi literales dentro de `_onServicioDocumentoPendientesReintentarSolicitado` ([servicio_bloc.dart:734-830](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L734)) |
| `copilot-instructions.md` | En la raíz y en `.github/`; ya no son idénticos (divergieron), lo que empeora el problema: no está claro cuál vale |

### 7.3 Código muerto

- `ObtenerCatalogosUseCase.ejecutar()` y la clase `CatalogosData`
  ([obtener_catalogos_use_case.dart:8 y 82](../lib/features/catalogos/application/obtener_catalogos_use_case.dart#L8)).
- Evento `CargarCatalogos`: registrado pero nunca despachado.
- `ServicioInitial` ([servicio_state.dart:18](../lib/features/servicios/presentation/bloc/servicio_state.dart#L18)): nunca se emite.
- `ApiClient.patch()`, `ApiConstants.register`, `SecureStorage.borrarValor()`:
  sin uso (`borrarToken()` ya se usa desde el logout).
- `NetworkException`: declarada y nunca lanzada; los errores de red siguen
  cayendo en `ServerException` genéricos.
- `authRepository`, `catalogoRepository`, `servicioRepository` y
  `liquidacionRepository` expuestos como públicos en `AppDependencies` sin que
  nadie los lea desde afuera.
- Condicional redundante en `_asegurarCatalogosParaPaso`: dos `if` seguidos con
  la misma condición `(paso == 1 || paso == 2)`
  ([formulario_servicio.dart:59-67](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L59)).

### 7.4 Inconsistencias de estilo y convención

- **Indentación mezclada**: `servicios/`, `auth/`, `catalogos/` y `core/` usan
  tabuladores; `liquidaciones/` y ahora **todo `main.dart`** usan 2 espacios. No
  hay `.editorconfig`.
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

- **PDF en base64 dentro de `flutter_secure_storage`**
  ([servicio_repository_impl.dart:631](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L631)).
  El keystore no está pensado para blobs; con varias órdenes pendientes puede
  fallar. `rutaPdfLocal` sigue siendo un pseudo-URI `memoria://...` que no apunta
  a nada ([servicio_bloc.dart:1137](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1137)).
- **Cola de pendientes compartida entre usuarios** (ver §3.5).
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
- **Avisos de `flutter analyze`**: el import innecesario de `dart:typed_data` se
  fue con la refactorización de mis servicios. Quedan los tres
  `use_build_context_synchronously` del flujo de firma
  (`formulario_servicio.dart:570, 586, 605`), que pueden lanzar si el técnico
  cierra la hoja mientras se captura la firma.

### 7.6 Dependencias

**Todas las dependencias de `pubspec.yaml` están en uso**: `flutter_bloc`,
`equatable`, `http` + `http_parser`, `flutter_secure_storage`, `pdf` +
`printing`, `uuid`, `signature`, `cupertino_icons`. No hay paquetes huérfanos.
`JwtHelper` decodifica el token sin agregar dependencias.

En `dev_dependencies` siguen faltando `bloc_test` y `mocktail`/`mockito`.

---

## Porcentaje aproximado de avance: **≈ 86 %**

**Justificación.** El 78 % anterior correspondía a un camino crítico completo
pero con huecos de uso diario y de contrato. Desde entonces se cerraron
justamente esos huecos: sesión persistente, logout real, cierre de sesión global
ante 401, HTTP fuera de las vistas, `resolucionId` como array, parte `web` y
reglas por canal alineadas con el contrato actualizado. Además se pasó de 0 a 51
tests reales sobre las zonas que se tocaron. Eso recupera la mayor parte del
bloque de "funcionalidad desviada", buena parte de "deuda técnica" y una porción
de "calidad y verificación": **+8 puntos**.

El ≈ 14 % restante:

- **~5 % — funcionalidad faltante o desviada**: sin detalle ni edición de
  órdenes (`GET`/`PATCH /servicios/:id`), `km` entero y `km = 0` aceptado en
  campo, rol no verificado, cola de pendientes compartida entre usuarios, equipo
  obligatorio en remoto.
- **~5 % — calidad y verificación**: sin tests de validación, facturación,
  liquidaciones ni widgets; sin CI; sin configuración por entorno; sin
  `app_theme.dart` ni tema oscuro.
- **~4 % — deuda técnica**: formulario de 2.867 líneas con cálculo propio de
  facturación, cinco focos de duplicación, código muerto, indentación mezclada y
  los riesgos de §7.5 (blobs en secure storage, parseo por fuerza bruta,
  detección de error de firma por texto que ya no coincide con el backend,
  descuento ambiguo).

La app se puede usar en campo sin re-loguearse y cumple el contrato en los
puntos que más datos perdían. Lo que falta es, sobre todo, poder corregir una
orden ya cargada y blindar con tests y CI lo que ya funciona.
