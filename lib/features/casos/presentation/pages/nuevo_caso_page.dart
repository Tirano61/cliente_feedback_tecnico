import 'package:cliente_feedback_tecnico/features/casos/presentation/widgets/formulario_caso.dart';
import 'package:flutter/material.dart';

import 'package:cliente_feedback_tecnico/features/casos/presentation/pages/mis_casos_page.dart';

class NuevoCasoPage extends StatelessWidget {
	const NuevoCasoPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Nuevo caso'),
				actions: [
					IconButton(
						onPressed: () {
							Navigator.of(context).push(
								MaterialPageRoute(builder: (_) => const MisCasosPage()),
							);
						},
						icon: const Icon(Icons.list_alt),
						tooltip: 'Mis servicios',
					),
				],
			),
			body: const Padding(
				padding: EdgeInsets.all(16),
				child: FormularioCaso(),
			),
		);
	}
}
