import 'package:flutter/material.dart';

class MisCasosPage extends StatelessWidget {
	const MisCasosPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Mis casos')),
			body: const Center(
				child: Text('Listado de casos pendiente de implementacion'),
			),
		);
	}
}
