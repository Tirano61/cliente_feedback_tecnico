import 'package:cliente_feedback_tecnico/features/auth/infrastructure/dtos/usuario_dto.dart';

class LoginResponseDto {
	final String accessToken;
	final UsuarioDto usuario;

	const LoginResponseDto({
		required this.accessToken,
		required this.usuario,
	});

	factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
		final dynamic user = json['user'];

		return LoginResponseDto(
			accessToken: json['access_token']?.toString() ?? '',
			usuario: UsuarioDto.fromJson(
				user is Map<String, dynamic> ? user : const <String, dynamic>{},
			),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'access_token': accessToken,
			'user': usuario.toJson(),
		};
	}
}
