# Estado del proyecto — App Flutter Técnico

> Documento generado a partir de una revisión del código fuente real del repo
> (`lib/`, `test/`, `pubspec.yaml`, `docs/`) el **12/09/2026**, contra la
> arquitectura declarada en [CLAUDE.md](../CLAUDE.md) (el archivo se titula
> internamente "AGENTS.md — App Flutter Técnico"; no existe un `AGENTS.md`
> separado en el repo).

---

## 1. Resumen

App Flutter del técnico para el sistema de servicio técnico de balanzas
electrónicas. Es el cliente móvil/web que consume la API NestJS del repo
`backend`: permite al técnico loguearse, cargar una orden de servicio completa
(canal, cliente, equipo, falla, diagnóstico, resolución, repuestos,
facturación), generar el PDF de la orden localmente, firmarlo y subirlo, ver sus
servicios cargados y consultar sus liquidaciones.

**Etapa: funcional, en desarrollo avanzado.** No es un esqueleto: el flujo
principal del técnico (login → carga de orden → POST /servicios → PDF → firma →
subida del documento) está implementado de punta a punta contra un backend real
(`https://backend-feedback-11c2.onrender.com/api/v1`), con idempotencia, cola
offline de documentos pendientes y manejo de errores tipado. Lo que falta es
mayormente **consolidación**: persistencia de sesión, cumplimiento de las reglas
por canal, tests, tema compartido y limpieza de deuda técnica acumulada.

Tamaño actual: **73 archivos Dart, ~11.100 líneas** en `lib/` + 1 test trivial.
`flutter analyze` pasa con 4 avisos `info` (ningún error ni warning).

---

## 2. Qué está implementado y funcionando

### 2.1 Infraestructura base (`lib/core/`)

| Pieza | Archivo | Estado |
|---|---|---|
| Cliente HTTP con JWT | [lib/core/api/api_client.dart](../lib/core/api/api_client.dart) | Completo: `get`, `post`, `patch`, `postMultipart`, header `Authorization: Bearer` inyectado automáticamente desde storage |
| Constantes de endpoints | [lib/core/api/api_constants.dart](../lib/core/api/api_constants.dart) | Completo, incluye helpers por id (`servicioDocumentoPdf`, `liquidacionItems`, …) |
| Storage seguro | [lib/core/auth/secure_storage.dart](../lib/core/auth/secure_storage.dart) | Completo: token + clave/valor genérico (usado para la cola offline) |
| Excepciones tipadas | [lib/core/error/failures.dart](../lib/core/error/failures.dart) | `ServerException`, `AuthException`, `NetworkException` — tal como pide la arquitectura (sin dartz/Either) |
| Inyección de dependencias | [lib/core/di/app_dependencies.dart](../lib/core/di/app_dependencies.dart) | Completo: 4 repositorios + 15 use cases cableados en un único `AppDependencies.create()`, sin get_it |
| Bootstrap de BLoCs | [lib/main.dart](../lib/main.dart) | `MultiBlocProvider` con `AuthBloc`, `CatalogoBloc`, `ServicioBloc`, `LiquidacionesBloc`; routing por `BlocBuilder<AuthBloc>` |

### 2.2 Auth (`lib/features/auth/`)

- `POST /auth/login` funcionando: [auth_repository_impl.dart](../lib/features/auth/infrastructure/repositories/auth_repository_impl.dart)
  guarda el `access_token` en secure storage y mapea 401 → `AuthException`.
- [login_page.dart](../lib/features/auth/presentation/pages/login_page.dart) (192 líneas):
  pantalla completa con gradiente, mostrar/ocultar contraseña, `BlocListener` de
  errores. Sin lógica de negocio en la vista.
- `AuthBloc` con `AppStarted` / `LoginSubmitted` / `LogoutRequested`.

### 2.3 Catálogos (`lib/features/catalogos/`)

Los 5 catálogos del formulario se consumen y parsean:
`GET /cat/diagnosticos`, `/cat/resoluciones`, `/zonas`, `/categorias-producto`,
`/productos?categoriaId=` — ver
[catalogo_repository_impl.dart](../lib/features/catalogos/infrastructure/repositories/catalogo_repository_impl.dart).

