import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';

class LoginUseCase {
	final IAuthRepository _repository;

	LoginUseCase(this._repository);

	Future<Usuario> ejecutar(String email, String password) {
		return _repository.login(email: email, password: password);
	}
}
