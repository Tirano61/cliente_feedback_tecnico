import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';

abstract class IAuthRepository {
	Future<Usuario> login({required String email, required String password});

	/// Sesion persistida y todavia utilizable, o null si no hay ninguna.
	///
	/// Si lo guardado esta incompleto o vencido, limpia el storage antes de
	/// devolver null: nunca deja restos que revivan en el proximo arranque.
	Future<Usuario?> obtenerSesionGuardada();

	Future<void> logout();
}
