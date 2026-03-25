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
	bool _ocultarContrasena = true;

	@override
	void dispose() {
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
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
				body: Stack(
					children: [
						Container(
							decoration: const BoxDecoration(
								gradient: LinearGradient(
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
									colors: [
										Color(0xFFE9F1FB),
										Color(0xFFF8FAFD),
									],
								),
							),
						),
						Align(
							alignment: Alignment.topRight,
							child: Container(
								width: 180,
								height: 180,
								margin: const EdgeInsets.only(top: 40, right: 24),
								decoration: BoxDecoration(
									shape: BoxShape.circle,
									color: theme.colorScheme.primary.withValues(alpha: 0.10),
								),
							),
						),
						Align(
							alignment: Alignment.bottomLeft,
							child: Container(
								width: 240,
								height: 240,
								margin: const EdgeInsets.only(left: 18, bottom: 30),
								decoration: BoxDecoration(
									shape: BoxShape.circle,
									color: theme.colorScheme.secondary.withValues(alpha: 0.08),
								),
							),
						),
						SafeArea(
							child: Center(
								child: SingleChildScrollView(
									padding: const EdgeInsets.all(20),
									child: ConstrainedBox(
										constraints: const BoxConstraints(maxWidth: 460),
										child: Card(
											elevation: 1,
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(22),
											),
											child: Padding(
												padding: const EdgeInsets.all(22),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Container(
															width: 48,
															height: 48,
															decoration: BoxDecoration(
																color: theme.colorScheme.primary.withValues(alpha: 0.13),
																borderRadius: BorderRadius.circular(14),
															),
															child: Icon(
																Icons.build_circle_outlined,
																color: theme.colorScheme.primary,
															),
														),
														const SizedBox(height: 16),
														Text(
															'Ingreso de tecnico',
															style: theme.textTheme.headlineSmall?.copyWith(
																fontWeight: FontWeight.w700,
															),
														),
														const SizedBox(height: 6),
														Text(
															'Accede para registrar y gestionar ordenes de servicio.',
															style: theme.textTheme.bodyMedium?.copyWith(
																color: theme.colorScheme.onSurfaceVariant,
															),
														),
														const SizedBox(height: 20),
														TextField(
															controller: _emailController,
															keyboardType: TextInputType.emailAddress,
															autofillHints: const [AutofillHints.username],
															decoration: const InputDecoration(
																labelText: 'Email',
																prefixIcon: Icon(Icons.alternate_email_rounded),
															),
														),
														const SizedBox(height: 12),
														TextField(
															controller: _passwordController,
															obscureText: _ocultarContrasena,
															autofillHints: const [AutofillHints.password],
															decoration: InputDecoration(
																labelText: 'Contrasena',
																prefixIcon: const Icon(Icons.lock_outline_rounded),
																suffixIcon: IconButton(
																	onPressed: () {
																		setState(() {
																			_ocultarContrasena = !_ocultarContrasena;
																		});
																	},
																	icon: Icon(
																		_ocultarContrasena
																			? Icons.visibility_outlined
																			: Icons.visibility_off_outlined,
																	),
																),
															),
														),
														const SizedBox(height: 18),
														BlocBuilder<AuthBloc, AuthState>(
															builder: (context, state) {
																final cargando = state is AuthLoading;
																return SizedBox(
																	width: double.infinity,
																	child: ElevatedButton(
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
																		style: ElevatedButton.styleFrom(
																		padding: const EdgeInsets.symmetric(vertical: 14),
																		shape: RoundedRectangleBorder(
																			borderRadius: BorderRadius.circular(12),
																		),
																	),
																	child: Text(cargando ? 'Ingresando...' : 'Ingresar'),
																),
																);
															},
														),
													],
												),
											),
										),
									),
								),
							),
						),
					],
				),
			),
		);
	}
}
