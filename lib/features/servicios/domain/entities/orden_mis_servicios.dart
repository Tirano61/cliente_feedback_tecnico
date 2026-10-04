/// Orden de GET /servicios/mios (param `orderBy`). Siempre descendente; lo
/// resuelve el backend antes de paginar, la app no reordena localmente.
enum OrdenMisServicios {
	/// Por `createdAt`: cuando se cargo. Es el default del backend.
	fechaCarga,

	/// Por `fechaHoraServicio`: cuando se realizo. Los que no tienen fecha van
	/// al final.
	fechaServicio,
}
