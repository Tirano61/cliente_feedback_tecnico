# AGENTS.md — App Flutter Técnico

## Descripción general del sistema

Sistema de gestión de servicio técnico para balanzas electrónicas de uso agropecuario. Este repo es la app del técnico: compila a dos targets desde el mismo código, APK Android para el técnico en campo y Flutter Web para el técnico en taller/PC. Contiene únicamente las pantallas del técnico. El panel de administración y el de feedback/desarrollo son repos separados.

Es uno de cuatro repos:
- **backend** — NestJS + PostgreSQL (API compartida)
- **app-tecnico** — este repo
- **admin-web** — administración y liquidaciones (repo separado)
- **feedback-web** — análisis de fallas (repo separado)

---

## Fuentes de verdad para los modelos

Para armar los modelos de parseo y los shapes exactos de request/response, usar SIEMPRE estos archivos del repo backend:
- `endpoints.md` — todos los endpoints con ejemplos de payload y respuesta
- `backend_feedback_postman_collection.json` — colección Postman con requests reales

No inventar campos ni estructuras — copiarlos de esos archivos.

---

## Stack

- **Flutter** — un solo proyecto, dos targets: APK Android y Flutter Web
- **Backend** — NestJS en `http://localhost:3000/api/v1`
- **Estado** — flutter_bloc + equatable
- **HTTP** — http (no Dio). JWT agregado en ApiClient wrapper
- **Storage** — flutter_secure_storage para el token
- **DI** — clase `AppDependencies` instanciada en main, sin get_it
- **BLoCs** — MultiBlocProvider en main.dart
- **Errores** — excepciones tipadas, estados de error en cada BLoC. Sin dartz ni Either
- **PDF** — generación local de la orden a partir de la respuesta de POST /servicios
- **Routing** — Navigator 2.0 nativo via BlocBuilder en MaterialApp

---

## Regla fundamental de arquitectura

**Las vistas no tienen lógica.** Solo renderizan estado con `BlocBuilder`, escuchan efectos con `BlocListener` y despachan eventos con `context.read<XBloc>().add(XEvent())`. Cero lógica de negocio, cero llamadas a repositorios fuera de los BLoCs.

---

## Rol de este repo

Solo `tecnico`. El login usa el mismo endpoint que las otras apps; el JWT trae el rol. Un usuario con rol admin no usa esta app (usa los paneles web).

---

## Flujo del técnico — carga de un servicio

1. Login → guarda el JWT
2. Selecciona el canal (campo / remoto / fábrica) — define qué campos aparecen
3. Busca el cliente por CUIT o nombre (`GET /clientes/buscar?q=`). Si no existe, lo crea (`POST /clientes`)
4. Al seleccionar el cliente, se traen todos sus datos automáticamente
5. Describe el equipo: n° de serie del indicador, modelo, "colocada en", año estimado
6. Marca las partes que fallaron (selección múltiple, mínimo 1)
7. Carga síntoma, diagnóstico (categoría + detalle) y resolución
8. Agrega repuestos usados (`GET /repuestos?q=`) con cantidad
9. En campo: ingresa km recorridos
10. Guarda con `POST /servicios` incluyendo un `idempotencyKey` único
11. Genera y comparte el PDF con la respuesta (sin segunda llamada)
12. Opcionalmente sube el PDF firmado (`POST /servicios/:id/documento/firmado`)

---

## Estructura del payload POST /servicios (ver shape completo en endpoints.md)

