import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/piezas_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/pieza_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_unidad_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pestaña "Piezas": busqueda por numero de serie y placas reacondicionadas
/// disponibles.
class PiezasTab extends StatefulWidget {
	const PiezasTab({super.key});

	@override
	State<PiezasTab> createState() => _PiezasTabState();
}

class _PiezasTabState extends State<PiezasTab> {
	final TextEditingController _busquedaController = TextEditingController();

	/// Ultima busqueda que el bloc le mostro a esta pantalla.
	String? _ultimaBusquedaDelBloc;

	@override
	void initState() {
		super.initState();
		context.read<PiezasBloc>().add(const PiezasSolicitadas());
	}

	@override
	void dispose() {
		_busquedaController.dispose();
		super.dispose();
	}

	Future<void> _abrirDetalle(Unidad unidad) async {
		final bloc = context.read<PiezasBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(
				builder: (_) => PiezaDetallePage(unidadId: unidad.id, unidadInicial: unidad),
			),
		);
		bloc.add(const PiezasRefrescadas());
	}

	@override
	Widget build(BuildContext context) {
		return BlocBuilder<PiezasBloc, PiezasState>(builder: _construirCuerpo);
	}

	Widget _construirCuerpo(BuildContext context, PiezasState state) {
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
						textCapitalization: TextCapitalization.characters,
						decoration: const InputDecoration(
							prefixIcon: Icon(Icons.search),
							labelText: 'Buscar por número de serie',
						),
						onChanged: (valor) {
							context.read<PiezasBloc>().add(PiezasBusquedaCambiada(texto: valor));
						},
					),
				),
				const SizedBox(height: 10),
				Padding(
					padding: const EdgeInsets.symmetric(horizontal: 16),
					child: Align(
						alignment: Alignment.centerLeft,
						child: FilterChip(
							avatar: const Icon(Icons.recycling, size: 18),
							label: const Text('Placas reacondicionadas disponibles'),
							selected: state.soloReacondicionadas,
							onSelected: (activas) {
								context.read<PiezasBloc>().add(PiezasReacondicionadasAlternadas(activas: activas));
							},
						),
					),
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

	Widget _construirListado(BuildContext context, PiezasState state) {
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
								onPressed: () => context.read<PiezasBloc>().add(const PiezasSolicitadas()),
								icon: const Icon(Icons.refresh),
								label: const Text('Reintentar'),
							),
						],
					),
				),
			);
		}

		if (state.piezas.isEmpty) {
			return ListView(
				padding: const EdgeInsets.symmetric(horizontal: 24),
				children: [
					const SizedBox(height: 120),
					Text(state.textoVacio, textAlign: TextAlign.center),
				],
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
							'Se muestran ${state.piezas.length} de ${state.total} piezas',
							style: Theme.of(context).textTheme.bodySmall,
						),
					),
				),
				Expanded(
					child: RefreshIndicator(
						onRefresh: () async {
							context.read<PiezasBloc>().add(const PiezasRefrescadas());
						},
						child: NotificationListener<ScrollNotification>(
							// Cerca del final se pide la pagina siguiente; el bloc descarta
							// los pedidos repetidos mientras carga.
							onNotification: (notificacion) {
								if (notificacion.metrics.extentAfter < 400) {
									context.read<PiezasBloc>().add(const PiezasSiguientePaginaSolicitada());
								}
								return false;
							},
							child: ListView.separated(
								padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
								itemCount: state.piezas.length + (mostrarPie ? 1 : 0),
								separatorBuilder: (_, _) => const SizedBox(height: 10),
								itemBuilder: (context, index) {
									if (index == state.piezas.length) {
										return _PiePaginacion(
											cargandoMas: state.cargandoMas,
											errorPaginacion: state.errorPaginacion,
										);
									}

									final unidad = state.piezas[index];
									return _TarjetaPieza(unidad: unidad, onTap: () => _abrirDetalle(unidad));
								},
							),
						),
					),
				),
			],
		);
	}
}

class _TarjetaPieza extends StatelessWidget {
	final Unidad unidad;
	final VoidCallback onTap;

	const _TarjetaPieza({required this.unidad, required this.onTap});

	@override
	Widget build(BuildContext context) {
		final modelo = unidad.producto?.nombre;
		return Card(
			child: ListTile(
				onTap: onTap,
				leading: Icon(iconoTipoUnidad(unidad.tipo)),
				title: Text(
					'${nombreTipoUnidad(unidad.tipo)} ${unidad.nroSerie}',
					style: const TextStyle(fontWeight: FontWeight.w700),
				),
				subtitle: (modelo ?? '').trim().isEmpty ? null : Text(modelo!.trim()),
				trailing: EstadoUnidadBadge(estado: unidad.estado),
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
							context.read<PiezasBloc>().add(const PiezasSiguientePaginaSolicitada(reintento: true));
						},
						icon: const Icon(Icons.refresh),
						label: const Text('Reintentar'),
					),
				],
			);
		}

		return Center(
			child: TextButton(
				onPressed: () => context.read<PiezasBloc>().add(const PiezasSiguientePaginaSolicitada()),
				child: const Text('Cargar más'),
			),
		);
	}
}
