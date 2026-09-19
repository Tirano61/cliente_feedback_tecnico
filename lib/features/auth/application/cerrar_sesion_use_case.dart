import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';

class CerrarSesionUseCase {
	final IAuthRepository _repository;

	CerrarSesionUseCase(this._repository);

	Future<void> ejecutar() {
		return _repository.logout();
	}
}
