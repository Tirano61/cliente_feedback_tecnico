import 'package:equatable/equatable.dart';

/// Resumen del servicio de fabrica vinculado a una recepcion
/// (`GET /servicios/:id`): lo que el detalle de la recepcion muestra.
class ServicioVinculado extends Equatable {
	final String id;

	/// Cuando se realizo el servicio (`fechaHoraServicio`), o cuando se cargo
	/// si no lo tiene.
	final DateTime? fecha;
	final String? tecnicoNombre;

	/// Nombres de las categorias de diagnostico.
	final List<String> diagnosticos;
	final String? diagnosticoDetalle;

	/// Nombres de las resoluciones (en fabrica, "Trabajo realizado").
	final List<String> resoluciones;

	const ServicioVinculado({
		required this.id,
		this.fecha,
		this.tecnicoNombre,
		this.diagnosticos = const [],
		this.diagnosticoDetalle,
		this.resoluciones = const [],
	});

	@override
	List<Object?> get props => [
				id,
				fecha,
				tecnicoNombre,
				diagnosticos,
				diagnosticoDetalle,
				resoluciones,
			];
}
