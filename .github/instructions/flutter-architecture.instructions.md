---
description: "Use when creating or modifying Flutter app code, BLoCs, use cases, repositories, DTOs, entities, routing, or form screens in this project. Enforces DDD by feature, BLoC boundaries, Spanish domain naming, and project-specific conventions."
name: "Flutter DDD y BLoC"
applyTo: "lib/**/*.dart, test/**/*.dart"
---
# Flutter DDD y BLoC

## Objetivo
Aplicar arquitectura DDD por feature con separacion estricta de capas:
`presentation -> application -> domain <- infrastructure`.

## Reglas de capas
- `presentation`: solo UI, `BlocBuilder` y `BlocListener`, y dispatch de eventos.
- `application`: casos de uso con un unico metodo publico `ejecutar(...)`.
- `domain`: entidades y contratos de repositorio.
- `infrastructure`: DTOs, mappers y `RepositoryImpl` con `ApiClient`.
- No mover logica de negocio a widgets/paginas.

## Estado y eventos
- Usar `flutter_bloc` + `equatable`.
- Eventos y estados deben extender su clase base abstracta.
- Definir siempre `props` en todos los eventos/estados.
- Capturar excepciones tipadas en BLoC y mapearlas a estados de error de UI.

## Convenciones de nombre
- Archivos en `snake_case`.
- Clases en `PascalCase`.
- Dominio en espanol: clases, metodos, variables y comentarios.

## Integracion y red
- Usar `http` a traves de `ApiClient`.
- JWT en `flutter_secure_storage`.
- Endpoints y contratos segun documentacion de proyecto.

## Enlaces de referencia
- Especificacion funcional y tecnica completa: `copilot-instructions.md` (raiz).
- Instrucciones globales del workspace: `.github/copilot-instructions.md`.
