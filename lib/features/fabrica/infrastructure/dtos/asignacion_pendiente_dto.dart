import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/asignacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/solicitudes_fabrica_dto.dart';

/// Como se guarda en el dispositivo una `AsignacionPendiente`: el body de
/// `POST /fabrica/unidades/asignaciones` tal cual se va a mandar y el ultimo
/// mensaje de error.
class AsignacionPendienteDto {
	final SolicitudAsignacion solicitud;
	final String? mensajeError;

	const AsignacionPendienteDto({required this.solicitud, this.mensajeError});

	factory AsignacionPendienteDto.desdeEntidad(AsignacionPendiente asignacion) {
		return AsignacionPendienteDto(
			solicitud: asignacion.solicitud,
			mensajeError: asignacion.mensajeError,
		);
	}

	/// null si al registro le falta el servicio, el indicador, la pieza o un
	/// tipo que se pueda poner.
	static AsignacionPendienteDto? fromJson(Map<String, dynamic> json) {
		final body = JsonFabrica.mapa(json['solicitud']);
		if (body == null) {
			return null;
		}
		final servicioId = JsonFabrica.textoOpcional(body['servicioId']);
		final indicadorNroSerie = JsonFabrica.textoOpcional(body['indicadorNroSerie']);
		final nroSerie = JsonFabrica.textoOpcional(body['nroSerie']);
		final tipo = CodigosFabrica.tipoUnidad(body['tipo']);
		if (servicioId == null ||
				indicadorNroSerie == null ||
				nroSerie == null ||
				(tipo != TipoUnidad.placa && tipo != TipoUnidad.celda)) {
			return null;
		}
		return AsignacionPendienteDto(
			solicitud: SolicitudAsignacion(
				indicadorNroSerie: indicadorNroSerie,
				tipo: tipo,
				nroSerie: nroSerie,
				productoId: JsonFabrica.textoOpcional(body['productoId']),
				indicadorProductoId: JsonFabrica.textoOpcional(body['indicadorProductoId']),
				retiradaNroSerie: JsonFabrica.textoOpcional(body['retiradaNroSerie']),
				recepcionId: JsonFabrica.textoOpcional(body['recepcionId']),
				servicioId: servicioId,
				observacion: JsonFabrica.textoOpcional(body['observacion']),
			),
			mensajeError: JsonFabrica.textoOpcional(json['mensajeError']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'solicitud': SolicitudAsignacionDto.desdeEntidad(solicitud).toJson(),
			if (mensajeError != null) 'mensajeError': mensajeError,
		};
	}

	AsignacionPendiente aEntidad() {
		return AsignacionPendiente(solicitud: solicitud, mensajeError: mensajeError);
	}
}
