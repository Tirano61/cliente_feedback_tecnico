import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepciones_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/nueva_recepcion_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/recepcion_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_recepcion_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pestaña "Equipos en fabrica": recepciones con buscador y filtros.
class RecepcionesTab extends StatefulWidget {
	const RecepcionesTab({super.key});

	@override
	State<RecepcionesTab> createState() => _RecepcionesTabState();
}

class _RecepcionesTabState extends State<RecepcionesTab> {
	final TextEditingController _busquedaController = TextEditingController();

	/// Ultima busqueda que el bloc le mostro a esta pantalla.
	String? _ultimaBusquedaDelBloc;

	@override
	void initState() {
		super.initState();
		context.read<RecepcionesBloc>().add(const RecepcionesSolicitadas());
	}

	@override
	void dispose() {
		_busquedaController.dispose();
		super.dispose();
	}

	Future<void> _abrirDetalle(Recepcion recepcion) async {
		final bloc = context.read<RecepcionesBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(
				builder: (_) => RecepcionDetallePage(recepcionId: recepcion.id),
			),
		);
		bloc.add(const RecepcionesRefrescadas());
	}

	Future<void> _abrirNuevaRecepcion() async {
		final bloc = context.read<RecepcionesBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(builder: (_) => const NuevaRecepcionPage()),
		);
		bloc.add(const RecepcionesRefrescadas());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			floatingActionButton: FloatingActionButton.extended(
				onPressed: _abrirNuevaRecepcion,
				icon: const Icon(Icons.add),
				label: const Text('Nueva recepción'),
			),
			body: BlocBuilder<RecepcionesBloc, RecepcionesState>(
				builder: _construirCuerpo,
			),
		);
	}

	Widget _construirCuerpo(BuildContext context, RecepcionesState state) {
		// El campo refleja la busqueda del bloc (se conserva al volver a entrar).
		// Solo se escribe cuando el bloc la cambio, para no pisar lo que se tipea.
		if (_ultimaBusquedaDelBloc != state.busqueda) {
			_ultimaBusquedaDelBloc = state.busqueda;
			if (_busquedaController.text != state.busqueda) {
				_busquedaController.text = state.busqueda;
				_busquedaController.selection = TextSelection.fromPosition(
					TextPosition(offset: _busquedaController.text.length),
				);
			}
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
							labelText: 'Buscar por número, cliente o serie del indicador',
						),
						onChanged: (valor) {
							context.read<RecepcionesBloc>().add(
								RecepcionesBusquedaCambiada(texto: valor),
							);
						},
					),
				),
				const SizedBox(height: 10),
				_Filtros(
					estados: state.estadosFiltrables,
					filtroEstado: state.filtroEstado,
					verDevueltas: state.verDevueltas,
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
					child: SizedBox(
						height: 4,
						child: state.actualizando ? const LinearProgressIndicator() : null,
					),
				),
				Expanded(child: _construirListado(context, state)),
			],
		);
	}

	Widget _construirListado(BuildContext context, RecepcionesState state) {
		if (state.cargando) {
			return const Center(child: CircularProgressIndicator());
		}

		final errorListado = state.errorListado;
		if (errorListado != null) {
			return Center(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 24),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Text(errorListado, textAlign: TextAlign.center),
							const SizedBox(height: 12),
							OutlinedButton.icon(
								onPressed: () {
									context.read<RecepcionesBloc>().add(const RecepcionesSolicitadas());
								},
								icon: const Icon(Icons.refresh),
								label: const Text('Reintentar'),
							),
						],
					),
				),
			);
		}

		if (state.recepciones.isEmpty) {
			return RefreshIndicator(
				onRefresh: () async {
					context.read<RecepcionesBloc>().add(const RecepcionesRefrescadas());
				},
				child: ListView(
					children: [
						const SizedBox(height: 120),
						Center(
							child: Text(
								state.actualizando
										? 'Buscando equipos...'
										: state.hayFiltrosActivos
												? 'No hay equipos para los filtros aplicados.'
												: 'No hay equipos en fábrica.',
								textAlign: TextAlign.center,
							),
						),
					],
				),
			);
		}

		final mostrarPie = state.hayMasPaginas || state.cargandoMas || state.errorPaginacion != null;

		return Column(
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
					child: Align(
						alignment: Alignment.centerLeft,
						child: Text(
							'Se muestran ${state.recepciones.length} de ${state.total} equipos',
							style: Theme.of(context).textTheme.bodySmall,
						),
					),
				),
				Expanded(
					child: RefreshIndicator(
						onRefresh: () async {
							context.read<RecepcionesBloc>().add(const RecepcionesRefrescadas());
						},
						child: NotificationListener<ScrollNotification>(
							// Cerca del final se pide la pagina siguiente; el bloc descarta
							// los pedidos repetidos mientras carga.
							onNotification: (notificacion) {
								if (notificacion.metrics.extentAfter < 400) {
									context.read<RecepcionesBloc>().add(
										const RecepcionesSiguientePaginaSolicitada(),
									);
								}
								return false;
							},
							child: ListView.separated(
								// Abajo queda lugar para que el boton flotante no tape la ultima.
								padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
								itemCount: state.recepciones.length + (mostrarPie ? 1 : 0),
								separatorBuilder: (_, _) => const SizedBox(height: 10),
								itemBuilder: (context, index) {
									if (index == state.recepciones.length) {
										return _PiePaginacion(
											cargandoMas: state.cargandoMas,
											errorPaginacion: state.errorPaginacion,
										);
									}

									final recepcion = state.recepciones[index];
									return _TarjetaRecepcion(
										recepcion: recepcion,
										dias: state.diasEnFabrica(recepcion),
										onTap: () => _abrirDetalle(recepcion),
									);
								},
							),
						),
					),
				),
			],
		);
	}
}

