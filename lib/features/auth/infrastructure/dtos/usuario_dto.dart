import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';

class UsuarioDto extends Usuario {
	const UsuarioDto({
		required super.id,
		required super.nombre,
		required super.email,
		required super.rol,
	});

	factory UsuarioDto.fromJson(Map<String, dynamic> json) {
		return UsuarioDto(
			id: json['id']?.toString() ?? '',
			nombre: json['nombre']?.toString() ?? '',
			email: json['email']?.toString() ?? '',
			rol: json['rol']?.toString() ?? 'tecnico',
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'nombre': nombre,
			'email': email,
			'rol': rol,
		};
	}
}
