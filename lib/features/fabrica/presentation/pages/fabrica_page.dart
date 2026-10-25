import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/ingresos_tab.dart';
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
						_PestanaProximamente(
							texto: 'Acá vas a poder buscar piezas por número de serie, ver las '
									'placas reacondicionadas disponibles y el historial de cada pieza.',
						),
					],
				),
			),
		);
	}
}

class _PestanaProximamente extends StatelessWidget {
	final String texto;

	const _PestanaProximamente({required this.texto});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 32),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(
							Icons.construction_outlined,
							size: 40,
							color: Theme.of(context).colorScheme.onSurfaceVariant,
						),
						const SizedBox(height: 12),
						Text(
							'Próximamente',
							style: Theme.of(context).textTheme.titleMedium,
						),
						const SizedBox(height: 8),
						Text(texto, textAlign: TextAlign.center),
					],
				),
			),
		);
	}
}
