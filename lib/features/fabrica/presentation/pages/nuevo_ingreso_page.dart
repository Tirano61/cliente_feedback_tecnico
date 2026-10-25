import 'package:cliente_feedback_tecnico/core/widgets/alta_rapida_cliente_dialogo.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/ingreso_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/selector_modelo_pieza.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ingreso de una placa o celda a fabrica. Con `recepcion` es la pieza que se
/// saco del equipo de esa recepcion; sin recepcion se elige de que cliente o
/// sucursal viene.
class NuevoIngresoPage extends StatefulWidget {
	final PrecargaIngresoRecepcion? recepcion;

	const NuevoIngresoPage({this.recepcion, super.key});

	/// Abre el alta y espera a que se cierre, incluido el detalle del ingreso
	/// que la reemplaza al registrar: quien la abre refresca recien al volver.
	static Future<void> abrir(BuildContext context, {PrecargaIngresoRecepcion? recepcion}) async {
		final cierreDetalle = await Navigator.of(context).push<Future<void>>(
			MaterialPageRoute<Future<void>>(builder: (_) => NuevoIngresoPage(recepcion: recepcion)),
		);
		await cierreDetalle;
	}

	@override
	State<NuevoIngresoPage> createState() => _NuevoIngresoPageState();
}

class _NuevoIngresoPageState extends State<NuevoIngresoPage> {
	final TextEditingController _buscarClienteController = TextEditingController();
	final TextEditingController _nroSerieController = TextEditingController();
	final TextEditingController _indicadorController = TextEditingController();
	final TextEditingController _observacionController = TextEditingController();

	@override
	void initState() {
		super.initState();
		context.read<NuevoIngresoBloc>().add(NuevoIngresoIniciado(recepcion: widget.recepcion));
		// Para el modelo de la pieza (opcional).
		context.read<CatalogoBloc>().add(const CargarCatalogosProductos());
	}

	@override
	void dispose() {
		_buscarClienteController.dispose();
		_nroSerieController.dispose();
		_indicadorController.dispose();
		_observacionController.dispose();
		super.dispose();
	}

	void _buscarCliente() {
		context.read<NuevoIngresoBloc>().add(
			NuevoIngresoBuscarClienteSolicitado(query: _buscarClienteController.text),
		);
	}

	void _cambiar(NuevoIngresoCambiado evento) {
		context.read<NuevoIngresoBloc>().add(evento);
	}

	/// El alta se reemplaza por el detalle. Al reemplazarla, la ruta del alta
	/// se completa enseguida: devuelve el cierre del detalle para que
	/// [NuevoIngresoPage.abrir] espere hasta que el tecnico vuelva.
	void _reemplazarPorDetalle(IngresoDetallePage detalle) {
		final ruta = MaterialPageRoute<void>(builder: (_) => detalle);
		Navigator.of(context).pushReplacement<void, Future<void>>(ruta, result: ruta.popped);
	}

	void _mostrarMensaje(String mensaje) {
		ScaffoldMessenger.of(context)
			..hideCurrentSnackBar()
			..showSnackBar(SnackBar(content: Text(mensaje)));
	}

