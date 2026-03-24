import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/bloc/caso_bloc.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/bloc/caso_event.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/bloc/caso_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MisCasosPage extends StatefulWidget {
	const MisCasosPage({super.key});

	@override
	State<MisCasosPage> createState() => _MisCasosPageState();
}

class _MisCasosPageState extends State<MisCasosPage> {
	@override
	void initState() {
		super.initState();
		context.read<CasoBloc>().add(const MisCasosSolicitados());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Mis servicios')),
			body: BlocBuilder<CasoBloc, CasoState>(
				builder: (context, state) {
					if (state is MisCasosLoading) {
						return const Center(child: CircularProgressIndicator());
					}

					if (state is CasoError) {
						return Center(child: Text(state.mensaje));
					}

					if (state is MisCasosLoaded) {
						if (state.casos.isEmpty) {
							return const Center(child: Text('No hay servicios cargados.'));
						}

						return ListView.separated(
							padding: const EdgeInsets.all(16),
							itemCount: state.casos.length,
							separatorBuilder: (_, __) => const SizedBox(height: 12),
							itemBuilder: (context, index) {
								final caso = state.casos[index];
								return _TarjetaServicio(caso: caso);
							},
						);
					}

					return const SizedBox.shrink();
				},
			),
		);
	}
}

class _TarjetaServicio extends StatelessWidget {
	final Caso caso;

	const _TarjetaServicio({required this.caso});

	@override
	Widget build(BuildContext context) {
		final aprobado = caso.aprobado;
		final colorEstado = aprobado ? Colors.green : Colors.orange;
		final textoEstado = aprobado ? 'Aprobado' : 'Pendiente de aprobacion';
		final iconoEstado = aprobado ? Icons.verified : Icons.pending_actions;

		return Card(
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(12),
				side: BorderSide(color: colorEstado.withValues(alpha: 0.6), width: 1.4),
			),
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Icon(iconoEstado, color: colorEstado),
								const SizedBox(width: 8),
								Text(
									textoEstado,
									style: TextStyle(
										fontWeight: FontWeight.bold,
										color: colorEstado,
									),
								),
							],
						),
						const SizedBox(height: 8),
						Text('Canal: ${caso.canal.name}'),
						Text('Fecha: ${caso.fecha.toLocal()}'),
						const SizedBox(height: 6),
						Text(
							caso.sintoma,
							maxLines: 2,
							overflow: TextOverflow.ellipsis,
						),
					],
				),
			),
		);
	}
}
