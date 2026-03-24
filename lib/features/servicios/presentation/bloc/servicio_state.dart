import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

abstract class ServicioState extends Equatable {
	const ServicioState();

	@override
	List<Object?> get props => [];
}

class ServicioInitial extends ServicioState {
	const ServicioInitial();
}

class ServicioGuardando extends ServicioState {
	const ServicioGuardando();
}

class ServicioGuardadoExito extends ServicioState {
	const ServicioGuardadoExito();
}

class ServicioError extends ServicioState {
	final String mensaje;

	const ServicioError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}

class MisServiciosLoading extends ServicioState {
	const MisServiciosLoading();
}

class MisServiciosLoaded extends ServicioState {
	final List<Servicio> servicios;

	const MisServiciosLoaded({required this.servicios});

	@override
	List<Object> get props => [servicios];
}


