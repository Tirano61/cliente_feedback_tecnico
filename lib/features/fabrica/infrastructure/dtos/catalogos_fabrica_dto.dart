import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/dtos/json_fabrica.dart';

/// Embebido en la falla llega sin `activo`: se toma como activo.
class ComponenteDto {
	final String id;
	final String nombre;
	final String productoId;
	final bool activo;

	const ComponenteDto({
		required this.id,
		required this.nombre,
		required this.productoId,
		required this.activo,
	});

	factory ComponenteDto.fromJson(Map<String, dynamic> json) {
		return ComponenteDto(
			id: JsonFabrica.texto(json['id']),
			nombre: JsonFabrica.texto(json['nombre']),
			productoId: JsonFabrica.texto(json['productoId']),
			activo: JsonFabrica.booleano(json['activo'], porDefecto: true),
		);
	}

	Componente aEntidad() {
		return Componente(id: id, nombre: nombre, productoId: productoId, activo: activo);
	}
}

class CausaDto {
	final String id;
	final String nombre;
	final bool activo;

	const CausaDto({
		required this.id,
		required this.nombre,
		required this.activo,
	});

	factory CausaDto.fromJson(Map<String, dynamic> json) {
		return CausaDto(
			id: JsonFabrica.texto(json['id']),
			nombre: JsonFabrica.texto(json['nombre']),
			activo: JsonFabrica.booleano(json['activo'], porDefecto: true),
		);
	}

	Causa aEntidad() {
		return Causa(id: id, nombre: nombre, activo: activo);
	}
}
