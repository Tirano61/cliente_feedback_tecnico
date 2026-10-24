import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';

class ProductoFabricaDto {
	final String id;
	final String nombre;
	final String? version;

	const ProductoFabricaDto({
		required this.id,
		required this.nombre,
		this.version,
	});

	factory ProductoFabricaDto.fromJson(Map<String, dynamic> json) {
		return ProductoFabricaDto(
			id: JsonFabrica.texto(json['id']),
			nombre: JsonFabrica.texto(json['nombre']),
			version: JsonFabrica.textoOpcional(json['version']),
		);
	}

	ProductoFabrica aEntidad() {
		return ProductoFabrica(id: id, nombre: nombre, version: version);
	}
}

class ClienteFabricaDto {
	final String id;
	final String nombre;
	final String? cuit;

	const ClienteFabricaDto({
		required this.id,
		required this.nombre,
		this.cuit,
	});

	factory ClienteFabricaDto.fromJson(Map<String, dynamic> json) {
		return ClienteFabricaDto(
			id: JsonFabrica.texto(json['id']),
			nombre: JsonFabrica.texto(json['nombre']),
			cuit: JsonFabrica.textoOpcional(json['cuit']),
		);
	}

	ClienteFabrica aEntidad() {
		return ClienteFabrica(id: id, nombre: nombre, cuit: cuit);
	}
}

class UsuarioFabricaDto {
	final String? id;
	final String fullName;

	const UsuarioFabricaDto({
		this.id,
		required this.fullName,
	});

	factory UsuarioFabricaDto.fromJson(Map<String, dynamic> json) {
		return UsuarioFabricaDto(
			id: JsonFabrica.textoOpcional(json['id']),
			fullName: JsonFabrica.texto(json['fullName']),
		);
	}

	UsuarioFabrica aEntidad() {
		return UsuarioFabrica(id: id, fullName: fullName);
	}
}

class IndicadorFabricaDto {
	final String? id;
	final String nroSerie;

	const IndicadorFabricaDto({
		this.id,
		required this.nroSerie,
	});

	factory IndicadorFabricaDto.fromJson(Map<String, dynamic> json) {
		return IndicadorFabricaDto(
			id: JsonFabrica.textoOpcional(json['id']),
			nroSerie: JsonFabrica.texto(json['nroSerie']),
		);
	}

	IndicadorFabrica aEntidad() {
		return IndicadorFabrica(id: id, nroSerie: nroSerie);
	}
}

/// Atajos para los objetos embebidos que pueden venir en null.
ProductoFabrica? productoFabricaOpcional(dynamic json) {
	final mapa = JsonFabrica.mapa(json);
	return mapa == null ? null : ProductoFabricaDto.fromJson(mapa).aEntidad();
}

ClienteFabrica? clienteFabricaOpcional(dynamic json) {
	final mapa = JsonFabrica.mapa(json);
	return mapa == null ? null : ClienteFabricaDto.fromJson(mapa).aEntidad();
}

UsuarioFabrica? usuarioFabricaOpcional(dynamic json) {
	final mapa = JsonFabrica.mapa(json);
	return mapa == null ? null : UsuarioFabricaDto.fromJson(mapa).aEntidad();
}

IndicadorFabrica? indicadorFabricaOpcional(dynamic json) {
	final mapa = JsonFabrica.mapa(json);
	return mapa == null ? null : IndicadorFabricaDto.fromJson(mapa).aEntidad();
}
