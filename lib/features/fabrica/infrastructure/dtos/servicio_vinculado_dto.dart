import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/servicio_vinculado.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/vinculacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';

/// `GET /servicios/:id`: el backend devuelve el servicio con sus relaciones
/// (`tecnico`, `diagnosticoCat` y `resolucion` como listas de `{ id, nombre }`).
/// Solo se leen los campos del resumen.
class ServicioVinculadoDto {
	final String id;
	final DateTime? fecha;
	final String? tecnicoNombre;
	final List<String> diagnosticos;
	final String? diagnosticoDetalle;
	final List<String> resoluciones;

	const ServicioVinculadoDto({
		required this.id,
		this.fecha,
		this.tecnicoNombre,
		this.diagnosticos = const [],
		this.diagnosticoDetalle,
		this.resoluciones = const [],
	});

	factory ServicioVinculadoDto.fromJson(Map<String, dynamic> json) {
		return ServicioVinculadoDto(
			id: JsonFabrica.texto(json['id']),
			fecha: JsonFabrica.fecha(json['fechaHoraServicio']) ?? JsonFabrica.fecha(json['fecha']),
			tecnicoNombre: JsonFabrica.textoOpcional(JsonFabrica.mapa(json['tecnico'])?['fullName']),
			diagnosticos: _nombres(json['diagnosticoCat']),
			diagnosticoDetalle: JsonFabrica.textoOpcional(json['diagnosticoDetalle']),
			resoluciones: _nombres(json['resolucion']),
		);
	}

	static List<String> _nombres(dynamic lista) {
		return JsonFabrica.listaDeMapas(lista)
				.map((item) => JsonFabrica.textoOpcional(item['nombre']))
				.whereType<String>()
				.toList();
	}

	ServicioVinculado aEntidad() {
		return ServicioVinculado(
			id: id,
			fecha: fecha,
			tecnicoNombre: tecnicoNombre,
			diagnosticos: diagnosticos,
			diagnosticoDetalle: diagnosticoDetalle,
			resoluciones: resoluciones,
		);
	}
}

/// Como se guarda una vinculacion pendiente en el dispositivo.
class VinculacionPendienteDto {
	final String recepcionId;
	final String servicioId;

	const VinculacionPendienteDto({
		required this.recepcionId,
		required this.servicioId,
	});

	factory VinculacionPendienteDto.desdeEntidad(VinculacionPendiente vinculacion) {
		return VinculacionPendienteDto(
			recepcionId: vinculacion.recepcionId,
			servicioId: vinculacion.servicioId,
		);
	}

	/// null si al registro le falta alguno de los dos ids.
	static VinculacionPendienteDto? fromJson(Map<String, dynamic> json) {
		final recepcionId = JsonFabrica.textoOpcional(json['recepcionId']);
		final servicioId = JsonFabrica.textoOpcional(json['servicioId']);
		if (recepcionId == null || servicioId == null) {
			return null;
		}
		return VinculacionPendienteDto(recepcionId: recepcionId, servicioId: servicioId);
	}

	Map<String, dynamic> toJson() {
		return {'recepcionId': recepcionId, 'servicioId': servicioId};
	}

	VinculacionPendiente aEntidad() {
		return VinculacionPendiente(recepcionId: recepcionId, servicioId: servicioId);
	}
}
