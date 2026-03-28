import 'dart:convert';

import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FormularioServicio extends StatefulWidget {
	const FormularioServicio({super.key});

	@override
	State<FormularioServicio> createState() => _FormularioServicioState();
}

class _FormularioServicioState extends State<FormularioServicio> {
	final TextEditingController _buscarClienteController = TextEditingController();
	final TextEditingController _lugarDetalleController = TextEditingController();
	final TextEditingController _equipoNroSerieController = TextEditingController();
	final TextEditingController _equipoUbicacionController = TextEditingController();
	final TextEditingController _equipoAnioController = TextEditingController();
	final TextEditingController _kmController = TextEditingController();
	final TextEditingController _buscarRepuestoController = TextEditingController();
	final TextEditingController _ivaController = TextEditingController(text: '21');
	final TextEditingController _descuentoController = TextEditingController();
	final TextEditingController _sintomaController = TextEditingController();
	final TextEditingController _diagnosticoDetalleController = TextEditingController();
	final TextEditingController _observacionesController = TextEditingController();

	String? _modeloIndicadorSeleccionadoId;

	final Set<String> _categoriasFallaSeleccionadasIds = <String>{};
	final Map<String, _ProductoFallaSeleccionado> _productosFallaSeleccionados =
			<String, _ProductoFallaSeleccionado>{};

	@override
	void initState() {
		super.initState();
		final catalogoState = context.read<CatalogoBloc>().state;
		if (catalogoState is! CatalogoLoaded) {
			context.read<CatalogoBloc>().add(const CargarCatalogos());
		}
		context.read<ServicioBloc>().add(const ServicioFormularioReiniciado());
	}

	@override
	void dispose() {
		_buscarClienteController.dispose();
		_lugarDetalleController.dispose();
		_equipoNroSerieController.dispose();
		_equipoUbicacionController.dispose();
		_equipoAnioController.dispose();
		_kmController.dispose();
		_buscarRepuestoController.dispose();
		_ivaController.dispose();
		_descuentoController.dispose();
		_sintomaController.dispose();
		_diagnosticoDetalleController.dispose();
		_observacionesController.dispose();
		super.dispose();
	}

	void _limpiarFormularioVisual() {
		_buscarClienteController.clear();
		_lugarDetalleController.clear();
		_equipoNroSerieController.clear();
		_equipoUbicacionController.clear();
		_equipoAnioController.clear();
		_modeloIndicadorSeleccionadoId = null;
		_categoriasFallaSeleccionadasIds.clear();
		_productosFallaSeleccionados.clear();
		_kmController.clear();
		_buscarRepuestoController.clear();
		_ivaController.text = '21';
		_descuentoController.clear();
		_sintomaController.clear();
		_diagnosticoDetalleController.clear();
		_observacionesController.clear();
		context.read<ServicioBloc>().add(const ServicioFormularioReiniciado());
	}

