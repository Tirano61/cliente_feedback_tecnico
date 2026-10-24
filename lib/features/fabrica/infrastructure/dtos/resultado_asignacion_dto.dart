import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/resultado_asignacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/referencias_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/unidad_dto.dart';

class ResultadoAsignacionDto {
	final IndicadorFabrica indicador;
	final Unidad instalada;
	final List<Unidad> retiradas;

	const ResultadoAsignacionDto({
		required this.indicador,
		required this.instalada,
		required this.retiradas,
	});

	factory ResultadoAsignacionDto.fromJson(Map<String, dynamic> json) {
		return ResultadoAsignacionDto(
			indicador: IndicadorFabricaDto.fromJson(
				JsonFabrica.mapa(json['indicador']) ?? const {},
			).aEntidad(),
			instalada: UnidadDto.fromJson(JsonFabrica.mapa(json['instalada']) ?? const {}).aEntidad(),
			retiradas: unidadesDesdeJson(json['retiradas']),
		);
	}

	ResultadoAsignacion aEntidad() {
		return ResultadoAsignacion(
			indicador: indicador,
			instalada: instalada,
			retiradas: retiradas,
		);
	}
}
