# Endpoints API

## Base URL

- `http://localhost:3000/api/v1`

## Auth

Header para privados:

```http
Authorization: Bearer <token>
```

## Auth publico

| Metodo | Endpoint |
|---|---|
| POST | `/auth/register` |
| POST | `/auth/login` |

## Servicios

| Metodo | Endpoint | Rol |
|---|---|---|
| POST | `/servicios` | tecnico |
| GET | `/servicios/mios` | tecnico |
| GET | `/servicios` | admin-tecnico, admin-desarrollo, admin |
| GET | `/servicios/:id` | tecnico, admin-tecnico, admin-desarrollo, admin |
| PATCH | `/servicios/:id` | tecnico |

### Payload ejemplo POST /servicios

```json
{
  "canal": "campo",
  "clienteId": "{{clienteId}}",
  "lugarProvinciaId": "{{zonaId}}",
  "lugarDetalle": "Cestari 14",
  "equipoNroSerie": "SN-001",
  "equipoModelo": "ST455",
  "equipoUbicacion": "Tolva principal",
  "equipoAnio": 2021,
  "partesFallaron": ["celda", "app_movil"],
  "km": 120,
  "sintoma": "No inicia",
  "diagnosticoDetalle": "Fuente sin salida",
  "diagnosticoCatId": "{{diagnosticoId}}",
  "resolucionId": "{{resolucionId}}",
  "observaciones": "Cliente solicita seguimiento",
  "productoIds": ["{{productoId}}"]
}
```

## Clientes

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/clientes/buscar?q=` | tecnico, admin-tecnico, admin |
| GET | `/clientes/:id` | tecnico, admin-tecnico, admin |
| POST | `/clientes` | tecnico, admin-tecnico |
| PATCH | `/clientes/:id` | admin-tecnico |

## Catalogos

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/cat/diagnosticos` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/cat/diagnosticos` | admin-desarrollo, admin |
| PATCH | `/cat/diagnosticos/:id` | admin-desarrollo, admin |
| GET | `/cat/resoluciones` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/cat/resoluciones` | admin-desarrollo, admin |
| PATCH | `/cat/resoluciones/:id` | admin-desarrollo, admin |
| GET | `/zonas` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/zonas` | admin-tecnico, admin |
| PATCH | `/zonas/:id` | admin-tecnico, admin |

## Productos

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/categorias-producto` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/categorias-producto` | admin-tecnico, admin |
| PATCH | `/categorias-producto/:id` | admin-tecnico, admin |
| GET | `/productos?categoriaId=` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/productos` | admin-tecnico, admin |
| PATCH | `/productos/:id` | admin-tecnico, admin |

## Repuestos

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/repuestos?q=` | tecnico, admin-tecnico, admin |
| POST | `/repuestos` | admin-tecnico |
| PATCH | `/repuestos/:id` | admin-tecnico |
| POST | `/servicios/:id/repuestos` | tecnico, admin-tecnico, admin |
| GET | `/servicios/:id/repuestos` | tecnico, admin-tecnico, admin |

### Payload POST /servicios/:id/repuestos

Acepta ambos formatos:

```json
{ "repuestoId": "{{repuestoId}}", "cantidad": 1 }
```

```json
{ "repuesto_id": "{{repuestoId}}", "cantidad": 1 }
```

## Cotizacion

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/cotizacion` | tecnico, admin-tecnico, admin |
| GET | `/cotizacion/historial` | tecnico, admin-tecnico, admin |
| POST | `/cotizacion` | admin-tecnico |

## Liquidacion

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/tipos-salida` | tecnico, admin-tecnico |
| POST | `/tipos-salida` | admin-tecnico |
| PATCH | `/tipos-salida/:id` | admin-tecnico |
| GET | `/tipos-servicio` | tecnico, admin-tecnico |
| POST | `/tipos-servicio` | admin-tecnico |
| PATCH | `/tipos-servicio/:id` | admin-tecnico |
| POST | `/liquidaciones` | admin-tecnico |
| GET | `/liquidaciones/mias` | tecnico |
| GET | `/liquidaciones` | admin-tecnico |
| PATCH | `/liquidaciones/:id` | admin-tecnico |
| PATCH | `/liquidaciones/:id/aprobar` | admin-tecnico |
| POST | `/liquidaciones/:id/items` | admin-tecnico |
| PATCH | `/liquidaciones/:id/items/:itemId/aprobar` | admin-tecnico |
| DELETE | `/liquidaciones/:id/items/:itemId` | admin-tecnico |

### Payloads importantes de liquidacion

`POST /liquidaciones`:

```json
{ "servicio_id": "{{servicioId}}", "km": 140 }
```

Tambien soporta camelCase:

```json
{ "servicioId": "{{servicioId}}", "km": 140 }
```

`PATCH /liquidaciones/:id`:

```json
{ "tipo_salida_id": "{{tipoSalidaId}}" }
```

`POST /liquidaciones/:id/items`:

```json
{ "tipo_servicio_id": "{{tipoServicioId}}" }
```

## Analytics (feedback)

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/stats/por-canal` | admin-desarrollo, admin |
| GET | `/stats/por-diagnostico` | admin-desarrollo, admin |
| GET | `/stats/por-parte` | admin-desarrollo, admin |
| GET | `/stats/por-producto` | admin-desarrollo, admin |
| GET | `/stats/por-periodo` | admin-desarrollo, admin |
| GET | `/stats/resolucion` | admin-desarrollo, admin |
| GET | `/export` | admin-desarrollo, admin |
