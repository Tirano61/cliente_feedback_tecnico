import 'package:cliente_feedback_tecnico/features/servicios/presentation/widgets/formulario_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/pages/liquidaciones_screen.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/pages/mis_servicios_page.dart';

class NuevaOrdenServicioPage extends StatelessWidget {
	const NuevaOrdenServicioPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Nueva orden de servicio'),
				actions: [
					IconButton(
						onPressed: () {
							Navigator.of(context).push(
								MaterialPageRoute(builder: (_) => const LiquidacionesScreen()),
							);
						},
						icon: const Icon(Icons.payments_outlined),
						tooltip: 'Liquidaciones',
					),
					IconButton(
						onPressed: () {
							Navigator.of(context).push(
								MaterialPageRoute(builder: (_) => const MisServiciosPage()),
							);
						},
						icon: const Icon(Icons.list_alt),
						tooltip: 'Mis servicios',
					),
					IconButton(
						onPressed: () => _confirmarCierreSesion(context),
						icon: const Icon(Icons.logout),
						tooltip: 'Cerrar sesion',
					),
				],
			),
			body: const Padding(
				padding: EdgeInsets.all(4),
				child: FormularioServicio(),
			),
		);
	}

	Future<void> _confirmarCierreSesion(BuildContext context) async {
		final authBloc = context.read<AuthBloc>();

		final confirmado = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Cerrar sesion'),
					content: const Text(
						'Vas a volver a la pantalla de ingreso y se pierde lo que no hayas guardado.',
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Cancelar'),
						),
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							child: const Text('Cerrar sesion'),
						),
					],
				);
			},
		);

		if (confirmado == true) {
			authBloc.add(const LogoutRequested());
		}
	}
}
