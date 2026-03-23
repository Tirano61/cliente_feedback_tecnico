import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:equatable/equatable.dart';

abstract class CasoState extends Equatable {
	const CasoState();

	@override
	List<Object?> get props => [];
}

class CasoInitial extends CasoState {
	const CasoInitial();
}

class CasoGuardando extends CasoState {
	const CasoGuardando();
}

class CasoGuardadoExito extends CasoState {
	const CasoGuardadoExito();
}

class CasoError extends CasoState {
	final String mensaje;

	const CasoError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}

class MisCasosLoading extends CasoState {
	const MisCasosLoading();
}

class MisCasosLoaded extends CasoState {
	final List<Caso> casos;

	const MisCasosLoaded({required this.casos});

	@override
	List<Object> get props => [casos];
}
