import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/selector_modelo_pieza.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Poner placa/celda" en el indicador de una recepcion: la pieza que se pone
/// (nueva o reacondicionada disponible) y la que sale.
class AsignarUnidadPage extends StatefulWidget {
	final PrecargaAsignacionRecepcion precarga;

	const AsignarUnidadPage({required this.precarga, super.key});

	@override
	State<AsignarUnidadPage> createState() => _AsignarUnidadPageState();
}

class _AsignarUnidadPageState extends State<AsignarUnidadPage> {
	final TextEditingController _nroSerieController = TextEditingController();
	final TextEditingController _retiradaController = TextEditingController();
	final TextEditingController _observacionController = TextEditingController();

	@override
	void initState() {
		super.initState();
		context.read<AsignacionUnidadBloc>().add(AsignacionIniciada(precarga: widget.precarga));
		// Para el modelo de la pieza (opcional).
		context.read<CatalogoBloc>().add(const CargarCatalogosProductos());
	}

	@override
	void dispose() {
		_nroSerieController.dispose();
		_retiradaController.dispose();
		_observacionController.dispose();
		super.dispose();
	}

	void _cambiar(AsignacionCambiada evento) {
		context.read<AsignacionUnidadBloc>().add(evento);
	}

	/// Elegir de las listas completa el campo; lo que se tipea no se pisa.
	static void _sincronizar(TextEditingController controller, String valor) {
		if (controller.text == valor) {
			return;
		}
		controller.text = valor;
		controller.selection = TextSelection.fromPosition(TextPosition(offset: valor.length));
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text('Poner placa/celda · Recepción N° ${widget.precarga.numero}'),
			),
			body: MultiBlocListener(
				listeners: [
					BlocListener<AsignacionUnidadBloc, AsignacionUnidadState>(
						listenWhen: (_, actual) => actual.errorMensaje != null,
						listener: (context, state) {
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(SnackBar(content: Text(state.errorMensaje!)));
						},
					),
					BlocListener<AsignacionUnidadBloc, AsignacionUnidadState>(
						listenWhen: (anterior, actual) => anterior.nroSerie != actual.nroSerie,
						listener: (context, state) => _sincronizar(_nroSerieController, state.nroSerie),
					),
					BlocListener<AsignacionUnidadBloc, AsignacionUnidadState>(
						listenWhen: (anterior, actual) => anterior.retiradaNroSerie != actual.retiradaNroSerie,
						listener: (context, state) =>
								_sincronizar(_retiradaController, state.retiradaNroSerie),
					),
				],
				child: BlocBuilder<AsignacionUnidadBloc, AsignacionUnidadState>(
					builder: (context, state) {
						// Mientras no arranca el formulario de esta recepcion no se muestra el anterior.
						if (state.precarga != widget.precarga) {
							return const Center(child: CircularProgressIndicator());
						}
						if (state.asignada) {
							return _Resultado(state: state);
						}
						return _formulario(context, state);
					},
				),
			),
		);
	}

	Widget _formulario(BuildContext context, AsignacionUnidadState state) {
		final precarga = widget.precarga;
		final bloqueado = state.guardando;
		return ListView(
			padding: const EdgeInsets.all(16),
			children: [
				Card(
					margin: EdgeInsets.zero,
					child: ListTile(
						leading: Icon(iconoTipoUnidad(TipoUnidad.indicador)),
						title: Text('Indicador ${precarga.indicadorNroSerie}'),
						subtitle: Text('Recepción N° ${precarga.numero} · ${precarga.clienteNombre}'),
					),
				),
				const SizedBox(height: 20),
				_titulo(context, 'Pieza que se pone'),
				Wrap(
					spacing: 8,
					children: [
						for (final tipo in AsignacionUnidadState.tiposAsignables)
							ChoiceChip(
								avatar: Icon(iconoTipoUnidad(tipo), size: 18),
								label: Text(nombreTipoUnidad(tipo)),
								selected: state.tipo == tipo,
								onSelected: bloqueado ? null : (_) => _cambiar(AsignacionCambiada(tipo: tipo)),
							),
					],
				),
				if (state.tipo != null) ...[
					const SizedBox(height: 12),
					_Reacondicionadas(state: state),
				],
				const SizedBox(height: 12),
				TextField(
					controller: _nroSerieController,
					enabled: !bloqueado,
					textCapitalization: TextCapitalization.characters,
					decoration: const InputDecoration(
						labelText: 'N° de serie de la pieza que se pone',
						helperText: 'Si es nueva, queda registrada con este número.',
					),
					onChanged: (valor) => _cambiar(AsignacionCambiada(nroSerie: valor)),
				),
				const SizedBox(height: 12),
				SelectorModeloPieza(
					palabra: state.palabraModelo,
					productoId: state.productoId,
					habilitado: !bloqueado,
					onChanged: (valor) {
						_cambiar(AsignacionCambiada(productoId: valor, limpiarProducto: valor == null));
					},
				),
				if (state.tipo != null) ...[
					const SizedBox(height: 20),
					_titulo(context, 'Pieza que se saca'),
					if (state.piezasParaRetirar.isNotEmpty) ...[
						const Text('Piezas que figuran en el indicador:'),
						const SizedBox(height: 6),
						Wrap(
							spacing: 8,
							runSpacing: 8,
							children: [
								for (final pieza in state.piezasParaRetirar)
									FilterChip(
										avatar: Icon(iconoTipoUnidad(pieza.tipo), size: 18),
										label: Text(_etiquetaPieza(pieza)),
										selected: normalizarSerie(state.retiradaNroSerie) ==
												normalizarSerie(pieza.nroSerie),
										onSelected: bloqueado
												? null
												: (_) {
														context.read<AsignacionUnidadBloc>().add(
															AsignacionRetiradaElegida(pieza: pieza),
														);
													},
									),
							],
						),
						const SizedBox(height: 12),
					],
					TextField(
						controller: _retiradaController,
						enabled: !bloqueado,
						textCapitalization: TextCapitalization.characters,
						decoration: const InputDecoration(
							labelText: 'N° de serie de la que se saca (opcional)',
						),
						onChanged: (valor) => _cambiar(AsignacionCambiada(retiradaNroSerie: valor)),
					),
					if (state.avisoRetirada != null) ...[
						const SizedBox(height: 6),
						Text(
							state.avisoRetirada!,
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: Theme.of(context).colorScheme.onSurfaceVariant,
									),
						),
					],
				],
				const SizedBox(height: 12),
				TextField(
					controller: _observacionController,
					enabled: !bloqueado,
					minLines: 1,
					maxLines: 4,
					decoration: const InputDecoration(
						labelText: 'Observación (opcional)',
						hintText: 'Ej: cambio de placa por falla de fuente',
					),
					onChanged: (valor) => _cambiar(AsignacionCambiada(observacion: valor)),
				),
				ErrorAccionDetalle(mensaje: state.errorAsignacion),
				const SizedBox(height: 24),
				SizedBox(
					width: double.infinity,
					child: ElevatedButton.icon(
						onPressed: bloqueado
								? null
								: () => context.read<AsignacionUnidadBloc>().add(const AsignacionGuardada()),
						icon: bloqueado ? const ProgresoBoton() : const Icon(Icons.swap_horiz),
						label: Text(state.etiquetaGuardar),
					),
				),
			],
		);
	}

	Widget _titulo(BuildContext context, String texto) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Text(
				texto,
				style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
			),
		);
	}
}

