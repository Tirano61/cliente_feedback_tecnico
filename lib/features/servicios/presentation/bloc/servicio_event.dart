import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

abstract class ServicioEvent extends Equatable {
	const ServicioEvent();

	@override
	List<Object?> get props => [];
}

class ServicioFormularioCambiado extends ServicioEvent {
	final Canal? canal;
	final String? zonaId;
	final String? categoriaId;
	final String? productoId;
	final String? sintoma;
	final String? diagnosticoCatId;
	final String? diagnosticoDetalle;
	final String? resolucionId;
	final String? observaciones;

	const ServicioFormularioCambiado({
		this.canal,
		this.zonaId,
		this.categoriaId,
		this.productoId,
		this.sintoma,
		this.diagnosticoCatId,
		this.diagnosticoDetalle,
		this.resolucionId,
		this.observaciones,
	});

	@override
	List<Object?> get props => [
				canal,
				zonaId,
				categoriaId,
				productoId,
				sintoma,
				diagnosticoCatId,
				diagnosticoDetalle,
				resolucionId,
				observaciones,
			];
}

class ServicioGuardarPressed extends ServicioEvent {
	const ServicioGuardarPressed();
}

class MisServiciosSolicitados extends ServicioEvent {
	const MisServiciosSolicitados();
}

class ServicioFormularioReiniciado extends ServicioEvent {
	const ServicioFormularioReiniciado();
}


