import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/codigos_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/referencias_fabrica_dto.dart';

class UnidadDto {
	final String id;
	final TipoUnidad tipo;
	final String nroSerie;
	final EstadoUnidad estado;
	final ProductoFabrica? producto;
	final String? indicadorActualId;
	final List<Unidad> piezasInstaladas;

	const UnidadDto({
		required this.id,
		required this.tipo,
		required this.nroSerie,
		required this.estado,
		this.producto,
		this.indicadorActualId,
		this.piezasInstaladas = const [],
	});

	factory UnidadDto.fromJson(Map<String, dynamic> json) {
		return UnidadDto(
			id: JsonFabrica.texto(json['id']),
			tipo: CodigosFabrica.tipoUnidad(json['tipo']),
			nroSerie: JsonFabrica.texto(json['nroSerie']),
			estado: CodigosFabrica.estadoUnidad(json['estado']),
			producto: productoFabricaOpcional(json['producto']),
			indicadorActualId: JsonFabrica.textoOpcional(json['indicadorActualId']),
			piezasInstaladas: unidadesDesdeJson(json['piezasInstaladas']),
		);
	}

	Unidad aEntidad() {
		return Unidad(
			id: id,
			tipo: tipo,
			nroSerie: nroSerie,
			estado: estado,
			producto: producto,
			indicadorActualId: indicadorActualId,
			piezasInstaladas: piezasInstaladas,
		);
	}
}

List<Unidad> unidadesDesdeJson(dynamic json) {
	return JsonFabrica.listaDeMapas(json)
			.map((item) => UnidadDto.fromJson(item).aEntidad())
			.toList();
}
