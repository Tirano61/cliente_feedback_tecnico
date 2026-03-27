# Flutter Tecnico - Handoff para Copilot

Fecha: 2026-03-26
Objetivo: entregar a Copilot un brief completo para implementar el flujo tecnico de orden de servicio unificada en Flutter.

## 1. Contexto funcional

- El tecnico debe poder crear una orden completa en un solo envio.
- La orden incluye bloque tecnico, productos por falla, facturacion e items cobrables.
- La app genera el PDF en el momento con la respuesta del backend.
- Si no se puede enviar documento/firma en el alta, se adjunta despues.
- Debe evitarse duplicar ordenes en reintentos (idempotencia).

## 2. Prompt recomendado para Copilot

Usa este texto como prompt inicial en el repo Flutter:

Implementar en Flutter el flujo completo de orden de servicio tecnico contra backend NestJS.

Requisitos funcionales:
1. Crear orden con POST /servicios en un solo envio (datos tecnicos + productosFalla + facturacion + facturacionItems + documento opcional).
2. Usar idempotencyKey por borrador y reutilizarla en reintentos.
3. Interpretar replayed en la respuesta: true significa orden ya creada previamente por la misma clave.
4. Generar PDF de orden desde la respuesta del POST.
5. Capturar firma cliente.
6. Si documento/firma no se envio en el POST, enviar PATCH /servicios/:id/documento.
7. Guardar estado local para soporte offline y reintentos.

Requisitos tecnicos:
1. Crear modelos request/response tipados para todos los contratos de servicios.
2. Crear capa API con repositorio y manejo de errores por codigo HTTP.
3. Implementar maquina de estados local de la orden.
4. Implementar cola de sincronizacion con reintentos y backoff.
5. Evitar doble envio por doble tap.
6. Agregar pruebas de flujo basico, replay idempotente y adjunto posterior de documento.

Entregar:
1. Estructura de carpetas propuesta.
2. Modelos y mappers.
3. Casos de uso.
4. Servicios HTTP.
5. Pantallas o controladores necesarios.
6. Checklist de QA manual.

## 3. Endpoints que debe consumir Flutter

Base URL:
- http://localhost:3000/api/v1

Auth:
- POST /auth/login

Servicios:
- POST /servicios
- GET /servicios/mios
- GET /servicios/:id
- PATCH /servicios/:id/documento

Catalogos y datos de soporte:
- GET /cat/diagnosticos
- GET /cat/resoluciones
- GET /zonas
- GET /categorias-producto
- GET /productos?categoriaId={id}
- GET /clientes/buscar?q={texto}
- POST /clientes

## 4. Contrato minimo para POST /servicios

Campos clave de request:
1. idempotencyKey (uuid v4)
2. fechaHoraServicio, timezoneIana, utcOffsetMinutos
3. canal, clienteId, lugarProvinciaId, lugarDetalle
4. partesFallaron
5. diagnosticoCatId (array)
6. resolucionId (array opcional)
7. productosFalla [{ parteFallo, productoFallaId }]
8. facturacion
9. facturacionItems
10. documento (opcional)

Campos clave de response:
1. replayed (boolean)
2. servicioId
3. idempotencyKey
4. estadoOrden
5. version
6. servicio
7. facturacion
8. facturacionItems
9. documento

Regla de negocio importante:
- Si replayed = true, no se creo una orden nueva. El backend devolvio la misma orden por reintento con igual idempotencyKey.

## 5. Contrato minimo para PATCH /servicios/:id/documento

Request:
1. pdfHashSha256 (opcional)
2. pdfUrl (opcional)
3. firmaClienteNombre (opcional)
4. firmaClienteDocumento (opcional)
5. firmaFechaHora (opcional)

Response:
- Devuelve el mismo shape de POST /servicios con replayed = false y estadoOrden actualizado.

## 6. Flujo recomendado en app tecnico

1. Login y carga de catalogos base.
2. Crear o seleccionar cliente.
3. Completar bloque tecnico.
4. Completar productosFalla y validaciones locales.
5. Completar bloque facturacion e items.
6. Generar idempotencyKey al crear borrador local.
7. Enviar POST /servicios.
8. Si ok, guardar servicioId y generar PDF.
9. Capturar firma.
10. Si falta documento en alta, enviar PATCH /servicios/:id/documento.
11. Marcar orden sincronizada.

