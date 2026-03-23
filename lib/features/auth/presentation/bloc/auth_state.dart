import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
	const AuthState();

	@override
	List<Object?> get props => [];
}

class AuthInitial extends AuthState {
	const AuthInitial();
}

class AuthLoading extends AuthState {
	const AuthLoading();
}

class AuthAuthenticated extends AuthState {
	final Usuario usuario;

	const AuthAuthenticated({required this.usuario});

	@override
	List<Object> get props => [usuario];
}

class AuthUnauthenticated extends AuthState {
	const AuthUnauthenticated();
}

class AuthError extends AuthState {
	final String mensaje;

	const AuthError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}
