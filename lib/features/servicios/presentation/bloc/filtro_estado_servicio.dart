/// Filtro de estado del listado "mis servicios".
///
/// Vive en la capa de presentacion porque no existe en el backend: el tecnico
/// filtra sobre lo que ya trajo GET /servicios/mios.
enum FiltroEstadoServicio { todos, aprobados, pendientes }