	@override
	Widget build(BuildContext context) {
		final recepcion = widget.recepcion;
		return Scaffold(
			appBar: AppBar(
				title: Text(
					recepcion == null ? 'Nuevo ingreso' : 'Ingresar pieza · Recepción N° ${recepcion.numero}',
				),
			),
			body: MultiBlocListener(
				listeners: [
					BlocListener<NuevoIngresoBloc, NuevoIngresoState>(
						listenWhen: (_, actual) => actual.errorMensaje != null,
						listener: (context, state) => _mostrarMensaje(state.errorMensaje!),
					),
					// Elegir una pieza instalada completa el numero de serie.
					BlocListener<NuevoIngresoBloc, NuevoIngresoState>(
						listenWhen: (anterior, actual) =>
								anterior.nroSerie != actual.nroSerie && _nroSerieController.text != actual.nroSerie,
						listener: (context, state) {
							_nroSerieController.text = state.nroSerie;
							_nroSerieController.selection = TextSelection.fromPosition(
								TextPosition(offset: state.nroSerie.length),
							);
						},
					),
					BlocListener<NuevoIngresoBloc, NuevoIngresoState>(
						listenWhen: (_, actual) => actual.ingresoCreado != null,
						listener: (context, state) {
							final ingreso = state.ingresoCreado!;
							_mostrarMensaje('Ingreso N° ${ingreso.numero} registrado.');
							_reemplazarPorDetalle(
								IngresoDetallePage(ingresoId: ingreso.id, ingresoInicial: ingreso),
							);
						},
					),
					BlocListener<NuevoIngresoBloc, NuevoIngresoState>(
						listenWhen: (_, actual) => actual.clienteCreado != null,
						listener: (context, state) {
							_mostrarMensaje('Cliente ${state.clienteCreado!.nombre} creado y seleccionado.');
						},
					),
					BlocListener<NuevoIngresoBloc, NuevoIngresoState>(
						listenWhen: (_, actual) => actual.ingresoAbierto != null,
						listener: (context, state) => _avisarIngresoAbierto(state.ingresoAbierto!),
					),
				],
				child: BlocBuilder<NuevoIngresoBloc, NuevoIngresoState>(
					builder: (context, state) {
						return ListView(
							padding: const EdgeInsets.all(16),
							children: [
								_titulo(context, 'Origen'),
								if (state.recepcion != null)
									_origenRecepcion(state.recepcion!)
								else
									_buscadorCliente(state),
								const SizedBox(height: 20),
								_titulo(context, 'Pieza'),
								if (state.piezasInstaladas.isNotEmpty) ...[
									const Text('Piezas que figuran en el indicador:'),
									const SizedBox(height: 6),
									Wrap(
										spacing: 8,
										runSpacing: 8,
										children: [
											for (final pieza in state.piezasInstaladas)
												ActionChip(
													avatar: Icon(iconoTipoUnidad(pieza.tipo), size: 18),
													label: Text('${nombreTipoUnidad(pieza.tipo)} ${pieza.nroSerie}'),
													onPressed: () {
														context.read<NuevoIngresoBloc>().add(
															NuevoIngresoPiezaInstaladaElegida(pieza: pieza),
														);
													},
												),
										],
									),
									const SizedBox(height: 12),
								],
								Wrap(
									spacing: 8,
									children: [
										for (final tipo in NuevoIngresoState.tiposIngresables)
											ChoiceChip(
												avatar: Icon(iconoTipoUnidad(tipo), size: 18),
												label: Text(nombreTipoUnidad(tipo)),
												selected: state.tipo == tipo,
												onSelected: (_) => _cambiar(NuevoIngresoCambiado(tipo: tipo)),
											),
									],
								),
								const SizedBox(height: 12),
								TextField(
									controller: _nroSerieController,
									textCapitalization: TextCapitalization.characters,
									decoration: const InputDecoration(labelText: 'N° de serie de la pieza'),
									onChanged: (valor) => _cambiar(NuevoIngresoCambiado(nroSerie: valor)),
								),
								const SizedBox(height: 12),
								_selectorModelo(state),
								if (state.recepcion == null) ...[
									const SizedBox(height: 12),
									TextField(
										controller: _indicadorController,
										textCapitalization: TextCapitalization.characters,
										decoration: const InputDecoration(
											labelText: 'N° de serie del indicador del que salió (opcional)',
										),
										onChanged: (valor) =>
												_cambiar(NuevoIngresoCambiado(indicadorNroSerie: valor)),
									),
								],
								const SizedBox(height: 12),
								TextField(
									controller: _observacionController,
									minLines: 2,
									maxLines: 5,
									decoration: const InputDecoration(
										labelText: 'Qué observó el técnico',
										hintText: 'Ej: no da tensión en la salida de 5 V',
									),
									onChanged: (valor) => _cambiar(NuevoIngresoCambiado(observacionTecnico: valor)),
								),
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton.icon(
										onPressed: state.guardando
												? null
												: () {
														context.read<NuevoIngresoBloc>().add(const NuevoIngresoGuardado());
													},
										icon: state.guardando ? const ProgresoBoton() : const Icon(Icons.save_outlined),
										label: const Text('Registrar ingreso'),
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

	Widget _origenRecepcion(PrecargaIngresoRecepcion recepcion) {
		return Card(
			margin: EdgeInsets.zero,
			child: ListTile(
				leading: const Icon(Icons.inventory_2_outlined),
				title: Text('Recepción N° ${recepcion.numero} · ${recepcion.clienteNombre}'),
				subtitle: Text('Indicador ${recepcion.indicadorNroSerie}'),
			),
		);
	}

	Widget _buscadorCliente(NuevoIngresoState state) {
		final cliente = state.clienteOrigen;
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				TextField(
					controller: _buscarClienteController,
					textInputAction: TextInputAction.search,
					decoration: InputDecoration(
						labelText: 'Cliente o sucursal de origen (buscar por nombre o CUIT)',
						suffixIcon: state.buscandoClientes
								? const Padding(
										padding: EdgeInsets.all(12),
										child: ProgresoBoton(color: null),
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
							? const ProgresoBoton(color: null)
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
										context.read<NuevoIngresoBloc>().add(
											NuevoIngresoClienteSeleccionado(cliente: encontrado),
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
		final bloc = context.read<NuevoIngresoBloc>();
		return showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return BlocConsumer<NuevoIngresoBloc, NuevoIngresoState>(
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
									NuevoIngresoClienteRapidoSolicitado(
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

	Widget _selectorModelo(NuevoIngresoState state) {
		return SelectorModeloPieza(
			palabra: state.palabraModelo,
			productoId: state.productoId,
			onChanged: (valor) {
				_cambiar(NuevoIngresoCambiado(productoId: valor, limpiarProducto: valor == null));
			},
		);
	}

	Future<void> _avisarIngresoAbierto(IngresoAbiertoExistente existente) async {
		final verExistente = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('La pieza ya está en fábrica'),
					content: Text(existente.mensaje),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Cerrar'),
						),
						ElevatedButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							child: Text(
								existente.numero == null ? 'Ver ingreso' : 'Ver ingreso N° ${existente.numero}',
							),
						),
					],
				);
			},
		);

		if (verExistente == true && mounted) {
			_reemplazarPorDetalle(IngresoDetallePage(ingresoId: existente.ingresoId));
		}
	}
}
