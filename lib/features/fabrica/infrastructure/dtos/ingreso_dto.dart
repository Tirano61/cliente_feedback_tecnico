import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/falla.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/reparacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/catalogos_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/referencias_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/unidad_dto.dart';

class FallaDto {
	final String id;
	final Componente? componente;
	final String? componenteOtro;
	final Causa? causa;
	final String? detalle;
	final UsuarioFabrica? usuario;
	final DateTime? fecha;

	const FallaDto({
		required this.id,
		this.componente,
		this.componenteOtro,
		this.causa,
		this.detalle,
		this.usuario,
		this.fecha,
	});

	factory FallaDto.fromJson(Map<String, dynamic> json) {
		final componente = JsonFabrica.mapa(json['componente']);
		final causa = JsonFabrica.mapa(json['causa']);
		return FallaDto(
			id: JsonFabrica.texto(json['id']),
			componente: componente == null ? null : ComponenteDto.fromJson(componente).aEntidad(),
			componenteOtro: JsonFabrica.textoOpcional(json['componenteOtro']),
			causa: causa == null ? null : CausaDto.fromJson(causa).aEntidad(),
			detalle: JsonFabrica.textoOpcional(json['detalle']),
			usuario: usuarioFabricaOpcional(json['usuario']),
			fecha: JsonFabrica.fecha(json['fecha']),
		);
	}

	Falla aEntidad() {
		return Falla(
			id: id,
			componente: componente,
			componenteOtro: componenteOtro,
			causa: causa,
			detalle: detalle,
			usuario: usuario,
			fecha: fecha,
		);
	}
}

/// endpoints.md solo muestra el body del POST de la reparacion; `id`,
/// `usuario` y `fecha` se leen si vienen, igual que en la falla.
class ReparacionDto {
	final String? id;
	final ResultadoReparacion resultado;
	final String? trabajoRealizado;
	final String? componentesReemplazados;
	final UsuarioFabrica? usuario;
	final DateTime? fecha;

	const ReparacionDto({
		this.id,
		required this.resultado,
		this.trabajoRealizado,
		this.componentesReemplazados,
		this.usuario,
		this.fecha,
	});

	factory ReparacionDto.fromJson(Map<String, dynamic> json) {
		return ReparacionDto(
			id: JsonFabrica.textoOpcional(json['id']),
			resultado: CodigosFabrica.resultadoReparacion(json['resultado']),
			trabajoRealizado: JsonFabrica.textoOpcional(json['trabajoRealizado']),
			componentesReemplazados: JsonFabrica.textoOpcional(json['componentesReemplazados']),
			usuario: usuarioFabricaOpcional(json['usuario']),
			fecha: JsonFabrica.fecha(json['fecha']),
		);
	}

	Reparacion aEntidad() {
		return Reparacion(
			id: id,
			resultado: resultado,
			trabajoRealizado: trabajoRealizado,
			componentesReemplazados: componentesReemplazados,
			usuario: usuario,
			fecha: fecha,
		);
	}
}

class IngresoDto {
	final String id;
	final int numero;
	final String unidadId;
	final Unidad unidad;
	final ClienteFabrica? clienteOrigen;
	final String? indicadorOrigenId;
	final IndicadorFabrica? indicadorOrigen;
	final String? recepcionId;
	final String? servicioId;
	final UsuarioFabrica? tecnico;
	final DateTime? fechaIngreso;
	final String? observacionTecnico;
	final EstadoIngreso estado;
	final Falla? falla;
	final Reparacion? reparacion;

	const IngresoDto({
		required this.id,
		required this.numero,
		required this.unidadId,
		required this.unidad,
		this.clienteOrigen,
		this.indicadorOrigenId,
		this.indicadorOrigen,
		this.recepcionId,
		this.servicioId,
		this.tecnico,
		this.fechaIngreso,
		this.observacionTecnico,
		required this.estado,
		this.falla,
		this.reparacion,
	});

	factory IngresoDto.fromJson(Map<String, dynamic> json) {
		final falla = JsonFabrica.mapa(json['falla']);
		final reparacion = JsonFabrica.mapa(json['reparacion']);
		final unidadId = JsonFabrica.texto(json['unidadId']);
		return IngresoDto(
			id: JsonFabrica.texto(json['id']),
			numero: JsonFabrica.entero(json['numero']),
			unidadId: unidadId,
			unidad: UnidadDto.fromJson(
				JsonFabrica.mapa(json['unidad']) ?? {'id': unidadId},
			).aEntidad(),
			clienteOrigen: clienteFabricaOpcional(json['clienteOrigen']),
			indicadorOrigenId: JsonFabrica.textoOpcional(json['indicadorOrigenId']),
			indicadorOrigen: indicadorFabricaOpcional(json['indicadorOrigen']),
			recepcionId: JsonFabrica.textoOpcional(json['recepcionId']),
			servicioId: JsonFabrica.textoOpcional(json['servicioId']),
			tecnico: usuarioFabricaOpcional(json['tecnico']),
			fechaIngreso: JsonFabrica.fecha(json['fechaIngreso']),
			observacionTecnico: JsonFabrica.textoOpcional(json['observacionTecnico']),
			estado: CodigosFabrica.estadoIngreso(json['estado']),
			falla: falla == null ? null : FallaDto.fromJson(falla).aEntidad(),
			reparacion: reparacion == null ? null : ReparacionDto.fromJson(reparacion).aEntidad(),
		);
	}

	Ingreso aEntidad() {
		return Ingreso(
			id: id,
			numero: numero,
			unidadId: unidadId,
			unidad: unidad,
			clienteOrigen: clienteOrigen,
			indicadorOrigenId: indicadorOrigenId,
			indicadorOrigen: indicadorOrigen,
			recepcionId: recepcionId,
			servicioId: servicioId,
			tecnico: tecnico,
			fechaIngreso: fechaIngreso,
			observacionTecnico: observacionTecnico,
			estado: estado,
			falla: falla,
			reparacion: reparacion,
		);
	}
}
