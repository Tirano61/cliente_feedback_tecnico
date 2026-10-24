import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/movimiento.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/referencias_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/unidad_dto.dart';

class MovimientoDto {
	final TipoMovimiento tipo;
	final DateTime? fecha;
	final UsuarioFabrica? usuario;
	final IndicadorFabrica? indicador;
	final String? servicioId;
	final String? recepcionId;
	final String? ingresoId;
	final String? observacion;

	const MovimientoDto({
		required this.tipo,
		this.fecha,
		this.usuario,
		this.indicador,
		this.servicioId,
		this.recepcionId,
		this.ingresoId,
		this.observacion,
	});

	factory MovimientoDto.fromJson(Map<String, dynamic> json) {
		return MovimientoDto(
			tipo: CodigosFabrica.tipoMovimiento(json['tipo']),
			fecha: JsonFabrica.fecha(json['fecha']),
			usuario: usuarioFabricaOpcional(json['usuario']),
			indicador: indicadorFabricaOpcional(json['indicador']),
			servicioId: JsonFabrica.textoOpcional(json['servicioId']),
			recepcionId: JsonFabrica.textoOpcional(json['recepcionId']),
			ingresoId: JsonFabrica.textoOpcional(json['ingresoId']),
			observacion: JsonFabrica.textoOpcional(json['observacion']),
		);
	}

	Movimiento aEntidad() {
		return Movimiento(
			tipo: tipo,
			fecha: fecha,
			usuario: usuario,
			indicador: indicador,
			servicioId: servicioId,
			recepcionId: recepcionId,
			ingresoId: ingresoId,
			observacion: observacion,
		);
	}
}

class HistorialUnidadDto {
	final Unidad unidad;
	final List<Movimiento> movimientos;

	const HistorialUnidadDto({
		required this.unidad,
		required this.movimientos,
	});

	factory HistorialUnidadDto.fromJson(Map<String, dynamic> json) {
		return HistorialUnidadDto(
			unidad: UnidadDto.fromJson(JsonFabrica.mapa(json['unidad']) ?? const {}).aEntidad(),
			movimientos: JsonFabrica.listaDeMapas(json['movimientos'])
					.map((item) => MovimientoDto.fromJson(item).aEntidad())
					.toList(),
		);
	}

	HistorialUnidad aEntidad() {
		return HistorialUnidad(unidad: unidad, movimientos: movimientos);
	}
}
