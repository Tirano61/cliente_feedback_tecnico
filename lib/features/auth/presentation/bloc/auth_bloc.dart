import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
	final LoginUseCase _loginUseCase;

	AuthBloc(this._loginUseCase) : super(const AuthInitial()) {
		on<AppStarted>(_onAppStarted);
		on<LoginSubmitted>(_onLoginSubmitted);
		on<LogoutRequested>(_onLogoutRequested);
	}

	Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
		emit(const AuthUnauthenticated());
	}

	Future<void> _onLoginSubmitted(
		LoginSubmitted event,
		Emitter<AuthState> emit,
	) async {
		emit(const AuthLoading());
		try {
			final usuario = await _loginUseCase.ejecutar(event.email, event.password);
			emit(AuthAuthenticated(usuario: usuario));
		} on AuthException catch (error) {
			emit(AuthError(mensaje: error.mensaje));
		} on ServerException catch (error) {
			emit(AuthError(mensaje: error.mensaje));
		} catch (_) {
			emit(const AuthError(mensaje: 'Error inesperado. Intenta de nuevo.'));
		}
	}

	Future<void> _onLogoutRequested(
		LogoutRequested event,
		Emitter<AuthState> emit,
	) async {
		emit(const AuthUnauthenticated());
	}
}