String _etiquetaPieza(Unidad pieza) {
	final modelo = pieza.producto?.nombre;
	return (modelo ?? '').trim().isEmpty ? pieza.nroSerie : '${pieza.nroSerie} · ${modelo!.trim()}';
}

/// Reacondicionadas disponibles del tipo elegido: tocar una completa el
/// numero de serie y el modelo.
class _Reacondicionadas extends StatelessWidget {
	final AsignacionUnidadState state;

	const _Reacondicionadas({required this.state});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final colorScheme = Theme.of(context).colorScheme;
		final elegida = state.reacondicionadaElegida;
		final error = state.errorReacondicionadas;
		final aviso = state.avisoReacondicionadas;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const Text('Reacondicionadas disponibles:'),
				const SizedBox(height: 6),
				if (state.cargandoReacondicionadas)
					const LinearProgressIndicator()
				else if (error != null)
					Row(
						children: [
							Expanded(
								child: Text(error, style: textTheme.bodySmall?.copyWith(color: colorScheme.error)),
							),
							TextButton.icon(
								onPressed: () {
									context.read<AsignacionUnidadBloc>().add(
										const AsignacionReacondicionadasSolicitadas(),
									);
								},
								icon: const Icon(Icons.refresh),
								label: const Text('Reintentar'),
							),
						],
					)
				else if (state.reacondicionadas.isNotEmpty)
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							for (final unidad in state.reacondicionadas)
								ChoiceChip(
									avatar: const Icon(Icons.recycling, size: 18),
									label: Text(_etiquetaPieza(unidad)),
									selected: elegida?.id == unidad.id,
									onSelected: state.guardando
											? null
											: (_) {
													context.read<AsignacionUnidadBloc>().add(
														AsignacionReacondicionadaElegida(unidad: unidad),
													);
												},
								),
						],
					),
				if (aviso != null) ...[
					const SizedBox(height: 6),
					Text(aviso, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
				],
			],
		);
	}
}

class _Resultado extends StatelessWidget {
	final AsignacionUnidadState state;

	const _Resultado({required this.state});

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final retiradas = state.textosRetiradas;
		return ListView(
			padding: const EdgeInsets.all(16),
			children: [
				SeccionDetalle(
					titulo: 'Pieza puesta',
					children: [
						ListTile(
							contentPadding: EdgeInsets.zero,
							leading: Icon(Icons.check_circle, color: colorScheme.primary),
							title: Text(state.textoInstalada ?? ''),
						),
					],
				),
				const SizedBox(height: 12),
				SeccionDetalle(
					titulo: 'Pieza que salió',
					children: [
						if (retiradas.isEmpty) const Text('No salió ninguna pieza del indicador.'),
						for (final retirada in retiradas)
							ListTile(
								dense: true,
								contentPadding: EdgeInsets.zero,
								leading: const Icon(Icons.outbox_outlined),
								title: Text(retirada),
								subtitle: const Text('Queda retirada hasta que se le dé ingreso a fábrica.'),
							),
					],
				),
				const SizedBox(height: 24),
				SizedBox(
					width: double.infinity,
					child: ElevatedButton.icon(
						onPressed: () => Navigator.of(context).pop(),
						icon: const Icon(Icons.arrow_back),
						label: const Text('Volver a la recepción'),
					),
				),
			],
		);
	}
}