	Future<void> _mostrarDialogoAltaRapidaCliente(BuildContext context) async {
		final payloadController = TextEditingController(
			text: const JsonEncoder.withIndent('  ').convert({
				'nombre': '',
			}),
		);

		await showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Alta rapida de cliente'),
					content: SizedBox(
						width: 520,
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Pegá el JSON del endpoint POST /clientes segun el backend.',
								),
								const SizedBox(height: 8),
								TextField(
									controller: payloadController,
									maxLines: 9,
									decoration: const InputDecoration(
										border: OutlineInputBorder(),
										hintText: '{"nombre":"Cliente"}',
									),
								),
							],
						),
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(),
							child: const Text('Cancelar'),
						),
						ElevatedButton(
							onPressed: () {
								context.read<ServicioBloc>().add(
										ServicioCrearClienteRapidoSolicitado(
											payloadJson: payloadController.text,
										),
								);
								Navigator.of(dialogContext).pop();
							},
							child: const Text('Crear cliente'),
						),
					],
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<ServicioBloc, ServicioState>(
			listenWhen: (previous, current) => current is ServicioFormularioState,
			listener: (context, state) {
				if (state is! ServicioFormularioState) {
					return;
				}

				if (state.errorMensaje != null && state.errorMensaje!.isNotEmpty) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text(state.errorMensaje!)),
					);
				}

				if (state.exitoMensaje != null && state.exitoMensaje!.isNotEmpty) {
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text(state.exitoMensaje!)),
					);
					_limpiaFormularioDespuesDeExito(state);
				}
			},
			builder: (context, servicioState) {
				final estadoFormulario = servicioState is ServicioFormularioState
						? servicioState
						: const ServicioFormularioState();

				if (_ivaController.text != estadoFormulario.ivaPorcentaje) {
					_ivaController.text = estadoFormulario.ivaPorcentaje;
					_ivaController.selection = TextSelection.fromPosition(
						TextPosition(offset: _ivaController.text.length),
					);
				}
				if (_descuentoController.text != estadoFormulario.descuentoPorcentaje) {
					_descuentoController.text = estadoFormulario.descuentoPorcentaje;
					_descuentoController.selection = TextSelection.fromPosition(
						TextPosition(offset: _descuentoController.text.length),
					);
				}

				return BlocBuilder<CatalogoBloc, CatalogoState>(
					builder: (context, catalogoState) {
						if (catalogoState is CatalogoLoading ||
								catalogoState is CatalogoInitial) {
							return const Center(child: CircularProgressIndicator());
						}

						if (catalogoState is CatalogoError) {
							return Center(
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										Text(catalogoState.mensaje),
										const SizedBox(height: 12),
										ElevatedButton(
											onPressed: () {
												context.read<CatalogoBloc>().add(const CargarCatalogos());
											},
											child: const Text('Reintentar catalogos'),
										),
									],
								),
							);
						}

						final catalogos = catalogoState as CatalogoLoaded;

						final resolucionLabel = _labelResolucion(estadoFormulario.canal);
						final categoriasIndicadorIds = catalogos.categorias
								.where(
									(categoria) =>
											categoria.activo &&
											categoria.nombre.toLowerCase().contains('indicador'),
								)
								.map((categoria) => categoria.id)
								.toSet();

						final indicadoresActivos = catalogos.productos
								.where(
									(producto) =>
											producto.activo &&
											(categoriasIndicadorIds.contains(producto.categoriaId) ||
													producto.nombre.toLowerCase().contains('indicador')),
								)
								.toList();
						final productosCategoriaFalla = _categoriasFallaSeleccionadasIds.isEmpty
								? const <Producto>[]
								: catalogos.productos
										.where(
											(producto) =>
													_categoriasFallaSeleccionadasIds.contains(producto.categoriaId) &&
													producto.activo,
										)
										.toList();

						return LayoutBuilder(
							builder: (context, constraints) {
								final colorScheme = Theme.of(context).colorScheme;
								final temaBase = Theme.of(context);

								return SingleChildScrollView(
									padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
									child: Center(
										child: ConstrainedBox(
											constraints: const BoxConstraints(maxWidth: 1080),
											child: Container(
												padding: const EdgeInsets.all(16),
												decoration: BoxDecoration(
													color: colorScheme.surface,
													borderRadius: BorderRadius.circular(20),
													border: Border.all(color: colorScheme.outlineVariant),
													boxShadow: [
														BoxShadow(
															color: colorScheme.shadow.withValues(alpha: 0.08),
															blurRadius: 24,
															offset: const Offset(0, 12),
														),
													],
												),
												child: Theme(
													data: temaBase.copyWith(
														inputDecorationTheme: temaBase.inputDecorationTheme.copyWith(
															filled: true,
															fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
															border: OutlineInputBorder(
																borderRadius: BorderRadius.circular(12),
															),
															enabledBorder: OutlineInputBorder(
																borderRadius: BorderRadius.circular(12),
																borderSide: BorderSide(color: colorScheme.outlineVariant),
															),
														),
													),
													child: ChipTheme(
														data: temaBase.chipTheme.copyWith(
															shape: RoundedRectangleBorder(
																borderRadius: BorderRadius.circular(10),
															),
															side: BorderSide(color: colorScheme.outlineVariant),
														),
														child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
													_encabezadoSeccion(
														titulo: 'Orden de servicio',
														subtitulo: 'Registro tecnico con validacion y trazabilidad.',
													),
													const SizedBox(height: 8),
																												_buildFechaHoraOrden(context, estadoFormulario),
																												const SizedBox(height: 12),
											SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: Canal.values.map((canal) {
														return Padding(
															padding: const EdgeInsets.only(right: 8),
															child: ChoiceChip(
																label: Text(canal.name),
																selected: estadoFormulario.canal == canal,
																onSelected: (_) {
																	context.read<ServicioBloc>().add(
																			ServicioFormularioCambiado(canal: canal),
																	);
																},
															),
														);
													}).toList(),
												),
											),
											const SizedBox(height: 16),
											Row(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Expanded(
														child: TextField(
															controller: _buscarClienteController,
															decoration: _decoracionCampoCompacta(
																context,
																labelText: 'Cliente (buscar por nombre o CUIT)',
																suffixIcon: estadoFormulario.buscandoClientes
																		? const Padding(
																			padding: EdgeInsets.all(10),
																			child: SizedBox(
																				height: 14,
																				width: 14,
																				child: CircularProgressIndicator(strokeWidth: 2),
																			),
																		)
																		: IconButton(
																			onPressed: () {
																				context.read<ServicioBloc>().add(
																						ServicioBuscarClienteSolicitado(
																							query: _buscarClienteController.text,
																						),
																				);
																			},
																			icon: const Icon(Icons.search),
																		),
															),
															onSubmitted: (valor) {
																context.read<ServicioBloc>().add(
																		ServicioBuscarClienteSolicitado(query: valor),
																);
															},
														),
													),
													const SizedBox(width: 8),
													OutlinedButton.icon(
														onPressed: estadoFormulario.creandoCliente
															? null
															: () => _mostrarDialogoAltaRapidaCliente(context),
														style: OutlinedButton.styleFrom(
															padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
															visualDensity: VisualDensity.compact,
															tapTargetSize: MaterialTapTargetSize.shrinkWrap,
														),
														icon: estadoFormulario.creandoCliente
																? const SizedBox(
																	height: 14,
																	width: 14,
																	child: CircularProgressIndicator(strokeWidth: 2),
																)
																: const Icon(Icons.person_add_alt_1),
														label: Text(
															'Alta rapida cliente',
															style: _estiloTextoCompacto(context),
														),
													),
												],
											),
											//const SizedBox(height: 8),
											SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: estadoFormulario.clientesEncontrados.map((cliente) {
														return Padding(
															padding: const EdgeInsets.only(right: 8),
															child: ChoiceChip(
																label: Text(
																	cliente.cuit == null || cliente.cuit!.isEmpty
																			? cliente.nombre
																			: '${cliente.nombre} (${cliente.cuit})',
																),
																selected: estadoFormulario.clienteSeleccionado?.id == cliente.id,
																onSelected: (_) {
																	context.read<ServicioBloc>().add(
																			ServicioClienteSeleccionado(cliente: cliente),
																	);
																},
															),
														);
													}).toList(),
												),
											),
											const SizedBox(height: 16),
											_filaDosCampos(
												izquierda: _dropdownZonas(context, catalogos, estadoFormulario),
												derecha: TextField(
													controller: _lugarDetalleController,
													decoration: _decoracionCampoCompacta(
														context,
														labelText: _labelLugarDetalle(estadoFormulario.canal),
													),
													onChanged: (valor) {
														context.read<ServicioBloc>().add(
																ServicioFormularioCambiado(lugarDetalle: valor),
														);
													},
												),
											),
											const SizedBox(height: 12),
											Row(
												children: [
													Text(
														'Equipo modelo y numero de serie',
														style: Theme.of(context).textTheme.titleSmall,
													),
												],
											),
											
											const SizedBox(height: 8),
											_builderSeleccionEquipoDesdeIndicadores(
												context,
												indicadoresActivos,
											),
											const SizedBox(height: 12),
											_filaDosCampos(
												izquierda: TextField(
													controller: _equipoUbicacionController,
													decoration: _decoracionCampoCompacta(
														context,
														labelText: 'Equipo ubicacion',
													),
													onChanged: (valor) {
														context.read<ServicioBloc>().add(
																ServicioFormularioCambiado(equipoUbicacion: valor),
														);
													},
												),
												derecha: TextField(
													controller: _equipoAnioController,
													keyboardType: TextInputType.number,
													decoration: _decoracionCampoCompacta(
														context,
														labelText: 'Equipo anio',
													),
													onChanged: (valor) {
														context.read<ServicioBloc>().add(
																ServicioFormularioCambiado(equipoAnio: valor),
														);
													},
												),
											),
											const SizedBox(height: 12),
											Text(
												'Partes que mostraban falla',
												style: Theme.of(context).textTheme.titleSmall?.copyWith(
													fontSize: 13,
												),
											),
											const SizedBox(height: 8),
											SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: catalogos.categorias
															.where((categoria) => categoria.activo)
															.map((categoria) {
																final seleccionada = _categoriasFallaSeleccionadasIds.contains(
																	categoria.id,
																);
																return Padding(
																	padding: const EdgeInsets.only(right: 8),
																	child: FilterChip(
																		label: Text(
																			categoria.nombre,
																			style: _estiloTextoCompacto(context),
																		),
																		visualDensity: VisualDensity.compact,
																		materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
																		selected: seleccionada,
																		onSelected: (seleccionar) {
																			setState(() {
																				if (seleccionar) {
																					_categoriasFallaSeleccionadasIds.add(categoria.id);
																				} else {
																					_categoriasFallaSeleccionadasIds.remove(categoria.id);
																				}
																			});
																		},
																	),
																);
															})
															.toList(),
												),
											),
											if (_categoriasFallaSeleccionadasIds.isEmpty) ...[
												const SizedBox(height: 8),
												Text(
													'Selecciona una o mas categorias para elegir partes con falla.',
																			style: _estiloTextoCompacto(context),
												),
											],
											if (productosCategoriaFalla.isNotEmpty) ...[
												const SizedBox(height: 8),
												OutlinedButton.icon(
													onPressed: () {
														_mostrarDialogoSeleccionPartes(
															context: context,
															productosDisponibles: productosCategoriaFalla,
															nombresCategorias: {
																for (final categoria in catalogos.categorias) categoria.id: categoria.nombre,
															},
														);
													},
													icon: const Icon(Icons.checklist_rtl),
													label: Text(
														'Seleccionar partes (${_productosFallaSeleccionados.length})',
														style: _estiloTextoCompacto(context),
													),
												),
											],
											if (_productosFallaSeleccionados.isNotEmpty) ...[
												const SizedBox(height: 8),
														SingleChildScrollView(
															scrollDirection: Axis.horizontal,
															child: Row(
																children: _productosFallaSeleccionados.entries.map((entry) {
																	return Padding(
																		padding: const EdgeInsets.only(right: 8),
																		child: InputChip(
																			label: Text(
																										entry.value.nombre,
																				style: _estiloTextoCompacto(context),
																			),
																			visualDensity: VisualDensity.compact,
																			materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
															onDeleted: () {
																setState(() {
																	_productosFallaSeleccionados.remove(entry.key);
																});
																_actualizarPartesFallaronEnBloc();
															},
																				),
																			);
																		}).toList(),
																	),
																),
											],
											const SizedBox(height: 12),
											TextField(
												controller: _kmController,
												keyboardType: TextInputType.number,
												style: _estiloTextoCompacto(context),
												decoration: _decoracionCampoCompacta(
													context,
													labelText: 'Kilometros (km)',
												),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(km: valor),
													);
												},
											),
											const SizedBox(height: 12),
											TextField(
												controller: _sintomaController,
												minLines: 2,
												maxLines: 2,
												style: _estiloTextoCompacto(context),
												decoration: _decoracionCampoCompacta(
													context,
													labelText: 'Sintoma',
												),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(sintoma: valor),
													);
												},
											),
											const SizedBox(height: 12),
											SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: catalogos.diagnosticos
														.where((diagnostico) => diagnostico.activo)
														.map((diagnostico) {
															final seleccionado = estadoFormulario
																	.diagnosticoCatIdsSeleccionados
																	.contains(
																diagnostico.id,
																	);
															return Padding(
																padding: const EdgeInsets.only(right: 8),
																child: ChoiceChip(
																				label: Text(
																					diagnostico.nombre,
																					style: _estiloTextoCompacto(context),
																				),
																				visualDensity: VisualDensity.compact,
																				materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
																selected: seleccionado,
																onSelected: (seleccionar) {
																	final seleccionados = estadoFormulario
																			.diagnosticoCatIdsSeleccionados
																			.toSet();
																	if (seleccionar) {
																		seleccionados.add(diagnostico.id);
																	} else {
																		seleccionados.remove(diagnostico.id);
																	}
																	context.read<ServicioBloc>().add(
																			ServicioFormularioCambiado(
																				diagnosticoCatIdsSeleccionados:
																						seleccionados.toList(),
																			),
																	);
																},
																),
															);
														}).toList(),
												),
											),
											const SizedBox(height: 12),
											TextField(
												controller: _diagnosticoDetalleController,
												maxLines: 3,
												style: _estiloTextoCompacto(context),
												decoration: _decoracionCampoCompacta(
													context,
													labelText: 'Diagnostico detalle',
												),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(diagnosticoDetalle: valor),
													);
												},
											),
											const SizedBox(height: 12),
											Text(
												resolucionLabel,
												style: Theme.of(context).textTheme.titleSmall?.copyWith(
													fontSize: 11,
												),
											),
											const SizedBox(height: 8),
											SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: catalogos.resoluciones
														.where((resolucion) => resolucion.activo)
														.map((resolucion) {
															return Padding(
																padding: const EdgeInsets.only(right: 8),
																child: ChoiceChip(
																				label: Text(
																					resolucion.nombre,
																					style: _estiloTextoCompacto(context),
																				),
																				visualDensity: VisualDensity.compact,
																				materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
																selected: estadoFormulario.resolucionId == resolucion.id,
																onSelected: (_) {
																	context.read<ServicioBloc>().add(
																			ServicioFormularioCambiado(resolucionId: resolucion.id),
																	);
																},
																),
															);
														}).toList(),
												),
											),
											const SizedBox(height: 12),
											TextField(
												controller: _observacionesController,
												maxLines: 3,
												style: _estiloTextoCompacto(context),
												decoration: _decoracionCampoCompacta(
													context,
													labelText: 'Observaciones (opcional)',
												),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(observaciones: valor),
													);
												},
											),
											const SizedBox(height: 20),
											SizedBox(
												width: double.infinity,
												child: ElevatedButton.icon(
													style: ElevatedButton.styleFrom(
														padding: const EdgeInsets.symmetric(vertical: 14),
														shape: RoundedRectangleBorder(
															borderRadius: BorderRadius.circular(12),
														),
													),
													onPressed: estadoFormulario.guardando
															? null
															: () {
																context.read<ServicioBloc>().add(
																		const ServicioGuardarPressed(),
																);
															},
													icon: estadoFormulario.guardando
															? const SizedBox(
																height: 16,
																width: 16,
																child: CircularProgressIndicator(strokeWidth: 2),
															)
															: const Icon(Icons.save),
													label: const Text('Crear orden de servicio'),
												),
											),
										],
									),
								),
							),
						),
					),
				),
								);
							},
						);
					},
				);
			},
		);
	}

	Widget _encabezadoSeccion({required String titulo, required String subtitulo}) {
		final colorScheme = Theme.of(context).colorScheme;
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
			decoration: BoxDecoration(
				color: colorScheme.primary.withValues(alpha: 0.07),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						titulo,
						style: Theme.of(context).textTheme.titleMedium?.copyWith(
							fontWeight: FontWeight.w700,
							letterSpacing: 0.2,
						),
					),
					const SizedBox(height: 2),
					/**Text(
						subtitulo,
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
							color: colorScheme.onSurfaceVariant,
						),
					),
					),*/
				],
			),
		);
	}

	Widget _buildFechaHoraOrden(
		BuildContext context,
		ServicioFormularioState estado,
	) {
		final fechaHora = estado.fechaHoraServicio;
		final fechaHoraTexto = fechaHora == null
				? 'Se completara al iniciar la carga de la orden'
				: _formatearFechaHora(fechaHora);
		final zonaTexto = estado.timezoneIana.trim().isEmpty
				? 'Zona horaria pendiente'
				: estado.timezoneIana.trim();

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
			),
			child: Row(
				children: [
					const Icon(Icons.schedule, size: 16),
					const SizedBox(width: 8),
					Expanded(
						child: Text(
							'Fecha y hora de orden: $fechaHoraTexto ($zonaTexto)',
							style: _estiloTextoCompacto(context),
						),
					),
				],
			),
		);
	}

	void _limpiaFormularioDespuesDeExito(ServicioFormularioState estado) {
		if (estado.exitoMensaje == null || estado.exitoMensaje!.isEmpty) {
			return;
		}
		_limpiarFormularioVisual();
	}

	void _actualizarPartesFallaronEnBloc() {
		final productosFalla = _productosFallaSeleccionados.values
				.map(
					(item) => ProductoFalla(
						parteFallo: item.parteFallo,
						productoFallaId: item.productoId,
					),
				)
				.toList();
		final partesFallaron = productosFalla
				.map((item) => item.parteFallo)
				.toSet()
				.toList();

		context.read<ServicioBloc>().add(
			ServicioFormularioCambiado(
				partesFallaronTexto: partesFallaron.join(', '),
				productosFallaSeleccionados: productosFalla,
			),
		);
	}

	Future<void> _mostrarDialogoSeleccionPartes({
		required BuildContext context,
		required List<Producto> productosDisponibles,
		required Map<String, String> nombresCategorias,
	}) async {
		final seleccionTemporal =
				Map<String, _ProductoFallaSeleccionado>.from(_productosFallaSeleccionados);
		final productosPorCategoria = <String, List<Producto>>{};

		for (final producto in productosDisponibles) {
			productosPorCategoria.putIfAbsent(producto.categoriaId, () => <Producto>[]).add(producto);
		}

		for (final lista in productosPorCategoria.values) {
			lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
		}

		await showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return StatefulBuilder(
					builder: (context, setDialogState) {
						return AlertDialog(
							title: const Text('Seleccionar partes con falla'),
							content: SizedBox(
								width: 640,
								height: 420,
								child: ListView(
									children: productosPorCategoria.entries.map((entry) {
										final categoriaId = entry.key;
										final productos = entry.value;
										final nombreCategoria =
												nombresCategorias[categoriaId] ?? 'Categoria';

										return ExpansionTile(
											tilePadding: const EdgeInsets.symmetric(horizontal: 4),
											title: Text(nombreCategoria),
											children: productos.map((producto) {
												final seleccionado =
														seleccionTemporal.containsKey(producto.id);
												return CheckboxListTile(
													dense: true,
													value: seleccionado,
													title: Text(producto.nombre),
													controlAffinity:
															ListTileControlAffinity.leading,
													onChanged: (valor) {
														setDialogState(() {
															if (valor == true) {
																				seleccionTemporal[producto.id] = _ProductoFallaSeleccionado(
																					productoId: producto.id,
																					nombre: producto.nombre,
																					parteFallo: _normalizarParteFalladaBackend(nombreCategoria),
																				);
															} else {
																seleccionTemporal.remove(producto.id);
															}
														});
													},
												);
											}).toList(),
										);
									}).toList(),
								),
							),
							actions: [
								TextButton(
									onPressed: () => Navigator.of(dialogContext).pop(),
									child: const Text('Cancelar'),
								),
								ElevatedButton(
									onPressed: () {
										setState(() {
											_productosFallaSeleccionados
												..clear()
												..addAll(seleccionTemporal);
										});
										_actualizarPartesFallaronEnBloc();
										Navigator.of(dialogContext).pop();
									},
									child: const Text('Aplicar'),
								),
							],
						);
					},
				);
			},
		);
	}

	Widget _builderSeleccionEquipoDesdeIndicadores(
		BuildContext context,
		List<Producto> indicadores,
	) {
		final opciones = indicadores;

		if (opciones.isEmpty) {
			return Container(
				width: double.infinity,
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
					borderRadius: BorderRadius.circular(8),
				),
				child: const Text(
					'No hay indicadores activos para seleccionar modelo.',
				),
			);
		}

		return _filaDosCampos(
			izquierda: DropdownButtonFormField<String>(
				value: _modeloIndicadorSeleccionadoId,
				isExpanded: true,
				decoration: _decoracionCampoCompacta(
					context,
					labelText: 'Equipo modelo (desde indicadores)',
				),
				items: opciones
						.map(
							(producto) => DropdownMenuItem<String>(
								value: producto.id,
								child: Text(
									producto.nombre,
									style: _estiloTextoCompacto(context),
									overflow: TextOverflow.ellipsis,
									maxLines: 1,
								),
							),
						)
						.toList(),
				selectedItemBuilder: (context) {
					return opciones
							.map(
								(producto) => Align(
									alignment: Alignment.centerLeft,
									child: Text(
										producto.nombre,
										style: _estiloTextoCompacto(context),
										overflow: TextOverflow.ellipsis,
										maxLines: 1,
									),
								),
							)
							.toList();
				},
				onChanged: (valor) {
					if (valor == null) {
						return;
					}
					setState(() {
						_modeloIndicadorSeleccionadoId = valor;
					});
					final productoSeleccionado = opciones.firstWhere(
						(producto) => producto.id == valor,
					);
					context.read<ServicioBloc>().add(
						ServicioFormularioCambiado(equipoModelo: productoSeleccionado.nombre),
					);
				},
			),
			derecha: TextField(
				controller: _equipoNroSerieController,
				decoration: _decoracionCampoCompacta(
					context,
					labelText: 'Equipo nro de serie',
				),
				onChanged: (valor) {
					context.read<ServicioBloc>().add(
						ServicioFormularioCambiado(equipoNroSerie: valor),
					);
				},
			),
		);
	}

	Widget _filaDosCampos({required Widget izquierda, required Widget derecha}) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Expanded(child: izquierda),
				const SizedBox(width: 12),
				Expanded(child: derecha),
			],
		);
	}

	Widget _dropdownZonas(
		BuildContext context,
		CatalogoLoaded catalogos,
		ServicioFormularioState estado,
	) {
		return DropdownButtonFormField<String>(
			value: estado.lugarProvinciaId.isEmpty ? null : estado.lugarProvinciaId,
			isExpanded: true,
			decoration: _decoracionCampoCompacta(
				context,
				labelText: 'Zona / Provincia',
			),
			items: catalogos.zonas
					.where((zona) => zona.activo)
					.map(
						(zona) => DropdownMenuItem(
							value: zona.id,
							child: Text(
								'${zona.nombre} - ${zona.provincia}',
								style: _estiloTextoCompacto(context),
								overflow: TextOverflow.ellipsis,
								maxLines: 1,
							),
						),
					)
					.toList(),
			selectedItemBuilder: (context) {
				return catalogos.zonas
						.where((zona) => zona.activo)
						.map(
							(zona) => Align(
								alignment: Alignment.centerLeft,
								child: Text(
									'${zona.nombre} - ${zona.provincia}',
									style: _estiloTextoCompacto(context),
									overflow: TextOverflow.ellipsis,
									maxLines: 1,
								),
							),
						)
						.toList();
			},
			onChanged: (valor) {
				if (valor == null) {
					return;
				}
				context.read<ServicioBloc>().add(ServicioFormularioCambiado(zonaId: valor));
			},
		);
	}

	TextStyle _estiloTextoCompacto(BuildContext context) {
		final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
		return base.copyWith(fontSize: 12.5);
	}

	InputDecoration _decoracionCampoCompacta(
		BuildContext context, {
		required String labelText,
		Widget? suffixIcon,
	}) {
		return InputDecoration(
			labelText: labelText,
			labelStyle: _estiloTextoCompacto(context),
			isDense: true,
			contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
			suffixIcon: suffixIcon,
		);
	}

	String _labelLugarDetalle(Canal? canal) {
		switch (canal) {
			case Canal.campo:
				return 'Lugar detalle (campo)';
			case Canal.remoto:
				return 'Lugar detalle (contacto remoto)';
			case Canal.fabrica:
				return 'Lugar detalle (fabrica)';
			case null:
				return 'Lugar detalle';
		}
	}

	String _labelResolucion(Canal? canal) {
		switch (canal) {
			case Canal.campo:
				return 'Resolucion';
			case Canal.remoto:
				return 'Resultado del contacto';
			case Canal.fabrica:
				return 'Trabajo realizado';
			case null:
				return 'Resolucion';
		}
	}

	String _formatearFechaHora(DateTime fechaHora) {
		final dia = fechaHora.day.toString().padLeft(2, '0');
		final mes = fechaHora.month.toString().padLeft(2, '0');
		final anio = fechaHora.year.toString();
		final hora = fechaHora.hour.toString().padLeft(2, '0');
		final minuto = fechaHora.minute.toString().padLeft(2, '0');
		return '$dia/$mes/$anio $hora:$minuto';
	}

	String _normalizarParteFalladaBackend(String valorCrudo) {
		final valor = valorCrudo.toLowerCase().trim();
		if (valor.isEmpty) {
			return 'otro';
		}
		if (valor.contains('indicador')) {
			return 'indicador';
		}
		if (valor.contains('celda')) {
			return 'celda';
		}
		if (valor.contains('app') && (valor.contains('movil') || valor.contains('mobile'))) {
			return 'app_movil';
		}
		if (valor.contains('movil') || valor.contains('mobile') || valor.contains('celular')) {
			return 'app_movil';
		}
		if (valor.contains('app') && valor.contains('pc')) {
			return 'app_pc';
		}
		if (valor.contains('pc') || valor.contains('web') || valor.contains('escritorio')) {
			return 'app_pc';
		}
		if (valor.contains('tablet')) {
			return 'tablet';
		}
		return 'otro';
	}
}

class _ProductoFallaSeleccionado {
	final String productoId;
	final String nombre;
	final String parteFallo;

	const _ProductoFallaSeleccionado({
		required this.productoId,
		required this.nombre,
		required this.parteFallo,
	});
}
