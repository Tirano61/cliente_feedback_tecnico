import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';
import 'package:cliente_feedback_tecnico/features/auth/domain/repositories/i_auth_repository.dart';

class RestaurarSesionUseCase {
	final IAuthRepository _repository;

	RestaurarSesionUseCase(this._repository);

	/// Devuelve el usuario de la sesion guardada, o null si hay que loguearse.
	Future<Usuario?> ejecutar() {
		return _repository.obtenerSesionGuardada();
	}
}
