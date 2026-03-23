import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/repositories/i_caso_repository.dart';

class CasoRepositoryImpl implements ICasoRepository {
	final ApiClient apiClient;

	CasoRepositoryImpl(this.apiClient);

	@override
	Future<void> cargarCaso(Caso caso) async {
		return;
	}

	@override
	Future<List<Caso>> obtenerMisCasos() async {
		return const [];
	}
}
