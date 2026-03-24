import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
	const LoginPage({super.key});

	@override
	State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocListener<AuthBloc, AuthState>(
			listenWhen: (previous, current) => current is AuthError,
			listener: (context, state) {
				if (state is AuthError) {
					ScaffoldMessenger.of(context)
						..hideCurrentSnackBar()
						..showSnackBar(SnackBar(content: Text(state.mensaje)));
				}
			},
			child: Scaffold(
				appBar: AppBar(title: const Text('Ingreso de tecnico')),
				body: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
						children: [
							TextField(
								controller: _emailController,
								keyboardType: TextInputType.emailAddress,
								decoration: const InputDecoration(labelText: 'Email'),
							),
							const SizedBox(height: 12),
							TextField(
								controller: _passwordController,
								obscureText: true,
								decoration: const InputDecoration(labelText: 'Contrasena'),
							),
							const SizedBox(height: 16),
							BlocBuilder<AuthBloc, AuthState>(
								builder: (context, state) {
									final cargando = state is AuthLoading;
									return ElevatedButton(
										onPressed: cargando
												? null
												: () {
														context.read<AuthBloc>().add(
																LoginSubmitted(
																	email: _emailController.text.trim(),
																	password: _passwordController.text,
																),
															);
													},
										child: Text(cargando ? 'Ingresando...' : 'Ingresar'),
									);
								},
							),
						],
					),
				),
			),
		);
	}
}