## 7. Manejo offline e idempotencia

1. Persistir borrador local con idempotencyKey fija.
2. En reconexion, reintentar con la misma clave.
3. Si replayed = true, tomar respuesta como exito.
4. No regenerar idempotencyKey en reintentos.
5. Bloquear doble envio concurrente del mismo borrador.

## 8. Criterios de aceptacion para cierre frontend

1. El tecnico puede crear orden completa en un solo envio.
2. Reintentos no duplican ordenes.
3. El PDF se puede generar con la respuesta del POST.
4. El documento/firma se puede adjuntar despues del alta.
5. La app muestra estado claro de sincronizacion.

## 9. Referencias backend

- Contratos y ejemplos: docs/endpoints.md
- Plan funcional: docs/plan-reforma-orden-servicio.md
- Coleccion de pruebas API: docs/postman/backend_feedback.postman_collection.json

## 10. Fase 1 iniciada - Contrato y compatibilidad

Objetivo de esta fase:
- cerrar el contrato de datos objetivo para Flutter
- identificar el gap contra lo que hoy envia la app
- definir estrategia de migracion sin bloquear al tecnico

### 10.1 Contrato objetivo acordado (fuente: docs/endpoints.md)

POST /servicios debe enviar:
1. idempotencyKey
2. fechaHoraServicio, timezoneIana, utcOffsetMinutos
3. bloque tecnico actual (canal, clienteId, lugar, equipo, partesFallaron, km, sintoma, diagnosticoDetalle, diagnosticoCatId, resolucionId, observaciones)
4. productosFalla: [{ parteFallo, productoFallaId }]
5. facturacion
6. facturacionItems
7. documento (opcional en alta)

POST /servicios debe recibir:
1. replayed
2. servicioId
3. idempotencyKey
4. estadoOrden
5. version
6. servicio
7. facturacion
8. facturacionItems
9. documento

PATCH /servicios/:id/documento debe enviar:
1. pdfHashSha256 (opcional)
2. pdfUrl (opcional)
3. firmaClienteNombre (opcional)
4. firmaClienteDocumento (opcional)
5. firmaFechaHora (opcional)

### 10.2 Gap actual Flutter (estado del codigo)

Ya implementado hoy:
1. bloque tecnico base
2. diagnosticoCatId como array
3. resolucionId como array (aunque con seleccion unica en UI)
4. productoIds como array de ids

Faltante para contrato objetivo:
1. idempotencyKey
2. fechaHoraServicio, timezoneIana, utcOffsetMinutos
3. productosFalla (hoy se envia productoIds)
4. facturacion
5. facturacionItems
6. documento en alta
7. parseo tipado de replayed, estadoOrden, version, servicioId
8. flujo PATCH /servicios/:id/documento

### 10.3 Decision de compatibilidad (transicion)

Para evitar corte de flujo tecnico, se define migracion por pasos:
1. introducir modelos nuevos en paralelo (request/response orden completa)
2. mantener el flujo UI actual y mapearlo al nuevo request
3. reemplazar productoIds por productosFalla en el mapper final
4. no regenerar claves de borrador al reintentar (idempotencyKey estable)
5. tratar replayed=true como exito funcional

Nota importante de modelado:
- para construir productosFalla correctamente, el estado local debe guardar por cada item seleccionado:
	- productoFallaId
	- parteFallo
- no alcanza con conservar solo productoIds

### 10.4 Entregables de cierre de Fase 1

1. tabla de contratos request/response aprobada por backend y frontend
2. mapeo campo a campo: actual vs objetivo
3. estrategia de migracion sin ruptura del alta tecnico
4. definicion de datos minimos que debe persistir un borrador local

### 10.5 Proximo paso inmediato (Fase 2)

1. crear modelos tipados para OrdenServicioRequest y OrdenServicioResponse
2. crear modelos tipados para ProductosFalla, Facturacion, FacturacionItem y Documento
3. adaptar ServicioDto para construir payload objetivo y parsear replayed/estado