import 'package:cliente_feedback_tecnico/core/widgets/alta_rapida_cliente_dialogo.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/recepcion_detalle_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NuevaRecepcionPage extends StatefulWidget {
	const NuevaRecepcionPage({super.key});

	@override
	State<NuevaRecepcionPage> createState() => _NuevaRecepcionPageState();
}

class _NuevaRecepcionPageState extends State<NuevaRecepcionPage> {
	final TextEditingController _buscarClienteController = TextEditingController();
	final TextEditingController _nroSerieController = TextEditingController();
	final TextEditingController _queLlegoController = TextEditingController();
	final TextEditingController _sintomaController = TextEditingController();
	final TextEditingController _observacionesController = TextEditingController();

	@override
	void initState() {
		super.initState();
		context.read<NuevaRecepcionBloc>().add(const NuevaRecepcionIniciada());
		// Para el modelo del indicador (opcional).
		context.read<CatalogoBloc>().add(const CargarCatalogosProductos());
	}

	@override
	void dispose() {
		_buscarClienteController.dispose();
		_nroSerieController.dispose();
		_queLlegoController.dispose();
		_sintomaController.dispose();
		_observacionesController.dispose();
		super.dispose();
	}

	void _buscarCliente() {
		context.read<NuevaRecepcionBloc>().add(
			NuevaRecepcionBuscarClienteSolicitado(query: _buscarClienteController.text),
		);
	}

	void _cambiar(NuevaRecepcionCambiada evento) {
		context.read<NuevaRecepcionBloc>().add(evento);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Nueva recepción')),
			body: MultiBlocListener(
				listeners: [
					BlocListener<NuevaRecepcionBloc, NuevaRecepcionState>(
						listenWhen: (_, actual) => actual.errorMensaje != null,
						listener: (context, state) {
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(SnackBar(content: Text(state.errorMensaje!)));
						},
					),
					BlocListener<NuevaRecepcionBloc, NuevaRecepcionState>(
						listenWhen: (_, actual) => actual.recepcionCreada != null,
						listener: (context, state) {
							final recepcion = state.recepcionCreada!;
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(
									SnackBar(content: Text('Recepción N° ${recepcion.numero} registrada.')),
								);
							Navigator.of(context).pushReplacement(
								MaterialPageRoute<void>(
									builder: (_) => RecepcionDetallePage(
										recepcionId: recepcion.id,
										recepcionInicial: recepcion,
									),
								),
							);
						},
					),
					BlocListener<NuevaRecepcionBloc, NuevaRecepcionState>(
						listenWhen: (_, actual) => actual.clienteCreado != null,
						listener: (context, state) {
							ScaffoldMessenger.of(context)
								..hideCurrentSnackBar()
								..showSnackBar(
									SnackBar(content: Text('Cliente ${state.clienteCreado!.nombre} creado y seleccionado.')),
								);
						},
					),
					BlocListener<NuevaRecepcionBloc, NuevaRecepcionState>(
						listenWhen: (_, actual) => actual.recepcionAbierta != null,
						listener: (context, state) => _avisarRecepcionAbierta(state.recepcionAbierta!),
					),
				],
				child: BlocBuilder<NuevaRecepcionBloc, NuevaRecepcionState>(
					builder: (context, state) {
						return ListView(
							padding: const EdgeInsets.all(16),
							children: [
								_titulo(context, 'Cliente'),
								_buscadorCliente(state),
								const SizedBox(height: 20),
								_titulo(context, 'Equipo'),
								TextField(
									controller: _nroSerieController,
									textCapitalization: TextCapitalization.characters,
									decoration: const InputDecoration(
										labelText: 'N° de serie del indicador',
									),
									onChanged: (valor) => _cambiar(NuevaRecepcionCambiada(indicadorNroSerie: valor)),
								),
								const SizedBox(height: 12),
								_selectorModelo(state),
								const SizedBox(height: 12),
								TextField(
									controller: _queLlegoController,
									minLines: 1,
									maxLines: 3,
									decoration: const InputDecoration(
										labelText: 'Qué llegó',
										hintText: 'Ej: indicador completo con cable de celdas',
									),
									onChanged: (valor) => _cambiar(NuevaRecepcionCambiada(queLlego: valor)),
								),
								const SizedBox(height: 12),
								TextField(
									controller: _sintomaController,
									minLines: 2,
									maxLines: 5,
									decoration: const InputDecoration(labelText: 'Qué reporta el cliente'),
									onChanged: (valor) => _cambiar(NuevaRecepcionCambiada(sintomaReportado: valor)),
								),
								const SizedBox(height: 12),
								TextField(
									controller: _observacionesController,
									minLines: 1,
									maxLines: 4,
									decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
									onChanged: (valor) => _cambiar(NuevaRecepcionCambiada(observaciones: valor)),
								),
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton.icon(
										onPressed: state.guardando
												? null
												: () {
														context.read<NuevaRecepcionBloc>().add(const NuevaRecepcionGuardada());
													},
										icon: state.guardando
												? const SizedBox(
														height: 16,
														width: 16,
														child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
													)
												: const Icon(Icons.save_outlined),
										label: const Text('Registrar recepción'),
									),
								),
							],
						);
					},
				),
			),
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

