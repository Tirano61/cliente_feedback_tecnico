import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
	final String id;
	final String fullName;
	final String email;
	final List<String> roles;

	const Usuario({
		required this.id,
		required this.fullName,
		required this.email,
		required this.roles,
	});

	@override
	List<Object> get props => [id, fullName, email, roles];
}
