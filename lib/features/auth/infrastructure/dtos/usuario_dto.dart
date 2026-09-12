import 'package:cliente_feedback_tecnico/features/auth/domain/entities/usuario.dart';

class UsuarioDto extends Usuario {
	const UsuarioDto({
		required super.id,
		required super.fullName,
		required super.email,
		required super.roles,
	});

	factory UsuarioDto.fromJson(Map<String, dynamic> json) {
		return UsuarioDto(
			id: json['id']?.toString() ?? '',
			fullName: json['fullName']?.toString() ?? '',
			email: json['email']?.toString() ?? '',
			roles: _rolesDesdeJson(json['roles']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'fullName': fullName,
			'email': email,
			'roles': roles,
		};
	}

	static List<String> _rolesDesdeJson(dynamic valor) {
		if (valor is! List) {
			return const [];
		}

		return valor
				.map((rol) => rol?.toString() ?? '')
				.where((rol) => rol.isNotEmpty)
				.toList();
	}
}