```
idempotencyKey        uuid generado en la app — MISMA clave si se reintenta
fechaHoraServicio     ISO-8601 con offset local
timezoneIana          America/Argentina/Buenos_Aires
utcOffsetMinutos      -180
canal                 campo | remoto | fabrica
clienteId             del cliente seleccionado
lugarProvinciaId      FK zona — solo campo
lugarDetalle          texto — solo campo (en remoto/fábrica lo pone el backend)
equipoNroSerie        del indicador
equipoModelo          ej: ST455
equipoUbicacion       campo libre ej: "Cestari 14"
equipoAnio            año estimado
partesFallaron        ARRAY: indicador|celda|app_movil|app_pc|tablet|web|otro
km                    solo campo
sintoma               texto libre
diagnosticoDetalle    texto libre
diagnosticoCatId      ARRAY de FK — puede ser más de una categoría
resolucionId          ARRAY de FK — puede ser más de una resolución
observaciones         opcional
productosFalla        ARRAY de { parteFallo, productoFallaId }
facturacion           subtotales, IVA, descuento, totales USD y ARS
facturacionItems      ARRAY: tipoItem mano_obra|viatico|repuesto
documento             pdfHashSha256, pdfUrl, datos de firma (todo null al crear)
```

**Importante**: `diagnosticoCatId`, `resolucionId` y `partesFallaron` son **arrays**. Modelarlos como List, no como valor único.

### Idempotencia

- La app genera un `idempotencyKey` (uuid) por cada orden nueva
- Si falla la red y se reintenta, se manda la MISMA clave — el backend devuelve la orden ya creada (`replayed = true`) sin duplicar
- Nunca regenerar la clave en un reintento del mismo formulario

### Facturación

- La app calcula los `facturacionItems` (mano de obra, viático por km, repuestos)
- El backend completa `cotizacionDolarSnapshot` y `valorKmUsdSnapshot` con los valores activos — la app no los manda
- Debe haber al menos un item `mano_obra`
- La respuesta de POST trae todo lo necesario para generar el PDF sin otra llamada

### Canal y campos

| Campo | campo | remoto | fábrica |
|---|---|---|---|
| lugarProvinciaId | requerido | no aplica | no aplica |
| lugarDetalle | requerido | automático "Soporte remoto" | automático "Fábrica" |
| km | requerido | no aplica | no aplica |
| Label resolución | "Resolución" | "Resultado del contacto" | "Trabajo realizado" |

Solo `canal = campo` genera liquidación (la crea el backend automáticamente).

---

## Documento y firma

- La app genera el PDF localmente con la respuesta de POST /servicios
- Puede subir el PDF firmado con `POST /servicios/:id/documento/firmado` (multipart: file + datos de firma opcionales)
- En campo: se puede subir sin firma (cliente ausente); con firma válida la orden pasa a `firmada`
- En remoto/fábrica: se sube sin firma; si se manda firma el backend la rechaza
- Estados de orden: `abierta` → `cerrada` → `firmada`

---

## Endpoints que usa este repo

Base URL: `http://localhost:3000/api/v1` · Header `Authorization: Bearer <token>`

```
// Auth
POST /auth/login       body: { email, password } → { access_token }

// Cliente (buscar, ver, crear)
GET  /clientes/buscar?q=
GET  /clientes/:id
POST /clientes             body: { cuit, nombre, contacto?, telefono?, localidad? }

// Repuestos (solo lectura)
GET  /repuestos?q=

// Catálogos (solo lectura, para poblar el formulario)
GET  /cat/diagnosticos
GET  /cat/resoluciones
GET  /zonas
GET  /categorias-producto
GET  /productos?categoriaId=
GET  /cotizacion           para mostrar el valor en pesos de los repuestos
GET  /tarifa-km            para calcular el viático por km

// Servicios
POST  /servicios
GET   /servicios/mios
GET   /servicios/:id
PATCH /servicios/:id
POST  /servicios/:id/repuestos          body: { repuestoId, cantidad }
GET   /servicios/:id/repuestos
GET   /servicios/:id/documento
GET   /servicios/:id/documento/pdf
POST  /servicios/:id/documento/firmado  multipart/form-data

// Liquidación (el técnico solo ve las suyas)
GET  /liquidaciones/mias?estado=
```