class _Filtros extends StatelessWidget {
	final List<EstadoRecepcion> estados;
	final EstadoRecepcion? filtroEstado;
	final bool verDevueltas;

	const _Filtros({
		required this.estados,
		required this.filtroEstado,
		required this.verDevueltas,
	});

	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
			scrollDirection: Axis.horizontal,
			padding: const EdgeInsets.symmetric(horizontal: 16),
			child: Row(
				children: [
					Padding(
						padding: const EdgeInsets.only(right: 8),
						child: ChoiceChip(
							label: const Text('Todos'),
							selected: filtroEstado == null,
							onSelected: (_) {
								context.read<RecepcionesBloc>().add(
									const RecepcionesFiltroEstadoCambiado(estado: null),
								);
							},
						),
					),
					for (final estado in estados)
						Padding(
							padding: const EdgeInsets.only(right: 8),
							child: ChoiceChip(
								label: Text(nombreEstadoRecepcion(estado)),
								selected: filtroEstado == estado,
								onSelected: (_) {
									context.read<RecepcionesBloc>().add(
										RecepcionesFiltroEstadoCambiado(estado: estado),
									);
								},
							),
						),
					const SizedBox(width: 8),
					FilterChip(
						avatar: const Icon(Icons.history, size: 18),
						label: const Text('Ver devueltas'),
						selected: verDevueltas,
						onSelected: (valor) {
							context.read<RecepcionesBloc>().add(
								RecepcionesVerDevueltasCambiado(verDevueltas: valor),
							);
						},
					),
				],
			),
		);
	}
}

class _TarjetaRecepcion extends StatelessWidget {
	final Recepcion recepcion;
	final int? dias;
	final VoidCallback onTap;

	const _TarjetaRecepcion({
		required this.recepcion,
		required this.dias,
		required this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final modelo = recepcion.indicador.producto?.nombre;

		return Card(
			child: InkWell(
				borderRadius: BorderRadius.circular(12),
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.all(14),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Expanded(
										child: Text(
											'N° ${recepcion.numero} · ${recepcion.cliente.nombre}',
											style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
										),
									),
									const SizedBox(width: 8),
									EstadoRecepcionBadge(estado: recepcion.estado),
								],
							),
							const SizedBox(height: 6),
							Text(
								modelo == null || modelo.isEmpty
										? 'Indicador ${recepcion.indicador.nroSerie}'
										: 'Indicador ${recepcion.indicador.nroSerie} · $modelo',
							),
							const SizedBox(height: 4),
							Row(
								children: [
									Icon(
										Icons.schedule,
										size: 16,
										color: Theme.of(context).colorScheme.onSurfaceVariant,
									),
									const SizedBox(width: 4),
									Text(textoDiasEnFabrica(dias), style: textTheme.bodySmall),
								],
							),
						],
					),
				),
			),
		);
	}
}

class _PiePaginacion extends StatelessWidget {
	final bool cargandoMas;
	final String? errorPaginacion;

	const _PiePaginacion({
		required this.cargandoMas,
		required this.errorPaginacion,
	});

	@override
	Widget build(BuildContext context) {
		if (cargandoMas) {
			return const Padding(
				padding: EdgeInsets.symmetric(vertical: 12),
				child: Center(child: CircularProgressIndicator()),
			);
		}

		final error = errorPaginacion;
		if (error != null) {
			return Column(
				children: [
					Text(error, textAlign: TextAlign.center),
					TextButton.icon(
						onPressed: () {
							context.read<RecepcionesBloc>().add(
								const RecepcionesSiguientePaginaSolicitada(reintento: true),
							);
						},
						icon: const Icon(Icons.refresh),
						label: const Text('Reintentar'),
					),
				],
			);
		}

		return Center(
			child: TextButton(
				onPressed: () {
					context.read<RecepcionesBloc>().add(
						const RecepcionesSiguientePaginaSolicitada(),
					);
				},
				child: const Text('Cargar más'),
			),
		);
	}
}
