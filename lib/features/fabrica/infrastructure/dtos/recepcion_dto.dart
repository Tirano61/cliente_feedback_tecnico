import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/ingreso_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/referencias_fabrica_dto.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/unidad_dto.dart';

class CambioEstadoRecepcionDto {
	final EstadoRecepcion estado;
	final DateTime? fecha;
	final String? usuarioId;
	final String? usuarioNombre;
	final String? observacion;

	const CambioEstadoRecepcionDto({
		required this.estado,
		this.fecha,
		this.usuarioId,
		this.usuarioNombre,
		this.observacion,
	});

	factory CambioEstadoRecepcionDto.fromJson(Map<String, dynamic> json) {
		return CambioEstadoRecepcionDto(
			estado: CodigosFabrica.estadoRecepcion(json['estado']),
			fecha: JsonFabrica.fecha(json['fecha']),
			usuarioId: JsonFabrica.textoOpcional(json['usuarioId']),
			usuarioNombre: JsonFabrica.textoOpcional(json['usuarioNombre']),
			observacion: JsonFabrica.textoOpcional(json['observacion']),
		);
	}

	CambioEstadoRecepcion aEntidad() {
		return CambioEstadoRecepcion(
			estado: estado,
			fecha: fecha,
			usuarioId: usuarioId,
			usuarioNombre: usuarioNombre,
			observacion: observacion,
		);
	}
}

/// Respuesta de `POST /fabrica/recepciones`, `GET /fabrica/recepciones/:id`,
/// los PATCH de la recepcion y cada item del listado.
class RecepcionDto {
	final String id;
	final int numero;
	final ClienteFabrica cliente;
	final String indicadorId;
	final Unidad indicador;
	final String queLlego;
	final String sintomaReportado;
	final UsuarioFabrica? tecnicoRecepcion;
	final DateTime? fechaRecepcion;
	final EstadoRecepcion estado;
	final List<CambioEstadoRecepcion> historialEstados;
	final String? servicioId;
	final DateTime? fechaDevolucion;
	final FormaDevolucion? formaDevolucion;
	final String? observaciones;
	final List<Ingreso> ingresos;
	final List<Unidad> piezasInstaladas;

	const RecepcionDto({
		required this.id,
		required this.numero,
		required this.cliente,
		required this.indicadorId,
		required this.indicador,
		required this.queLlego,
		required this.sintomaReportado,
		this.tecnicoRecepcion,
		this.fechaRecepcion,
		required this.estado,
		this.historialEstados = const [],
		this.servicioId,
		this.fechaDevolucion,
		this.formaDevolucion,
		this.observaciones,
		this.ingresos = const [],
		this.piezasInstaladas = const [],
	});

	factory RecepcionDto.fromJson(Map<String, dynamic> json) {
		final indicadorId = JsonFabrica.texto(json['indicadorId']);
		return RecepcionDto(
			id: JsonFabrica.texto(json['id']),
			numero: JsonFabrica.entero(json['numero']),
			cliente: ClienteFabricaDto.fromJson(
				JsonFabrica.mapa(json['cliente']) ?? const {},
			).aEntidad(),
			indicadorId: indicadorId,
			indicador: UnidadDto.fromJson(
				JsonFabrica.mapa(json['indicador']) ?? {'id': indicadorId, 'tipo': 'indicador'},
			).aEntidad(),
			queLlego: JsonFabrica.texto(json['queLlego']),
			sintomaReportado: JsonFabrica.texto(json['sintomaReportado']),
			tecnicoRecepcion: usuarioFabricaOpcional(json['tecnicoRecepcion']),
			fechaRecepcion: JsonFabrica.fecha(json['fechaRecepcion']),
			estado: CodigosFabrica.estadoRecepcion(json['estado']),
			historialEstados: JsonFabrica.listaDeMapas(json['historialEstados'])
					.map((item) => CambioEstadoRecepcionDto.fromJson(item).aEntidad())
					.toList(),
			servicioId: JsonFabrica.textoOpcional(json['servicioId']),
			fechaDevolucion: JsonFabrica.fecha(json['fechaDevolucion']),
			formaDevolucion: CodigosFabrica.formaDevolucion(json['formaDevolucion']),
			observaciones: JsonFabrica.textoOpcional(json['observaciones']),
			ingresos: JsonFabrica.listaDeMapas(json['ingresos'])
					.map((item) => IngresoDto.fromJson(item).aEntidad())
					.toList(),
			piezasInstaladas: unidadesDesdeJson(json['piezasInstaladas']),
		);
	}

	Recepcion aEntidad() {
		return Recepcion(
			id: id,
			numero: numero,
			cliente: cliente,
			indicadorId: indicadorId,
			indicador: indicador,
			queLlego: queLlego,
			sintomaReportado: sintomaReportado,
			tecnicoRecepcion: tecnicoRecepcion,
			fechaRecepcion: fechaRecepcion,
			estado: estado,
			historialEstados: historialEstados,
			servicioId: servicioId,
			fechaDevolucion: fechaDevolucion,
			formaDevolucion: formaDevolucion,
			observaciones: observaciones,
			ingresos: ingresos,
			piezasInstaladas: piezasInstaladas,
		);
	}
}