Este repo NO usa endpoints de administración (aprobar liquidaciones, administrar precios/catálogos, pagos, técnicos, analytics).

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
  final String fullName;
  final String email;
  final List<String> roles;
}
```

### Cliente
```dart
class Cliente extends Equatable {
  final String id;
  final String cuit;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? localidad;
}
```

### Servicio (campos principales — ver endpoints.md para el shape completo)
```dart
class Servicio extends Equatable {
  final String id;
  final Canal canal;
  final String clienteId;
  final String? lugarProvinciaId;
  final String? lugarDetalle;
  final String equipoNroSerie;
  final String equipoModelo;
  final String? equipoUbicacion;
  final int? equipoAnio;
  final List<String> partesFallaron;
  final double? km;
  final String sintoma;
  final String diagnosticoDetalle;
  final List<String> diagnosticoCatId;   // ARRAY
  final List<String> resolucionId;       // ARRAY
  final String? observaciones;
  final List<ProductoFalla> productosFalla;
  final DateTime fechaHoraServicio;
}
```

### Repuesto
```dart
class Repuesto extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final double precioUsd;
  final bool activo;
}
```

---

## Estructura de carpetas — DDD

```
lib/
├── core/
│   ├── api/           # ApiClient con JWT
│   ├── auth/          # SecureStorage
│   ├── error/         # Excepciones tipadas
│   ├── di/            # AppDependencies
│   ├── theme/         # app_theme.dart
│   └── widgets/       # widgets compartidos
│
├── features/
│   ├── auth/          # Login
│   ├── catalogos/     # Catálogos para el formulario
│   ├── clientes/      # Buscar y crear cliente
│   ├── servicios/     # Formulario de carga + mis servicios + PDF
│   ├── repuestos/     # Buscador de repuestos
│   └── liquidacion/   # Ver mi liquidación
│
└── main.dart
```

---

## Formulario del técnico — orden de campos

1. Canal — chips selección única (campo / remoto / fábrica)
2. Buscar cliente — autocomplete por CUIT o nombre + botón crear
3. Provincia — dropdown de zonas (solo campo)
4. Lugar de atención — texto libre (solo campo)
5. Equipo — n° de serie, modelo, "colocada en", año
6. Partes que fallaron — chips selección múltiple (mínimo 1)
7. Síntoma — TextField multilínea
8. Categoría de diagnóstico — chips (puede seleccionar más de una)
9. Detalle técnico — TextField multilínea
10. Resolución — chips (label según canal, puede ser más de una)
11. Repuestos usados — buscador + cantidad
12. Km recorridos — solo campo
13. Observaciones — opcional

La validación ocurre en el BLoC al recibir el evento de guardar, nunca en la vista.

---

## main.dart

```dart
MaterialApp(
  theme: temaLight(),
  darkTheme: temaDark(),
  themeMode: ThemeMode.system,
  home: BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state is AuthLoading) return const SplashPage();
      if (state is AuthAuthenticated) return const NuevoServicioPage();
      return const LoginPage();
    },
  ),
)
```

---

## Manejo de errores

```dart
class ServerException implements Exception { final String mensaje; final int? statusCode; }
class AuthException implements Exception { final String mensaje; }
class NetworkException implements Exception { final String mensaje; }
```

Los repositorios lanzan excepciones tipadas. Los BLoCs las capturan con try/catch y emiten estados de error.

---

## Convenciones de código

- Nombres de archivos: snake_case · Clases: PascalCase
- Todo en español salvo keywords de Dart/Flutter
- Los use cases tienen un único método `ejecutar(...)`
- Los repositorios impl reciben `ApiClient` por constructor
- Los use cases reciben el repositorio por constructor
- Los BLoCs reciben los use cases por constructor
- Las páginas leen dependencias con `context.read<XBloc>()`
- Los DTOs tienen factory `fromJson` y método `toJson`
- `diagnosticoCatId`, `resolucionId` y `partesFallaron` son arrays — modelar como List
- Generar un `idempotencyKey` uuid nuevo por cada orden, reutilizarlo en reintentos
- Props de Equatable siempre declarados
- Usar siempre widgets y colores de `app_theme.dart`
- Para el shape exacto de cualquier respuesta, consultar `endpoints.md` del backend
