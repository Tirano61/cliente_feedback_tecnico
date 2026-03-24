import 'package:cliente_feedback_tecnico/features/servicios/presentation/widgets/formulario_servicio.dart';
import 'package:flutter/material.dart';

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
								MaterialPageRoute(builder: (_) => const MisServiciosPage()),
							);
						},
						icon: const Icon(Icons.list_alt),
						tooltip: 'Mis servicios',
					),
				],
			),
			body: const Padding(
				padding: EdgeInsets.all(16),
				child: FormularioServicio(),
			),
		);
	}
}

