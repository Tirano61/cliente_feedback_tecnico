import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';

abstract class ICasoRepository {
	Future<void> cargarCaso(Caso caso);

	Future<List<Caso>> obtenerMisCasos();
}