	Widget _buscadorCliente(NuevaRecepcionState state) {
		final cliente = state.clienteSeleccionado;
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				TextField(
					controller: _buscarClienteController,
					textInputAction: TextInputAction.search,
					decoration: InputDecoration(
						labelText: 'Cliente o sucursal (buscar por nombre o CUIT)',
						suffixIcon: state.buscandoClientes
								? const Padding(
										padding: EdgeInsets.all(12),
										child: SizedBox(
											height: 16,
											width: 16,
											child: CircularProgressIndicator(strokeWidth: 2),
										),
									)
								: IconButton(
										onPressed: _buscarCliente,
										icon: const Icon(Icons.search),
										tooltip: 'Buscar',
									),
					),
					onSubmitted: (_) => _buscarCliente(),
				),
				const SizedBox(height: 8),
				OutlinedButton.icon(
					onPressed: state.creandoCliente ? null : _mostrarAltaRapidaCliente,
					icon: state.creandoCliente
							? const SizedBox(
									height: 14,
									width: 14,
									child: CircularProgressIndicator(strokeWidth: 2),
								)
							: const Icon(Icons.person_add_alt_1),
					label: const Text('Alta rapida cliente'),
				),
				if (state.clientesEncontrados.isNotEmpty) ...[
					const SizedBox(height: 8),
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							for (final encontrado in state.clientesEncontrados)
								ChoiceChip(
									label: Text(
										(encontrado.cuit ?? '').isEmpty
												? encontrado.nombre
												: '${encontrado.nombre} (${encontrado.cuit})',
									),
									selected: cliente?.id == encontrado.id,
									onSelected: (_) {
										context.read<NuevaRecepcionBloc>().add(
											NuevaRecepcionClienteSeleccionado(cliente: encontrado),
										);
									},
								),
						],
					),
				],
				if (cliente != null) ...[
					const SizedBox(height: 8),
					Card(
						margin: EdgeInsets.zero,
						child: ListTile(
							leading: const Icon(Icons.person_outline),
							title: Text(cliente.nombre),
							subtitle: Text(
								[
									if ((cliente.cuit ?? '').isNotEmpty) 'CUIT ${cliente.cuit}',
									if ((cliente.localidad ?? '').isNotEmpty) cliente.localidad!,
								].join(' · '),
							),
						),
					),
				],
			],
		);
	}

	/// Se cierra solo cuando el cliente quedo creado; si el backend lo rechaza,
	/// queda abierto con lo cargado y el mensaje.
	Future<void> _mostrarAltaRapidaCliente() {
		final bloc = context.read<NuevaRecepcionBloc>();
		return showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return BlocConsumer<NuevaRecepcionBloc, NuevaRecepcionState>(
					bloc: bloc,
					listenWhen: (_, actual) => actual.clienteCreado != null,
					listener: (_, _) => Navigator.of(dialogContext).pop(),
					builder: (_, state) {
						return AltaRapidaClienteDialogo(
							creando: state.creandoCliente,
							mensaje: state.errorAltaCliente,
							esError: true,
							onCrear: (datos) {
								bloc.add(
									NuevaRecepcionClienteRapidoSolicitado(
										cuit: datos.cuit,
										nombre: datos.nombre,
										contacto: datos.contacto,
										telefono: datos.telefono,
										localidad: datos.localidad,
									),
								);
							},
						);
					},
				);
			},
		);
	}

	Widget _selectorModelo(NuevaRecepcionState state) {
		return BlocBuilder<CatalogoBloc, CatalogoState>(
			builder: (context, catalogoState) {
				final indicadores =
						catalogoState is CatalogoLoaded ? catalogoState.indicadoresActivos : const <Producto>[];
				final cargando = catalogoState is CatalogoLoaded && catalogoState.cargandoProductos;
				final seleccionado = indicadores.any((p) => p.id == state.indicadorProductoId)
						? state.indicadorProductoId
						: null;

				return DropdownButtonFormField<String?>(
					// Al llegar el catalogo se reconstruye con el valor vigente.
					key: ValueKey('modelo-${indicadores.length}'),
					initialValue: seleccionado,
					isExpanded: true,
					decoration: InputDecoration(
						labelText: cargando ? 'Modelo (cargando...)' : 'Modelo (opcional)',
					),
					items: [
						const DropdownMenuItem<String?>(value: null, child: Text('Sin especificar')),
						for (final producto in indicadores)
							DropdownMenuItem<String?>(
								value: producto.id,
								child: Text(producto.nombre, overflow: TextOverflow.ellipsis),
							),
					],
					onChanged: (valor) {
						_cambiar(
							NuevaRecepcionCambiada(
								indicadorProductoId: valor,
								limpiarProducto: valor == null,
							),
						);
					},
				);
			},
		);
	}

	Future<void> _avisarRecepcionAbierta(RecepcionAbiertaExistente existente) async {
		final verExistente = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('El equipo ya está en fábrica'),
					content: Text(existente.mensaje),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Cerrar'),
						),
						ElevatedButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							child: Text(
								existente.numero == null
										? 'Ver recepción'
										: 'Ver recepción N° ${existente.numero}',
							),
						),
					],
				);
			},
		);

		if (verExistente == true && mounted) {
			Navigator.of(context).pushReplacement(
				MaterialPageRoute<void>(
					builder: (_) => RecepcionDetallePage(recepcionId: existente.recepcionId),
				),
			);
		}
	}
}
