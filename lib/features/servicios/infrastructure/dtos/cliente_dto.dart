import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';

class ClienteDto extends Cliente {
	const ClienteDto({
		required super.id,
		required super.nombre,
		super.cuit,
		super.contacto,
		super.telefono,
	});

	factory ClienteDto.fromJson(Map<String, dynamic> json) {
		return ClienteDto(
			id: json['id']?.toString() ?? '',
			nombre: json['nombre']?.toString() ?? '',
			cuit: json['cuit']?.toString(),
			contacto: json['contacto']?.toString(),
			telefono: json['telefono']?.toString(),
		);
	}
}
