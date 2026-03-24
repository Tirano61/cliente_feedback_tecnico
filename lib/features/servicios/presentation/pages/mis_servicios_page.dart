import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MisServiciosPage extends StatefulWidget {
	const MisServiciosPage({super.key});

	@override
	State<MisServiciosPage> createState() => _MisServiciosPageState();
}

class _MisServiciosPageState extends State<MisServiciosPage> {
	FiltroEstado _filtroSeleccionado = FiltroEstado.todos;

	@override
	void initState() {
		super.initState();
		context.read<ServicioBloc>().add(const MisServiciosSolicitados());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Mis servicios')),
			body: BlocBuilder<ServicioBloc, ServicioState>(
				builder: (context, state) {
					if (state is MisServiciosLoading) {
						return const Center(child: CircularProgressIndicator());
					}

					if (state is ServicioError) {
						return Center(child: Text(state.mensaje));
					}

					if (state is MisServiciosLoaded) {
						final serviciosFiltrados = _filtrarServicios(state.servicios);

						if (state.servicios.isEmpty) {
							return const Center(child: Text('No hay servicios cargados.'));
						}

						if (serviciosFiltrados.isEmpty) {
							return Column(
								children: [
									const SizedBox(height: 12),
									_FiltrosEstado(
										filtroSeleccionado: _filtroSeleccionado,
										onChanged: (filtro) {
											setState(() => _filtroSeleccionado = filtro);
										},
									),
									const Expanded(
										child: Center(
											child: Text('No hay servicios para este filtro.'),
										),
									),
								],
							);
						}

						return Column(
							children: [
								const SizedBox(height: 12),
								_FiltrosEstado(
									filtroSeleccionado: _filtroSeleccionado,
									onChanged: (filtro) {
										setState(() => _filtroSeleccionado = filtro);
									},
								),
								Expanded(
									child: ListView.separated(
										padding: const EdgeInsets.all(16),
										itemCount: serviciosFiltrados.length,
										separatorBuilder: (_, __) => const SizedBox(height: 12),
										itemBuilder: (context, index) {
											final servicio = serviciosFiltrados[index];
											return _TarjetaServicio(servicio: servicio);
										},
									),
								),
							],
						);
					}

					return const SizedBox.shrink();
				},
			),
		);
	}

	List<Servicio> _filtrarServicios(List<Servicio> servicios) {
		switch (_filtroSeleccionado) {
			case FiltroEstado.aprobados:
				return servicios.where((servicio) => servicio.aprobado).toList();
			case FiltroEstado.pendientes:
				return servicios.where((servicio) => !servicio.aprobado).toList();
			case FiltroEstado.todos:
				return servicios;
		}
	}
}

enum FiltroEstado { todos, aprobados, pendientes }

class _FiltrosEstado extends StatelessWidget {
	final FiltroEstado filtroSeleccionado;
	final ValueChanged<FiltroEstado> onChanged;

	const _FiltrosEstado({
		required this.filtroSeleccionado,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
			scrollDirection: Axis.horizontal,
			padding: const EdgeInsets.symmetric(horizontal: 16),
			child: Row(
				children: [
					ChoiceChip(
						label: const Text('Todos'),
						selected: filtroSeleccionado == FiltroEstado.todos,
						onSelected: (_) => onChanged(FiltroEstado.todos),
					),
					const SizedBox(width: 8),
					ChoiceChip(
						label: const Text('Aprobados'),
						selected: filtroSeleccionado == FiltroEstado.aprobados,
						onSelected: (_) => onChanged(FiltroEstado.aprobados),
					),
					const SizedBox(width: 8),
					ChoiceChip(
						label: const Text('Pendientes'),
						selected: filtroSeleccionado == FiltroEstado.pendientes,
						onSelected: (_) => onChanged(FiltroEstado.pendientes),
					),
				],
			),
		);
	}
}

class _TarjetaServicio extends StatelessWidget {
	final Servicio servicio;

	const _TarjetaServicio({required this.servicio});

	@override
	Widget build(BuildContext context) {
		final aprobado = servicio.aprobado;
		final colorEstado = aprobado ? Colors.green : Colors.orange;
		final textoEstado = aprobado ? 'Aprobado' : 'Pendiente de aprobacion';
		final iconoEstado = aprobado ? Icons.verified : Icons.pending_actions;
		final fecha = _formatearFecha(servicio.fecha);

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
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Expanded(
									child: Text(
										'Canal: ${servicio.canal.name}',
										style: const TextStyle(fontWeight: FontWeight.w600),
									),
								),
								Container(
									padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
									decoration: BoxDecoration(
										color: colorEstado.withValues(alpha: 0.14),
										borderRadius: BorderRadius.circular(999),
									),
									child: Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Icon(iconoEstado, color: colorEstado, size: 16),
											const SizedBox(width: 6),
											Text(
												textoEstado,
												style: TextStyle(
													fontWeight: FontWeight.w600,
													fontSize: 12,
													color: colorEstado,
												),
											),
										],
									),
								),
							],
						),
						const SizedBox(height: 6),
						Text(
							fecha,
							style: TextStyle(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
								fontSize: 12,
							),
						),
						const SizedBox(height: 6),
						Text(
							servicio.sintoma,
							maxLines: 2,
							overflow: TextOverflow.ellipsis,
						),
					],
				),
			),
		);
	}

	String _formatearFecha(DateTime fecha) {
		final local = fecha.toLocal();
		final dia = local.day.toString().padLeft(2, '0');
		final mes = local.month.toString().padLeft(2, '0');
		final anio = local.year;
		final hora = local.hour.toString().padLeft(2, '0');
		final minuto = local.minute.toString().padLeft(2, '0');
		return '$dia/$mes/$anio - $hora:$minuto';
	}
}


