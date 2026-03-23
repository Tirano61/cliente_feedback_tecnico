import 'package:cliente_feedback_tecnico/features/casos/presentation/widgets/formulario_caso.dart';
import 'package:flutter/material.dart';

class NuevoCasoPage extends StatelessWidget {
	const NuevoCasoPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Nuevo caso')),
			body: const Padding(
				padding: EdgeInsets.all(16),
				child: FormularioCaso(),
			),
		);
	}
}
