import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:equatable/equatable.dart';

abstract class CasoEvent extends Equatable {
	const CasoEvent();

	@override
	List<Object?> get props => [];
}

class CasoFormularioCambiado extends CasoEvent {
	final Canal? canal;
	final String? zonaId;
	final String? categoriaId;
	final String? productoId;
	final String? sintoma;
	final String? diagnosticoCatId;
	final String? diagnosticoDetalle;
	final String? resolucionId;
	final String? observaciones;

	const CasoFormularioCambiado({
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

class CasoGuardarPressed extends CasoEvent {
	const CasoGuardarPressed();
}

class MisCasosSolicitados extends CasoEvent {
	const MisCasosSolicitados();
}

class CasoFormularioReiniciado extends CasoEvent {
	const CasoFormularioReiniciado();
}