- [obtener_catalogos_use_case.dart](../lib/features/catalogos/application/obtener_catalogos_use_case.dart):
  `ejecutarBasicos()` paraleliza los 4 catálogos con `Future.wait`;
  `ejecutarProductosPorCategorias()` deduplica productos por id.
- [catalogo_bloc.dart](../lib/features/catalogos/presentation/bloc/catalogo_bloc.dart):
  **carga perezosa con caché** — no recarga si ya tiene datos, salvo `forzar: true`.
  El formulario sólo pide catálogos al entrar a los pasos que los necesitan
  ([formulario_servicio.dart:59-67](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L59)).

### 2.4 Servicios — el núcleo de la app (`lib/features/servicios/`)

**Formulario de carga** — [formulario_servicio.dart](../lib/features/servicios/presentation/widgets/formulario_servicio.dart) (2.845 líneas),
dividido en 5 pasos navegables por chips: `Tipo · Datos · Falla · Facturación · Observaciones`.

- **Canal**: chips de selección única (campo / remoto / fábrica).
- **Cliente**: búsqueda por nombre/CUIT (`GET /clientes/buscar?q=`), chips de
  resultados, tarjeta de resumen del cliente seleccionado y **alta rápida**
  (`POST /clientes`) en diálogo, con mensaje específico si el CUIT ya existe
  ([servicio_bloc.dart:437-447](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L437)).
- **Equipo**: modelo elegido desde el catálogo de indicadores + serie, ubicación, año.
- **Falla/diagnóstico/resolución**: selección múltiple de categorías de
  diagnóstico, productos que fallaron por parte, síntoma y detalle técnico
  multilínea, label de resolución que cambia según el canal
  (`_labelResolucion`, [formulario_servicio.dart:2744](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L2744)).
- **Repuestos**: búsqueda (`GET /repuestos?q=`) y selección desde
  `DropdownButtonFormField`, con cantidad editable y filtrado de los ya agregados.
- **Facturación**: `GET /cotizacion` + `GET /tarifa-km` con botón "Actualizar
  valores"; cálculo en vivo de subtotales (mano de obra / viático por km /
  repuestos), IVA y descuento; tabla de detalle responsive (tabla ≥860px,
  tarjetas compactas debajo).

**Alta de la orden** — [servicio_bloc.dart](../lib/features/servicios/presentation/bloc/servicio_bloc.dart) (1.326 líneas):

- Validación completa en el BLoC (`_validarFormulario`, 15 reglas) — nunca en la vista.
- **Idempotencia real**: `idempotencyKey` uuid v4 generado por orden, validado
  con regex y **reutilizado** en reintentos; el mensaje de éxito distingue
  `replayed` ([servicio_bloc.dart:494-497](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L494)).
- `fechaHoraServicio` ISO-8601 + `timezoneIana` + `utcOffsetMinutos` resueltos localmente.
- Construcción de `facturacionItems` (`mano_obra`, `viatico`, `repuesto`) y del
  bloque `facturacion` sin mandar los snapshots que completa el backend.
- `POST /servicios` en [servicio_repository_impl.dart](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart)
  con log del payload en debug y parseo tolerante de la respuesta.

**PDF y firma** — [generar_pdf_orden_servicio_use_case.dart](../lib/features/servicios/application/generar_pdf_orden_servicio_use_case.dart) (214 líneas):

- PDF A4 generado **localmente** con la respuesta del POST, sin segunda llamada:
  datos del cliente, datos técnicos, facturación, tabla de items y bloque de firma.
- Flujo de cierre (`_mostrarFlujoDocumentoCierre`): bottom sheet con vista previa
  (`Printing.layoutPdf`), captura de **firma manuscrita** (`Signature`), nombre y
  documento del firmante, y subida a `POST /servicios/:id/documento/firmado`
  (multipart). Si hay firma, el PDF se **regenera incluyendo el trazo** antes de subir.
- `PoliticaFirmaCanal` ([politica_firma_canal.dart](../lib/features/servicios/domain/entities/politica_firma_canal.dart))
  encapsula la regla "sólo `campo` admite firma", y el BLoC reintenta sin firma
  si el backend la rechaza ([servicio_bloc.dart:648-670](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L648)).

