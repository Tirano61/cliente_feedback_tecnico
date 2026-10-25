import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingresos_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/ingreso_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/nuevo_ingreso_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_ingreso_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pestaña "Piezas ingresadas": ingresos de placas y celdas con buscador y
/// filtros.
class IngresosTab extends StatefulWidget {
	const IngresosTab({super.key});

	@override
	State<IngresosTab> createState() => _IngresosTabState();
}

class _IngresosTabState extends State<IngresosTab> {
	final TextEditingController _busquedaController = TextEditingController();

	/// Ultima busqueda que el bloc le mostro a esta pantalla.
	String? _ultimaBusquedaDelBloc;

	@override
	void initState() {
		super.initState();
		context.read<IngresosBloc>().add(const IngresosSolicitados());
	}

	@override
	void dispose() {
		_busquedaController.dispose();
		super.dispose();
	}

	Future<void> _abrirDetalle(Ingreso ingreso) async {
		final bloc = context.read<IngresosBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(builder: (_) => IngresoDetallePage(ingresoId: ingreso.id)),
		);
		bloc.add(const IngresosRefrescados());
	}

	Future<void> _abrirNuevoIngreso() async {
		final bloc = context.read<IngresosBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(builder: (_) => const NuevoIngresoPage()),
		);
		bloc.add(const IngresosRefrescados());
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			floatingActionButton: FloatingActionButton.extended(
				onPressed: _abrirNuevoIngreso,
				icon: const Icon(Icons.add),
				label: const Text('Nuevo ingreso'),
			),
			body: BlocBuilder<IngresosBloc, IngresosState>(
				builder: _construirCuerpo,
			),
		);
	}

	Widget _construirCuerpo(BuildContext context, IngresosState state) {
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
							labelText: 'Buscar por número, serie, cliente o indicador',
						),
						onChanged: (valor) {
							context.read<IngresosBloc>().add(IngresosBusquedaCambiada(texto: valor));
						},
					),
				),
				const SizedBox(height: 10),
				_FiltroTipo(filtroTipo: state.filtroTipo),
				const SizedBox(height: 6),
				_FiltroEstado(estados: state.estadosFiltrables, filtroEstado: state.filtroEstado),
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

	Widget _construirListado(BuildContext context, IngresosState state) {
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
									context.read<IngresosBloc>().add(const IngresosSolicitados());
								},
								icon: const Icon(Icons.refresh),
								label: const Text('Reintentar'),
							),
						],
					),
				),
			);
		}

		if (state.ingresos.isEmpty) {
			return RefreshIndicator(
				onRefresh: () async {
					context.read<IngresosBloc>().add(const IngresosRefrescados());
				},
				child: ListView(
					children: [
						const SizedBox(height: 120),
						Center(
							child: Text(
								state.actualizando
										? 'Buscando piezas...'
										: state.hayFiltrosActivos
												? 'No hay piezas para los filtros aplicados.'
												: 'No hay piezas ingresadas.',
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
							'Se muestran ${state.ingresos.length} de ${state.total} piezas',
							style: Theme.of(context).textTheme.bodySmall,
						),
					),
				),
				Expanded(
					child: RefreshIndicator(
						onRefresh: () async {
							context.read<IngresosBloc>().add(const IngresosRefrescados());
						},
						child: NotificationListener<ScrollNotification>(
							// Cerca del final se pide la pagina siguiente; el bloc descarta
							// los pedidos repetidos mientras carga.
							onNotification: (notificacion) {
								if (notificacion.metrics.extentAfter < 400) {
									context.read<IngresosBloc>().add(const IngresosSiguientePaginaSolicitada());
								}
								return false;
							},
							child: ListView.separated(
								// Abajo queda lugar para que el boton flotante no tape la ultima.
								padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
								itemCount: state.ingresos.length + (mostrarPie ? 1 : 0),
								separatorBuilder: (_, _) => const SizedBox(height: 10),
								itemBuilder: (context, index) {
									if (index == state.ingresos.length) {
										return _PiePaginacion(
											cargandoMas: state.cargandoMas,
											errorPaginacion: state.errorPaginacion,
										);
									}

									final ingreso = state.ingresos[index];
									return _TarjetaIngreso(
										ingreso: ingreso,
										onTap: () => _abrirDetalle(ingreso),
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

class _FiltroTipo extends StatelessWidget {
	final TipoUnidad? filtroTipo;

	const _FiltroTipo({required this.filtroTipo});

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
							label: const Text('Placas y celdas'),
							selected: filtroTipo == null,
							onSelected: (_) {
								context.read<IngresosBloc>().add(const IngresosFiltroTipoCambiado(tipo: null));
							},
						),
					),
					for (final tipo in IngresosState.tiposFiltrables)
						Padding(
							padding: const EdgeInsets.only(right: 8),
							child: ChoiceChip(
								avatar: Icon(iconoTipoUnidad(tipo), size: 18),
								label: Text(nombreTipoUnidad(tipo)),
								selected: filtroTipo == tipo,
								onSelected: (_) {
									context.read<IngresosBloc>().add(IngresosFiltroTipoCambiado(tipo: tipo));
								},
							),
						),
				],
			),
		);
	}
}

class _FiltroEstado extends StatelessWidget {
	final List<EstadoIngreso> estados;
	final EstadoIngreso? filtroEstado;

	const _FiltroEstado({required this.estados, required this.filtroEstado});

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
							label: const Text('Todos los estados'),
							selected: filtroEstado == null,
							onSelected: (_) {
								context.read<IngresosBloc>().add(const IngresosFiltroEstadoCambiado(estado: null));
							},
						),
					),
					for (final estado in estados)
						Padding(
							padding: const EdgeInsets.only(right: 8),
							child: ChoiceChip(
								label: Text(nombreEstadoIngreso(estado)),
								selected: filtroEstado == estado,
								onSelected: (_) {
									context.read<IngresosBloc>().add(IngresosFiltroEstadoCambiado(estado: estado));
								},
							),
						),
				],
			),
		);
	}
}

