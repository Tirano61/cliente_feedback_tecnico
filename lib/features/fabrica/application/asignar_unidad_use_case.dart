import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/resultado_asignacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/repositories/i_fabrica_repository.dart';

class AsignarUnidadUseCase {
	final IFabricaRepository _repository;

	AsignarUnidadUseCase(this._repository);

	Future<ResultadoAsignacion> ejecutar(SolicitudAsignacion solicitud) {
		return _repository.asignarUnidad(solicitud);
	}
}
