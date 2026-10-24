import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class ObtenerCausasUseCase {
	final IFabricaRepository _repository;

	ObtenerCausasUseCase(this._repository);

	Future<List<Causa>> ejecutar() {
		return _repository.obtenerCausas();
	}
}
