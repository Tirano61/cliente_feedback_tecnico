/// Filtro de estado del listado "mis servicios".
///
/// Se traduce al param `aprobado` de GET /servicios/mios: `aprobados` es
/// liquidacion aprobada; `pendientes` es todo el resto, incluidos los
/// servicios remoto y fabrica, que no generan liquidacion.
enum FiltroEstadoServicio {
	todos,
	aprobados,
	pendientes;

	/// Valor del param `aprobado`; null es no mandarlo.
	bool? get aprobado => switch (this) {
				FiltroEstadoServicio.todos => null,
				FiltroEstadoServicio.aprobados => true,
				FiltroEstadoServicio.pendientes => false,
			};
}
