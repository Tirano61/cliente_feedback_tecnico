import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class RecibirDeDesarrolloUseCase {
	final IFabricaRepository _repository;

	RecibirDeDesarrolloUseCase(this._repository);

	Future<Ingreso> ejecutar({
		required String ingresoId,
		String? observacion,
	}) {
		return _repository.recibirDeDesarrollo(
			ingresoId: ingresoId,
			observacion: observacion,
		);
	}
}
