# Plan: trabajo en fábrica en la app del técnico

Este documento es la parte del plan de fábrica que le toca a esta app. El
contrato exacto de cada endpoint (payloads, respuestas, estados y errores) está
en `docs/endpoints.md`, sección **Fabrica**. No inventar campos: copiarlos de ahí.

---

## 1. Para qué

En fábrica el técnico trabaja desde una tablet (la app compila a APK y web).
Tiene que poder:

- registrar los **equipos de clientes que llegan** (recepciones) y llevar su estado hasta devolverlos;
- dar **ingreso** a placas y celdas que entran para revisión y **derivar las placas** a desarrollo;
- **poner una placa o celda** en un indicador (nueva o reacondicionada) registrando su número de serie;
- cargar el **resultado de las celdas** (las celdas no van a desarrollo);
- ver las **placas reacondicionadas disponibles** y el **historial** de una pieza.

## 2. Reglas de negocio (las valida el backend; la app las respeta y muestra el `mensaje` del error)

- La balanza se identifica por el **número de serie del indicador**. Placas, celdas e indicadores tienen número de serie propio.
- **Recepción**: `recibido → en_reparacion ⇄ esperando_presupuesto → listo_para_devolver → devuelto`.
  - `esperando_presupuesto`: el cliente todavía no aceptó el presupuesto. Si acepta → `en_reparacion`; si no → `listo_para_devolver`.
  - Para pasar a `listo_para_devolver` tiene que estar **vinculado el servicio de canal fábrica** (el formulario de servicio que ya existe, canal fábrica). Ese servicio sigue siendo el registro de diagnóstico, resolución y facturación.
  - `listo_para_devolver → en_reparacion` si falla la prueba final.
  - `devuelto` solo por la devolución (forma: envío, retira el cliente, lo lleva un técnico).
  - Un indicador no puede tener dos recepciones abiertas.
- **Ingreso** de placa o celda: con recepción toma cliente e indicador de la recepción; sin recepción hay que elegir de qué **cliente o sucursal** viene (las sucursales son clientes).
- **Placas**: se derivan a desarrollo. Falla y reparación de placas las carga **desarrollo** (no esta app). Cuando desarrollo la repara vuelve a servicio técnico como **reacondicionada disponible**.
- **Celdas**: quedan en servicio técnico. El técnico carga la **falla** (componente + causa) y después la **reparación** (reparada / irreparable). Reparada queda disponible; irreparable se descarta.
- **Poner una pieza** en un indicador: solo piezas nuevas (se registran en ese momento con su número de serie) o `reacondicionada_disponible`. En placas, si no se dice cuál se saca, sale la que tenía el indicador.
- Las reacondicionadas salen al cliente siempre desde servicio técnico. La placa original no vuelve al cliente.
- Los errores de reglas llegan con `{ codigo, mensaje }`: mostrar `mensaje` tal cual, claro, sin perder lo cargado.

## 3. Pantallas

Entrada nueva **"Fábrica"** en el AppBar de la pantalla principal (como Mis servicios y Liquidaciones), con tres pestañas:

1. **Equipos en fábrica** (recepciones)
   - Lista de recepciones abiertas (`abiertas=true`), con número, cliente, número de serie del indicador, estado y días en fábrica. Buscador (`q`: número, cliente o serie) y filtro por estado. Opción para ver devueltas.
   - Botón **Nueva recepción**: cliente (buscador de clientes que ya existe), número de serie del indicador, modelo (opcional, de productos), qué llegó, qué reporta el cliente, observaciones.
   - **Detalle de una recepción**:
     - datos, estado actual e historial de estados;
     - botones de cambio de estado según el estado actual (solo los permitidos);
     - **piezas instaladas** en el indicador y **piezas ingresadas** desde esta recepción;
     - acciones: *Ingresar pieza retirada* (precarga la recepción), *Poner placa/celda* (precarga indicador y recepción), *Cargar servicio de fábrica* (abre el formulario de servicio con canal fábrica y datos del equipo; al guardar, vincula el servicio a la recepción), *Devolver al cliente* (solo en `listo_para_devolver`).
2. **Piezas ingresadas** (ingresos)
   - Lista con filtro por tipo (placa / celda) y estado; buscador.
   - **Nuevo ingreso** sin recepción (por ejemplo partes de una sucursal): tipo, número de serie, modelo, cliente/sucursal de origen, indicador del que salió (opcional), qué observó el técnico.
   - **Detalle**: datos, estado, falla y reparación si las hay. Acciones según tipo y estado: *Derivar a desarrollo* (placa en servicio técnico); *Cargar falla* y *Cargar reparación* (solo celdas).
3. **Piezas** (unidades)
   - Búsqueda por número de serie.
   - Atajo **Placas reacondicionadas disponibles** (`tipo=placa&estado=reacondicionada_disponible`).
   - **Detalle de pieza** con su **historial** (recorrido completo, del más viejo al más nuevo). Si es un indicador, sus piezas instaladas.

## 4. Arquitectura (igual que el resto de la app)

- Feature nueva `lib/features/fabrica/` con `domain` (entidades, `IFabricaRepository`), `application` (use cases con `ejecutar`), `infrastructure` (DTOs `fromJson`/`toJson`, `FabricaRepositoryImpl` con `ApiClient`), `presentation` (BLoCs, páginas, widgets).
- Dependencias en `AppDependencies`, BLoCs en el `MultiBlocProvider`. Sin get_it.
- **Las vistas no tienen lógica**: render con `BlocBuilder`, efectos con `BlocListener`, eventos con `context.read`. Cálculos (días en fábrica, acciones permitidas por estado) en el BLoC o el estado.
- Mensajes de un solo uso en el estado (`errorMensaje` / `exitoMensaje`), como en `ServicioFormularioState`.
- Errores del backend con `codigo`: una excepción tipada en el dominio (como `ValoresOrdenRechazadosException`) o `ServerException` con el `mensaje`.
- Constantes de rutas en `ApiConstants`.
- Tests con `MockClient` contra el repositorio real, siguiendo `test/features/servicios/facturacion_valores_orden_test.dart`.

## 5. Pasos (cortos, uno por PR)

1. **Dominio e infraestructura**: entidades (recepción, unidad, ingreso, falla, reparación, movimiento, componente, causa), DTOs, repositorio, use cases y tests de parseo y de errores con `codigo`.
2. **Equipos en fábrica**: lista, nueva recepción, detalle con cambios de estado y devolución.
3. **Servicio de fábrica desde la recepción**: abrir el formulario de servicio con canal fábrica y vincularlo a la recepción al guardar.
4. **Ingresos**: ingreso desde la recepción y sin recepción, derivar placas, falla y reparación de celdas.
5. **Poner placa/celda** en un indicador y **piezas**: búsqueda, reacondicionadas disponibles, historial.
6. (Después) **Campo**: en el servicio de campo, registrar la placa que se pone (`POST /fabrica/unidades/asignaciones` con `servicioId`).

Fuera de alcance: garantías, comprobante de recepción, carga de falla/reparación de placas (es de desarrollo, en la web de feedback).
