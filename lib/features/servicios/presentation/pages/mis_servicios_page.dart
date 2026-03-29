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
	final TextEditingController _busquedaController = TextEditingController();
	String _busquedaTexto = '';

	@override
	void initState() {
		super.initState();
		context.read<ServicioBloc>().add(const MisServiciosSolicitados());
	}

	@override
	void dispose() {
		_busquedaController.dispose();
		super.dispose();
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
									Padding(
										padding: const EdgeInsets.symmetric(horizontal: 16),
										child: TextField(
											controller: _busquedaController,
											decoration: const InputDecoration(
												prefixIcon: Icon(Icons.search),
												labelText: 'Buscar por sintoma, modelo, serie o ID',
											),
											onChanged: (valor) {
												setState(() {
													_busquedaTexto = valor;
												});
											},
										),
									),
									const SizedBox(height: 10),
									_FiltrosEstado(
										filtroSeleccionado: _filtroSeleccionado,
										onChanged: (filtro) {
											setState(() => _filtroSeleccionado = filtro);
										},
									),
									const Expanded(
										child: Center(
											child: Text('No hay servicios para los filtros aplicados.'),
										),
									),
								],
							);
						}

						return Column(
							children: [
								const SizedBox(height: 12),
								Padding(
									padding: const EdgeInsets.symmetric(horizontal: 16),
									child: TextField(
										controller: _busquedaController,
										decoration: const InputDecoration(
											prefixIcon: Icon(Icons.search),
											labelText: 'Buscar por sintoma, modelo, serie o ID',
										),
										onChanged: (valor) {
											setState(() {
												_busquedaTexto = valor;
											});
										},
									),
								),
								const SizedBox(height: 10),
								_FiltrosEstado(
									filtroSeleccionado: _filtroSeleccionado,
									onChanged: (filtro) {
										setState(() => _filtroSeleccionado = filtro);
									},
								),
								Padding(
									padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
									child: Align(
										alignment: Alignment.centerLeft,
										child: Text(
											'Se muestran ${serviciosFiltrados.length} de ${state.servicios.length} servicios',
											style: Theme.of(context).textTheme.bodySmall,
										),
									),
								),
								Expanded(
									child: RefreshIndicator(
										onRefresh: () async {
											context.read<ServicioBloc>().add(const MisServiciosSolicitados());
										},
										child: ListView.separated(
											padding: const EdgeInsets.all(16),
											itemCount: serviciosFiltrados.length,
											separatorBuilder: (_, _) => const SizedBox(height: 12),
											itemBuilder: (context, index) {
												final servicio = serviciosFiltrados[index];
												return _TarjetaServicio(servicio: servicio);
											},
										),
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
		final texto = _busquedaTexto.trim().toLowerCase();

		final filtrados = servicios.where((servicio) {
			final coincideEstado = switch (_filtroSeleccionado) {
				FiltroEstado.aprobados => servicio.aprobado,
				FiltroEstado.pendientes => !servicio.aprobado,
				FiltroEstado.todos => true,
			};

			if (!coincideEstado) {
				return false;
			}

			if (texto.isEmpty) {
				return true;
			}

			return servicio.sintoma.toLowerCase().contains(texto) ||
					servicio.equipoModelo.toLowerCase().contains(texto) ||
					servicio.equipoNroSerie.toLowerCase().contains(texto) ||
					servicio.id.toLowerCase().contains(texto);
		}).toList();

		filtrados.sort((a, b) {
			final fechaA = a.fechaHoraServicio ?? a.fecha;
			final fechaB = b.fechaHoraServicio ?? b.fecha;
			if (fechaA == null && fechaB == null) {
				return 0;
			}
			if (fechaA == null) {
				return 1;
			}
			if (fechaB == null) {
				return -1;
			}
			return fechaB.compareTo(fechaA);
		});

		return filtrados;
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
		final estadoVisual = _resolverEstadoVisual(servicio);
		final fechaOrden = servicio.fechaHoraServicio ?? servicio.fecha;
		final fecha = fechaOrden == null ? 'Sin fecha informada' : _formatearFecha(fechaOrden);

		return Card(
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(12),
				side: BorderSide(color: estadoVisual.color.withValues(alpha: 0.6), width: 1.4),
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
										'${servicio.canal.name.toUpperCase()} - ${servicio.id.isEmpty ? 'sin-id' : servicio.id}',
										style: const TextStyle(fontWeight: FontWeight.w600),
									),
								),
								Container(
									padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
									decoration: BoxDecoration(
										color: estadoVisual.color.withValues(alpha: 0.14),
										borderRadius: BorderRadius.circular(999),
									),
									child: Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Icon(estadoVisual.icono, color: estadoVisual.color, size: 16),
											const SizedBox(width: 6),
											Text(
												estadoVisual.texto,
												style: TextStyle(
													fontWeight: FontWeight.w600,
													fontSize: 12,
													color: estadoVisual.color,
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
							'Modelo: ${servicio.equipoModelo} | Serie: ${servicio.equipoNroSerie} | Km: ${servicio.km}',
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
						if (servicio.facturacion != null) ...[
							const SizedBox(height: 8),
							Text(
								'Total facturado ARS: ${servicio.facturacion!.totalFinalArs.toStringAsFixed(2)}',
								style: const TextStyle(fontWeight: FontWeight.w600),
							),
						],
					],
				),
			),
		);
	}

	_EstadoServicioVisual _resolverEstadoVisual(Servicio servicio) {
		if (servicio.aprobado) {
			return const _EstadoServicioVisual(
				color: Colors.green,
				texto: 'Aprobado',
				icono: Icons.verified,
			);
		}
		if (servicio.resuelto) {
			return const _EstadoServicioVisual(
				color: Colors.blue,
				texto: 'Resuelto',
				icono: Icons.task_alt,
			);
		}
		return const _EstadoServicioVisual(
			color: Colors.orange,
			texto: 'Pendiente de aprobacion',
			icono: Icons.pending_actions,
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

class _EstadoServicioVisual {
	final Color color;
	final String texto;
	final IconData icono;

	const _EstadoServicioVisual({
		required this.color,
		required this.texto,
		required this.icono,
	});
}


