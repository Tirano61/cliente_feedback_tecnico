import 'dart:async';

import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/cerrar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/restaurar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
	final LoginUseCase _loginUseCase;
	final RestaurarSesionUseCase _restaurarSesionUseCase;
	final CerrarSesionUseCase _cerrarSesionUseCase;

	StreamSubscription<void>? _suscripcionSesionExpirada;

	AuthBloc(
		this._loginUseCase,
		this._restaurarSesionUseCase,
		this._cerrarSesionUseCase, {
		Stream<void>? sesionExpirada,
	}) : super(const AuthInitial()) {
		on<AppStarted>(_onAppStarted);
		on<LoginSubmitted>(_onLoginSubmitted);
		on<LogoutRequested>(_onLogoutRequested);
		on<SesionExpiradaDetectada>(_onSesionExpiradaDetectada);

		_suscripcionSesionExpirada = sesionExpirada?.listen(
			(_) => add(const SesionExpiradaDetectada()),
		);
	}

	Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
		emit(const AuthLoading());
		try {
			final usuario = await _restaurarSesionUseCase.ejecutar();
			if (usuario == null) {
				emit(const AuthUnauthenticated());
				return;
			}

			emit(AuthAuthenticated(usuario: usuario));
		} catch (_) {
			// Si no se puede leer el storage, se arranca deslogueado.
			emit(const AuthUnauthenticated());
		}
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
		await _limpiarSesion();
		emit(const AuthUnauthenticated());
	}

	Future<void> _onSesionExpiradaDetectada(
		SesionExpiradaDetectada event,
		Emitter<AuthState> emit,
	) async {
		// Un 401 tardio de una sesion ya cerrada no tiene que avisar nada.
		if (state is! AuthAuthenticated) {
			return;
		}

		await _limpiarSesion();
		emit(
			const AuthUnauthenticated(
				mensaje: 'Tu sesion expiro. Volve a ingresar.',
			),
		);
	}

	/// El borrado no puede impedir que la app quede deslogueada.
	Future<void> _limpiarSesion() async {
		try {
			await _cerrarSesionUseCase.ejecutar();
		} catch (_) {
			return;
		}
	}

	@override
	Future<void> close() async {
		await _suscripcionSesionExpirada?.cancel();
		return super.close();
	}
}