**Cola offline de documentos**: si la subida falla, la solicitud (PDF en base64
incluido) se persiste en secure storage bajo
`servicios_documentos_pendientes_v1` y se puede reintentar en lote desde
"Mis servicios" — `encolarDocumentoPendiente` / `obtenerDocumentosPendientes` /
`quitarDocumentoPendiente` en el repositorio + panel `_PanelPendientesDocumentos`.

**Mis servicios** — [mis_servicios_page.dart](../lib/features/servicios/presentation/pages/mis_servicios_page.dart) (943 líneas):
`GET /servicios/mios`, buscador por síntoma/modelo/serie/ID, filtros por estado,
orden por fecha descendente, verificación de si el PDF ya está en el servidor,
ver PDF, copiar enlace y "subir PDF ahora".

### 2.5 Liquidaciones (`lib/features/liquidaciones/`)

Feature completa y la mejor estructurada del repo (única con `datasources/` separado):

- `GET /liquidaciones/mias?estado=&page=&limit=` con **fallback automático sin
  paginación** si el backend rechaza `page`/`limit`
  ([liquidacion_repository_impl.dart:88-113](../lib/features/liquidaciones/infrastructure/repositories/liquidacion_repository_impl.dart#L88)).
- `GET /liquidaciones/:id/items` para el detalle por liquidación, con carga
  incremental por id y estado de "cargando" por fila.
- 401/403 → `AuthException` → estado `LiquidacionesSesionExpirada` → logout automático.
- [liquidaciones_screen.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_screen.dart) (760 líneas):
  3 tabs (Pendientes / Aprobadas / Reabiertas), header con total USD aprobado y
  contadores, pull-to-refresh, detalle expandible con items y precios.

---

## 3. Qué está a medias

No hay un solo `TODO`, `FIXME` ni mock en `lib/` — la búsqueda no devuelve
ninguna coincidencia. Lo que está a medias está a medias **por omisión**, no por
marcadores:

1. **Sesión no persistente.** `AuthBloc._onAppStarted` emite
   `AuthUnauthenticated` incondicionalmente
   ([auth_bloc.dart:17-19](../lib/features/auth/presentation/bloc/auth_bloc.dart#L17)):
   el token queda guardado en secure storage pero **nunca se lee al arrancar**,
   así que el técnico se loguea de nuevo en cada apertura de la app.

2. **Logout vacío.** `AuthRepositoryImpl.logout()` es un `return;` sin cuerpo
   ([auth_repository_impl.dart:66-69](../lib/features/auth/infrastructure/repositories/auth_repository_impl.dart#L66)),
   no borra el token; `AuthBloc._onLogoutRequested` ni siquiera lo invoca (no
   existe `LogoutUseCase`). Además **no hay ningún botón de logout en la UI**: el
   único disparador de `LogoutRequested` es la expiración de sesión en la pantalla
   de liquidaciones.

3. **`Usuario` casi vacío tras el login.** Si la respuesta del login no trae un
   objeto `usuario`, se devuelve un `UsuarioDto(id: '', nombre: 'Tecnico', …)`
   hardcodeado ([auth_repository_impl.dart:40-45](../lib/features/auth/infrastructure/repositories/auth_repository_impl.dart#L40)).
   El JWT no se decodifica, así que el **rol nunca se verifica** pese a que la
   arquitectura dice que "el JWT trae el rol".

4. **Reglas por canal no aplicadas al formulario.** `CLAUDE.md` especifica que
   `lugarProvinciaId`, `lugarDetalle` y `km` aplican **sólo a `campo`**, y que en
   remoto/fábrica el backend completa el lugar. En el código:
   - los campos de zona y lugar se muestran siempre, sin condicional por canal
     ([formulario_servicio.dart:1250-1265](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1250));
   - `_validarFormulario` exige zona y lugar **para los tres canales**
     ([servicio_bloc.dart:970-976](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L970));
   - el campo km está siempre visible en el paso de facturación.

   Sólo el *label* cambia por canal (`_labelLugarDetalle`, `_labelResolucion`).

5. **`resolucionId` modelado como valor único, no como array.** La arquitectura
   lo marca explícitamente como array. En el código es un `String`:
   - entidad: [servicio.dart:36](../lib/features/servicios/domain/entities/servicio.dart#L36);
   - al enviar se envuelve en lista de un elemento
     (`resolucionId.trim().isEmpty ? [] : [resolucionId]`,
     [servicio_dto.dart:243](../lib/features/servicios/infrastructure/dtos/servicio_dto.dart#L243));
   - al recibir se descarta todo menos el primero (`_primerValorListaOString`).

   Es decir: **si el backend devuelve más de una resolución, la app pierde el resto.**
   (`diagnosticoCatIds` y `partesFallaron` sí son `List`, correctamente.)

6. **`km` es `int`, no decimal.** `Servicio.km` es `int` y el BLoC redondea
   (`kmCantidad.round()`, [servicio_bloc.dart:1073](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1073))
   aunque la UI acepta decimales y el cálculo del viático usa el valor decimal:
   el PDF y el payload pueden no coincidir con lo que se le mostró al técnico.

7. **Parte `web` inexistente.** El set de partes permitidas
   (`_partesFallaronPermitidas`, [servicio_bloc.dart:29-36](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L29))
   omite `web`, y el normalizador mapea cualquier texto con "web" a `app_pc`.
   `CLAUDE.md` lista `indicador|celda|app_movil|app_pc|tablet|web|otro`.

8. **`PATCH /servicios/:id` sin usar.** `ApiClient.patch` existe pero no lo llama
   nadie: **no se puede editar una orden ya cargada.**

9. **Pendientes anotados por el propio autor** en
   [Progreso_app.md](../Progreso_app.md) y no resueltos: "Quitar los filtros en
   mis servicios aprobados/pendientes" (los filtros siguen ahí,
   [mis_servicios_page.dart:602](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L602)).

10. **Tests inexistentes en la práctica.** [test/widget_test.dart](../test/widget_test.dart)
    tiene 16 líneas y **no importa la app**: monta un `MaterialApp` con un
    `Text('Smoke test')`. Cobertura real: 0%.

---

## 4. Qué falta por completo

Contrastado contra la estructura y los endpoints declarados en [CLAUDE.md](../CLAUDE.md):

### 4.1 Carpetas de la arquitectura que no existen

| Declarado en CLAUDE.md | Estado real |
|---|---|
| `lib/core/theme/app_theme.dart` | **No existe.** El tema está inline en [main.dart:57-88](../lib/main.dart#L57), sólo `theme` claro — sin `darkTheme` ni `themeMode: ThemeMode.system`, que la arquitectura muestra explícitamente en su snippet de `main.dart`. La convención "usar siempre widgets y colores de `app_theme.dart`" no se puede cumplir. |
| `lib/core/widgets/` | **No existe.** No hay widgets compartidos; cada página redefine sus helpers. |
| `lib/features/clientes/` | **No existe** como feature. Cliente vive dentro de `servicios/` (entidad, DTO, use cases de buscar/crear). |
| `lib/features/repuestos/` | **No existe** como feature. Repuesto vive dentro de `servicios/`. |
| `SplashPage` | **No existe.** En `AuthLoading` se muestra un `CircularProgressIndicator` suelto. |

### 4.2 Endpoints listados para este repo y nunca invocados

- `GET /clientes/:id` — la arquitectura dice "al seleccionar el cliente se traen
  todos sus datos automáticamente"; hoy se usan los datos que ya vinieron en el
  resultado de búsqueda, sin segunda llamada.
- `GET /servicios/:id` — no hay pantalla de detalle de una orden.
- `PATCH /servicios/:id` — no hay edición de órdenes.
- `POST /servicios/:id/repuestos` y `GET /servicios/:id/repuestos` — los repuestos
  sólo viajan embebidos en `facturacionItems` del POST inicial; no se pueden
  agregar ni consultar después.
- `/auth/register` — constante declarada en `api_constants.dart` pero sin uso
  (probablemente correcto: el técnico no se auto-registra).

### 4.3 Otras ausencias

- **Tests de cualquier tipo**: no hay tests de BLoC, de use cases, de DTOs
  (`fromJson`/`toJson`) ni de widgets. No hay `mocktail`/`bloc_test` en
  `dev_dependencies`.
- **Configuración por entorno**: la `baseUrl` está hardcodeada como `const` en
  [api_constants.dart:3](../lib/core/api/api_constants.dart#L3), con la URL de
  devtunnel comentada arriba. No hay `--dart-define`, flavors ni `.env`, así que
  cambiar de entorno exige editar el código y recompilar. (Nota: la arquitectura
  documenta `http://localhost:3000/api/v1`; el código apunta a Render.)
- **Manejo de 401 fuera de liquidaciones**: sólo `LiquidacionRepositoryImpl`
  traduce 401/403 a `AuthException`. En servicios y catálogos un token vencido se
  convierte en un `ServerException` genérico, sin redirigir al login.
- **CI**: `.github/` contiene instrucciones de Copilot y hooks de un plugin de
  modernización Java, pero **ningún workflow** (`.github/workflows/` no existe):
  no corren ni `flutter analyze` ni `flutter test` automáticamente.
- **README real**: [README.md](../README.md) sigue siendo el template
  autogenerado de Flutter ("A new Flutter project"), igual que la `description`
  de `pubspec.yaml`.

---

## 5. Estructura actual del proyecto

```
cliente_feedback_tecnico/
├── CLAUDE.md                       # arquitectura de referencia (titulado "AGENTS.md")
├── Progreso_app.md                 # notas de avance del autor
├── copilot-instructions.md         # guía extensa (duplicada en .github/)
├── plan_backend.html
├── pubspec.yaml
├── analysis_options.yaml
├── .github/
│   ├── copilot-instructions.md
│   ├── instructions/flutter-architecture.instructions.md
│   └── modernize/java-upgrade/hooks/   # ajeno al proyecto Flutter
├── docs/
│   ├── endpoints.md                          # fuente de verdad de la API
│   ├── backend_feedback.postman_collection.json
│   ├── sistema_feedback_arquitectura.md
│   ├── flutter-tecnico-copilot-handoff.md
│   └── ESTADO.md                             # este documento
├── test/
│   └── widget_test.dart            # 16 líneas, no toca la app
├── android/ · ios/ · web/ · windows/ · linux/ · macos/
└── lib/
    ├── main.dart                                    (109)
    ├── core/
    │   ├── api/            api_client.dart (72) · api_constants.dart (38)
    │   ├── auth/           secure_storage.dart (33)
    │   ├── di/             app_dependencies.dart (122)
    │   └── error/          failures.dart (18)
    └── features/
        ├── auth/
        │   ├── application/         login_use_case.dart
        │   ├── domain/              entities/usuario.dart · repositories/i_auth_repository.dart
        │   ├── infrastructure/      dtos/usuario_dto.dart · repositories/auth_repository_impl.dart (70)
        │   └── presentation/        bloc/{auth_bloc,auth_event,auth_state}.dart
        │                            pages/login_page.dart (192)
        ├── catalogos/
        │   ├── application/         obtener_catalogos_use_case.dart (94)
        │   ├── domain/              entities/{cat_diagnostico,cat_resolucion,categoria_producto,
        │   │                                  producto,zona}.dart · repositories/i_catalogo_repository.dart
        │   ├── infrastructure/      repositories/catalogo_repository_impl.dart (163)
        │   └── presentation/        bloc/{catalogo_bloc,catalogo_event,catalogo_state}.dart
        ├── servicios/
        │   ├── application/         11 use cases (buscar_clientes, buscar_repuestos,
        │   │                        cargar_servicio, crear_cliente_rapido,
        │   │                        generar_pdf_orden_servicio (214), obtener_cotizacion_actual,
        │   │                        obtener_mis_servicios, subir_documento_firmado,
        │   │                        encolar/obtener/quitar_documento_pendiente)
        │   ├── domain/
        │   │   ├── entities/        servicio.dart (121) · cliente · repuesto · facturacion ·
        │   │   │                    facturacion_item · producto_falla · documento_orden ·
        │   │   │                    orden_servicio_respuesta · cotizacion_actual ·
        │   │   │                    solicitud_documento_firmado · politica_firma_canal
        │   │   └── repositories/    i_servicio_repository.dart
        │   ├── infrastructure/
        │   │   ├── dtos/            servicio_dto.dart (572) · orden_servicio_respuesta_dto (184) ·
        │   │   │                    cotizacion_actual_dto · repuesto_dto · cliente_dto
        │   │   └── repositories/    servicio_repository_impl.dart (527)
        │   └── presentation/
        │       ├── bloc/            servicio_bloc.dart (1326) · servicio_state.dart (406) ·
        │       │                    servicio_event.dart (227)
        │       ├── pages/           nueva_orden_servicio_page.dart (43) ·
        │       │                    mis_servicios_page.dart (943)
        │       └── widgets/         formulario_servicio.dart (2845)
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

1. **Restaurar la sesión al arrancar.** En `AuthBloc._onAppStarted`, leer el token
   de `SecureStorage` y emitir `AuthAuthenticated` si existe. Es el bug de UX más
   caro: hoy el técnico en campo se re-loguea en cada apertura.

2. **Cerrar el ciclo de logout.** Implementar `AuthRepositoryImpl.logout()` para
   borrar el token (`borrarToken()` ya existe y no lo usa nadie), crear
   `LogoutUseCase` y agregar el botón en el `AppBar` de
   [nueva_orden_servicio_page.dart](../lib/features/servicios/presentation/pages/nueva_orden_servicio_page.dart).

3. **Aplicar las reglas por canal.** Ocultar zona/lugar/km cuando el canal es
   `remoto` o `fabrica`, y hacer condicionales las validaciones correspondientes
   en `_validarFormulario`. Hoy el técnico en remoto está obligado a inventar una
   provincia y un lugar.

4. **Convertir `resolucionId` en `List<String>`** en entidad, DTO, estado y
   formulario (chips de selección múltiple, como ya se hace con
   `diagnosticoCatIds`), y **agregar `web`** a `_partesFallaronPermitidas`.
   Ambos son desvíos directos de la especificación que hoy pierden datos.

5. **Sacar el HTTP crudo de `mis_servicios_page.dart`** (ver §7.1). Mover las 3
   llamadas a `ServicioRepositoryImpl` + use cases, y exponer el resultado por
   estados del `ServicioBloc`.

6. **Uniformar el manejo de 401.** Que `ServicioRepositoryImpl` y
   `CatalogoRepositoryImpl` lancen `AuthException` en 401/403 como ya hace
   `LiquidacionRepositoryImpl`, y que los BLoCs propaguen un estado de sesión
   expirada que dispare `LogoutRequested`.

7. **Crear `lib/core/theme/app_theme.dart`** con `temaLight()` / `temaDark()`,
   mover el tema de `main.dart` y activar `themeMode: ThemeMode.system`, como
   describe la arquitectura.

8. **Primeros tests**, empezando por lo que más riesgo concentra:
   `ServicioBloc._validarFormulario` y `_recalcularFacturacion`,
   `ServicioDto.fromJson/toJson` contra los ejemplos reales de
   [docs/endpoints.md](endpoints.md), y `LiquidacionDto`. Agregar `bloc_test` y
   `mocktail`.

9. **Parametrizar la `baseUrl`** con `--dart-define=API_BASE_URL=...` y
   `String.fromEnvironment`, para dejar de editar código al cambiar de entorno.

10. **Partir `formulario_servicio.dart`** (2.845 líneas) en widgets por paso
    (`paso_tipo.dart`, `paso_datos.dart`, `paso_falla.dart`,
    `paso_facturacion.dart`, `paso_observaciones.dart`) dentro de
    `servicios/presentation/widgets/`.

11. **Workflow de CI** (`.github/workflows/flutter.yml`) con
    `flutter analyze` + `flutter test` en cada PR.

12. Actualizar [README.md](../README.md) y la `description` de `pubspec.yaml`,
    que siguen siendo el template de Flutter.

---

## 7. Deuda técnica o problemas detectados

### 7.1 Violación de la regla fundamental: "las vistas no tienen lógica"

Es el problema más serio del repo.
[mis_servicios_page.dart](../lib/features/servicios/presentation/pages/mis_servicios_page.dart)
importa `package:http`, `SecureStorage` y `ApiConstants` y **hace peticiones HTTP
directamente desde el `State` del widget**, saltándose `ApiClient`, el
repositorio, el use case y el BLoC:

- línea [251](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L251) y [261](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L261) — `_dispararVerificacionPdf`: lee el token y llama `GET /servicios/:id/documento`
- línea [323](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L323) y [336](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L336) — `_verPdfServicio`: descarga `GET /servicios/:id/documento/pdf`
- línea [387](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L387) y [401](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L401) — `_copiarEnlacePdf`: pide la metadata del documento

Además arma el header `Authorization` a mano y construye URLs concatenando
`ApiConstants.baseUrl`, duplicando responsabilidades de `ApiClient`.

### 7.2 Código duplicado

| Duplicación | Dónde |
|---|---|
| Normalización de "parte que falló" (la misma cadena de ~10 `if`) | `_normalizarParteFallada` en [servicio_bloc.dart:1294](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L1294) **y** `_normalizarParteFalladaBackend` en [formulario_servicio.dart:2766](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L2766) — la segunda, además, es lógica de negocio dentro de un widget |
| Extracción de `pdfUrl` del documento (mismas 6 claves + objetos `pdf`/`archivo`) | `_extraerPdfUrl` en [servicio_dto.dart:487](../lib/features/servicios/infrastructure/dtos/servicio_dto.dart#L487) **y** `_extraerPdfUrlDesdeDocumento` en [mis_servicios_page.dart:489](../lib/features/servicios/presentation/pages/mis_servicios_page.dart#L489) |
| Helpers de parseo `_doubleDesdeDynamic` / `_intDesdeDynamic` / `_boolDesdeDynamic` | Reimplementados en al menos 5 archivos: `servicio_dto.dart`, `repuesto_dto.dart`, `cotizacion_actual_dto.dart`, `liquidacion_dto.dart`, `catalogo_repository_impl.dart`, `servicio_repository_impl.dart` — candidatos claros a un `core/utils/parseo_json.dart` |
| `_formatearFechaHora` (dd/MM/yyyy HH:mm) | 3 copias: bloc, widget del formulario y use case del PDF |
| Bloque completo de reintento de pendientes (`for` + `try` + `quitarDocumentoPendiente`) | Repetido casi literal para `MisServiciosLoaded` y para el formulario en [servicio_bloc.dart:711-800](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L711) |
| `copilot-instructions.md` | Idéntico en la raíz y en `.github/` |

### 7.3 Código muerto

- `ObtenerCatalogosUseCase.ejecutar()` y la clase `CatalogosData` completa
  ([obtener_catalogos_use_case.dart:8 y 82](../lib/features/catalogos/application/obtener_catalogos_use_case.dart#L8)):
  nadie los llama; el bloc usa `ejecutarBasicos()` + `ejecutarProductosPorCategorias()`.
- Evento `CargarCatalogos`: registrado en el bloc pero **nunca despachado** desde la UI.
- `ServicioInitial` ([servicio_state.dart:17](../lib/features/servicios/presentation/bloc/servicio_state.dart#L17)): nunca se emite.
- `ApiClient.patch()`, `ApiConstants.register`, `SecureStorage.borrarToken()`,
  `SecureStorage.borrarValor()`: sin uso.
- Campos `authRepository` y `catalogoRepository` expuestos como públicos en
  `AppDependencies` pero sólo consumidos internamente al construir los use cases.
- `NetworkException` declarada y nunca lanzada — los errores de red caen en el
  `catch (_)` genérico que emite `ServerException`.
- Condicional redundante en `_asegurarCatalogosParaPaso`: dos `if` consecutivos
  con la **misma** condición `(paso == 1 || paso == 2)`
  ([formulario_servicio.dart:59-67](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L59)).

### 7.4 Inconsistencias de estilo y convención

- **Indentación mezclada**: la mayor parte del repo usa tabuladores, pero toda la
  feature `liquidaciones/` usa 2 espacios. `lib/main.dart` mezcla ambos dentro del
  mismo archivo (es justamente lo que arregla el cambio sin commitear que hay hoy
  en el working tree). Falta un `.editorconfig` y no se corre `dart format`.
- **`failures.dart` no contiene ningún `Failure`**: contiene excepciones. El
  nombre viene de un patrón (dartz/Either) que la arquitectura descarta
  explícitamente; debería llamarse `exceptions.dart`.
- **Nombre de la carpeta**: `features/liquidaciones/` vs `liquidacion/` en el
  árbol de `CLAUDE.md` (menor, pero conviene fijar uno).
- **Pantalla inicial**: `CLAUDE.md` la llama `NuevoServicioPage`; el código,
  `NuevaOrdenServicioPage`.
- Sufijo `Screen` en `LiquidacionesScreen` frente a `Page` en todo el resto.

### 7.5 Riesgos funcionales concretos

- **PDF en base64 dentro de `flutter_secure_storage`.** La cola de documentos
  pendientes serializa el PDF completo a base64 y lo guarda en el keystore
  ([servicio_repository_impl.dart:492](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L492)).
  El secure storage no está pensado para blobs; con varias órdenes pendientes esto
  puede fallar o degradarse mucho. Lo correcto sería guardar el archivo en disco y
  persistir sólo la ruta (el campo `rutaPdfLocal` ya existe, pero hoy es un
  pseudo-URI `memoria://...` que no apunta a nada).
- **Búsqueda de cotización "a fuerza bruta".** `_buscarValorPorClaves`
  ([servicio_repository_impl.dart:390](../lib/features/servicios/infrastructure/repositories/servicio_repository_impl.dart#L390))
  recorre recursivamente todo el JSON probando ~7 nombres de clave posibles,
  incluido el genérico `'valor'`. Es frágil: puede levantar un número equivocado
  de cualquier parte de la respuesta. El shape exacto está en
  [docs/endpoints.md](endpoints.md) y debería parsearse explícitamente.
- **Detección de errores de firma por texto.** `_esErrorFirmaNoPermitida`
  ([servicio_bloc.dart:958](../lib/features/servicios/presentation/bloc/servicio_bloc.dart#L958))
  decide si reintentar buscando las palabras "firma" + "canal"/"remoto"/"fabrica"
  en el mensaje del backend: cualquier cambio de wording del lado del servidor lo
  rompe en silencio.
- **Cálculo del descuento ambiguo.** En `_recalcularFacturacion` el descuento se
  aplica **después** del IVA (`totalConIvaArs * factorDescuento`), mientras que en
  la UI se muestra también un `descuentoMontoUsd` calculado **sobre el subtotal
  bruto** ([formulario_servicio.dart:1614](../lib/features/servicios/presentation/widgets/formulario_servicio.dart#L1614)).
  Los dos números no describen la misma operación; conviene fijar la regla con el
  backend y calcularla en un solo lugar.
- **Los 4 avisos de `flutter analyze`** (ninguno bloqueante, todos reales):
  un import innecesario de `dart:typed_data` en `mis_servicios_page.dart:2` y tres
  `use_build_context_synchronously` en el flujo de firma
  (`formulario_servicio.dart:570, 586, 605`) — este último puede causar
  excepciones si el usuario cierra la hoja mientras sube el documento.

### 7.6 Dependencias

**Todas las dependencias de `pubspec.yaml` están en uso**: `flutter_bloc` y
`equatable` (todos los BLoCs), `http` + `http_parser` (ApiClient y multipart),
`flutter_secure_storage` (token y cola), `pdf` + `printing` (generación y vista
previa), `uuid` (idempotencia), `signature` (firma manuscrita), `cupertino_icons`
(default del template). No hay paquetes huérfanos.

Lo que **falta** en `dev_dependencies`: `bloc_test` y `mocktail`/`mockito` para
poder testear BLoCs y repositorios.

---

## Porcentaje aproximado de avance: **≈ 78 %**

**Justificación.** El camino crítico del técnico está terminado y es sólido: los
tres BLoCs principales, los 15 use cases, los 4 repositorios y los DTOs completos
están implementados contra un backend real, con idempotencia, generación local de
PDF, firma manuscrita, cola offline de reintento y las tres pantallas del flujo
(carga de orden, mis servicios, liquidaciones). Eso es la mayor parte del
producto y explica el grueso del porcentaje.

El 22 % restante se reparte en tres bloques de tamaño parecido:

- **~8 % — funcionalidad faltante o desviada**: sesión no persistente, logout sin
  implementar, reglas por canal no aplicadas, `resolucionId` como valor único,
  parte `web` ausente, sin edición de órdenes (`PATCH /servicios/:id`), sin
  detalle de orden (`GET /servicios/:id`).
- **~7 % — calidad y verificación**: 0 % de cobertura de tests, sin CI, sin
  configuración por entorno, sin `app_theme.dart` ni tema oscuro.
- **~7 % — deuda técnica**: HTTP crudo en una vista, seis focos de duplicación,
  código muerto, indentación mezclada y los riesgos funcionales de §7.5 (blobs en
  secure storage, parseo por fuerza bruta, detección de errores por texto,
  descuento ambiguo).

Nada de eso impide que la app se use hoy; todo eso impide que se pueda mantener
y extender con confianza.
