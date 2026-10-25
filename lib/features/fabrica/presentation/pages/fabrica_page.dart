import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/ingresos_tab.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/piezas_tab.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/recepciones_tab.dart';
import 'package:flutter/material.dart';

/// Trabajo en fabrica: equipos de clientes, piezas ingresadas y piezas.
class FabricaPage extends StatelessWidget {
	const FabricaPage({super.key});

	@override
	Widget build(BuildContext context) {
		return DefaultTabController(
			length: 3,
			child: Scaffold(
				appBar: AppBar(
					title: const Text('Fábrica'),
					bottom: const TabBar(
						isScrollable: true,
						tabAlignment: TabAlignment.start,
						labelColor: Colors.white,
						unselectedLabelColor: Colors.white70,
						indicatorColor: Colors.white,
						tabs: [
							Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Equipos en fábrica'),
							Tab(icon: Icon(Icons.move_to_inbox_outlined), text: 'Piezas ingresadas'),
							Tab(icon: Icon(Icons.memory), text: 'Piezas'),
						],
					),
				),
				body: const TabBarView(
					children: [
						RecepcionesTab(),
						IngresosTab(),
						PiezasTab(),
					],
				),
			),
		);
	}
}
