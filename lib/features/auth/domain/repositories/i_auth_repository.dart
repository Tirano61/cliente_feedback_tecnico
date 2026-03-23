import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';

abstract class IAuthRepository {
	Future<Usuario> login({required String email, required String password});

	Future<void> logout();
}