class _TarjetaIngreso extends StatelessWidget {
	final Ingreso ingreso;
	final VoidCallback onTap;

	const _TarjetaIngreso({required this.ingreso, required this.onTap});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final unidad = ingreso.unidad;
		final modelo = unidad.producto?.nombre;
		final origen = [
			if ((ingreso.clienteOrigen?.nombre ?? '').trim().isNotEmpty) ingreso.clienteOrigen!.nombre.trim(),
			if (ingreso.indicadorOrigen != null) 'Indicador ${ingreso.indicadorOrigen!.nroSerie}',
		];

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
									Icon(iconoTipoUnidad(unidad.tipo), size: 20),
									const SizedBox(width: 6),
									Expanded(
										child: Text(
											'N° ${ingreso.numero} · ${nombreTipoUnidad(unidad.tipo)} ${unidad.nroSerie}',
											style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
										),
									),
									const SizedBox(width: 8),
									EstadoIngresoBadge(estado: ingreso.estado),
								],
							),
							if ((modelo ?? '').isNotEmpty) ...[
								const SizedBox(height: 6),
								Text(modelo!),
							],
							if (origen.isNotEmpty) ...[
								const SizedBox(height: 4),
								Text(origen.join(' · ')),
							],
							const SizedBox(height: 4),
							Text(
								'Ingresó ${formatearFechaFabrica(ingreso.fechaIngreso)}',
								style: textTheme.bodySmall,
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
							context.read<IngresosBloc>().add(
								const IngresosSiguientePaginaSolicitada(reintento: true),
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
					context.read<IngresosBloc>().add(const IngresosSiguientePaginaSolicitada());
				},
				child: const Text('Cargar más'),
			),
		);
	}
}
