import 'dart:convert';

import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
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
	final TextEditingController _equipoModeloController = TextEditingController();
	final TextEditingController _equipoUbicacionController = TextEditingController();
	final TextEditingController _equipoAnioController = TextEditingController();
	final TextEditingController _kmController = TextEditingController();
	final TextEditingController _sintomaController = TextEditingController();
	final TextEditingController _diagnosticoDetalleController = TextEditingController();
	final TextEditingController _observacionesController = TextEditingController();

	bool _equipoCargaManual = false;
	String? _modeloIndicadorSeleccionadoId;
	String? _serieIndicadorSeleccionada;

	String _categoriaFallaSeleccionadaId = '';
	final Map<String, String> _productosFallaSeleccionados = <String, String>{};

	@override
	void initState() {
		super.initState();
		final catalogoState = context.read<CatalogoBloc>().state;
		if (catalogoState is! CatalogoLoaded) {
			context.read<CatalogoBloc>().add(const CargarCatalogos());
		}

		if (context.read<ServicioBloc>().state is! ServicioFormularioState) {
			context.read<ServicioBloc>().add(const ServicioFormularioReiniciado());
		}
	}

	@override
	void dispose() {
		_buscarClienteController.dispose();
		_lugarDetalleController.dispose();
		_equipoNroSerieController.dispose();
		_equipoModeloController.dispose();
		_equipoUbicacionController.dispose();
		_equipoAnioController.dispose();
		_kmController.dispose();
		_sintomaController.dispose();
		_diagnosticoDetalleController.dispose();
		_observacionesController.dispose();
		super.dispose();
	}

	void _limpiarFormularioVisual() {
		_buscarClienteController.clear();
		_lugarDetalleController.clear();
		_equipoNroSerieController.clear();
		_equipoModeloController.clear();
		_equipoUbicacionController.clear();
		_equipoAnioController.clear();
		_equipoCargaManual = false;
		_modeloIndicadorSeleccionadoId = null;
		_serieIndicadorSeleccionada = null;
		_categoriaFallaSeleccionadaId = '';
		_productosFallaSeleccionados.clear();
		_kmController.clear();
		_sintomaController.clear();
		_diagnosticoDetalleController.clear();
		_observacionesController.clear();
		context.read<ServicioBloc>().add(
			const ServicioFormularioCambiado(partesFallaronTexto: ''),
		);
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
						final productosCategoriaFalla = _categoriaFallaSeleccionadaId.isEmpty
								? const <Producto>[]
								: catalogos.productos
										.where(
											(producto) =>
													producto.categoriaId == _categoriaFallaSeleccionadaId &&
													producto.activo,
										)
										.toList();

						return LayoutBuilder(
							builder: (context, constraints) {
								final esWeb = constraints.maxWidth > 800;

								return SingleChildScrollView(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Wrap(
												spacing: 8,
												runSpacing: 8,
												children: Canal.values.map((canal) {
													return ChoiceChip(
														label: Text(canal.name),
														selected: estadoFormulario.canal == canal,
														onSelected: (_) {
															context.read<ServicioBloc>().add(
																	ServicioFormularioCambiado(canal: canal),
															);
														},
													);
												}).toList(),
											),
											const SizedBox(height: 16),
											TextField(
												controller: _buscarClienteController,
												decoration: InputDecoration(
													labelText: 'Cliente (buscar por nombre o CUIT)',
													suffixIcon: estadoFormulario.buscandoClientes
															? const Padding(
																padding: EdgeInsets.all(12),
																child: SizedBox(
																	height: 16,
																	width: 16,
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
											const SizedBox(height: 8),
											Wrap(
												spacing: 8,
												runSpacing: 8,
												children: [
													for (final cliente in estadoFormulario.clientesEncontrados)
														ChoiceChip(
															label: Text(
																cliente.cuit == null || cliente.cuit!.isEmpty
																		? cliente.nombre
																		: '${cliente.nombre} (${cliente.cuit})',
															),
															selected:
																	estadoFormulario.clienteSeleccionado?.id ==
																	cliente.id,
															onSelected: (_) {
																context.read<ServicioBloc>().add(
																		ServicioClienteSeleccionado(cliente: cliente),
																);
															},
														),
													OutlinedButton.icon(
														onPressed: estadoFormulario.creandoCliente
															? null
															: () => _mostrarDialogoAltaRapidaCliente(context),
														icon: estadoFormulario.creandoCliente
																? const SizedBox(
																	height: 14,
																	width: 14,
																	child: CircularProgressIndicator(strokeWidth: 2),
																)
																: const Icon(Icons.person_add_alt_1),
														label: const Text('Alta rapida cliente'),
													),
												],
											),
											const SizedBox(height: 16),
											_dropdownZonas(context, catalogos, estadoFormulario),
											const SizedBox(height: 12),
											TextField(
												controller: _lugarDetalleController,
												decoration: InputDecoration(labelText: _labelLugarDetalle(estadoFormulario.canal)),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(lugarDetalle: valor),
													);
												},
											),
											const SizedBox(height: 12),
											Row(
												children: [
													Expanded(
														child: Text(
															'Equipo modelo y numero de serie',
															style: Theme.of(context).textTheme.titleSmall,
														),
													),
													Switch(
														value: _equipoCargaManual,
														onChanged: (value) {
															setState(() {
																_equipoCargaManual = value;
																_modeloIndicadorSeleccionadoId = null;
																_serieIndicadorSeleccionada = null;
																if (!value) {
																	_equipoModeloController.clear();
																	_equipoNroSerieController.clear();
																}
															});
														},
													),
												],
											),
											Align(
												alignment: Alignment.centerLeft,
												child: Text(
													_equipoCargaManual
															? 'Modo manual activo'
															: 'Modo lista de indicadores activo',
													style: Theme.of(context).textTheme.bodySmall,
												),
											),
											const SizedBox(height: 8),
											if (_equipoCargaManual)
												_estructuraResponsiva(
													esWeb: esWeb,
													izquierda: TextField(
														controller: _equipoModeloController,
														decoration: const InputDecoration(labelText: 'Equipo modelo'),
														onChanged: (valor) {
															context.read<ServicioBloc>().add(
																	ServicioFormularioCambiado(equipoModelo: valor),
															);
														},
													),
													derecha: TextField(
														controller: _equipoNroSerieController,
														decoration: const InputDecoration(labelText: 'Equipo nro de serie'),
														onChanged: (valor) {
															context.read<ServicioBloc>().add(
																	ServicioFormularioCambiado(equipoNroSerie: valor),
															);
														},
													),
												)
											else
												_builderSeleccionEquipoDesdeIndicadores(
													context,
													esWeb,
												),
											const SizedBox(height: 12),
											_estructuraResponsiva(
												esWeb: esWeb,
												izquierda: TextField(
													controller: _equipoUbicacionController,
													decoration: const InputDecoration(labelText: 'Equipo ubicacion'),
													onChanged: (valor) {
														context.read<ServicioBloc>().add(
																ServicioFormularioCambiado(equipoUbicacion: valor),
														);
													},
												),
												derecha: TextField(
													controller: _equipoAnioController,
													keyboardType: TextInputType.number,
													decoration: const InputDecoration(labelText: 'Equipo anio'),
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
												style: Theme.of(context).textTheme.titleSmall,
											),
											const SizedBox(height: 8),
											SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: catalogos.categorias
															.where((categoria) => categoria.activo)
															.map((categoria) {
																return Padding(
																	padding: const EdgeInsets.only(right: 8),
																	child: ChoiceChip(
																		label: Text(categoria.nombre),
																		selected:
																				_categoriaFallaSeleccionadaId == categoria.id,
																		onSelected: (_) {
																			setState(() {
																				_categoriaFallaSeleccionadaId = categoria.id;
																			});
																		},
																	),
																);
															})
															.toList(),
												),
											),
											if (productosCategoriaFalla.isNotEmpty) ...[
												const SizedBox(height: 8),
												Wrap(
													spacing: 8,
													runSpacing: 8,
													children: productosCategoriaFalla.map((producto) {
														final seleccionado =
																_productosFallaSeleccionados.containsKey(producto.id);
														return FilterChip(
															label: Text(producto.nombre),
															selected: seleccionado,
															onSelected: (_) {
																_toggleProductoFalla(producto);
															},
														);
													}).toList(),
												),
											],
											if (_productosFallaSeleccionados.isNotEmpty) ...[
												const SizedBox(height: 8),
												Wrap(
													spacing: 8,
													runSpacing: 8,
													children: _productosFallaSeleccionados.entries.map((entry) {
														return InputChip(
															label: Text(entry.value),
															onDeleted: () {
																setState(() {
																	_productosFallaSeleccionados.remove(entry.key);
																});
																_actualizarPartesFallaronEnBloc();
															},
														);
													}).toList(),
												),
											],
											const SizedBox(height: 12),
											TextField(
												controller: _kmController,
												keyboardType: TextInputType.number,
												decoration: const InputDecoration(labelText: 'Kilometros (km)'),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(km: valor),
													);
												},
											),
											const SizedBox(height: 12),
											TextField(
												controller: _sintomaController,
												maxLines: 3,
												decoration: const InputDecoration(labelText: 'Sintoma'),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(sintoma: valor),
													);
												},
											),
											const SizedBox(height: 12),
											Wrap(
												spacing: 8,
												runSpacing: 8,
												children: catalogos.diagnosticos
														.where((diagnostico) => diagnostico.activo)
														.map((diagnostico) {
															return ChoiceChip(
																label: Text(diagnostico.nombre),
																selected:
																		estadoFormulario.diagnosticoCatId == diagnostico.id,
																onSelected: (_) {
																	context.read<ServicioBloc>().add(
																			ServicioFormularioCambiado(
																				diagnosticoCatId: diagnostico.id,
																			),
																	);
																},
															);
														}).toList(),
											),
											const SizedBox(height: 12),
											TextField(
												controller: _diagnosticoDetalleController,
												maxLines: 3,
												decoration: const InputDecoration(labelText: 'Diagnostico detalle'),
												onChanged: (valor) {
													context.read<ServicioBloc>().add(
															ServicioFormularioCambiado(diagnosticoDetalle: valor),
													);
												},
											),
											const SizedBox(height: 12),
											Text(
												resolucionLabel,
												style: Theme.of(context).textTheme.titleSmall,
											),
											const SizedBox(height: 8),
											Wrap(
												spacing: 8,
												runSpacing: 8,
												children: catalogos.resoluciones
														.where((resolucion) => resolucion.activo)
														.map((resolucion) {
															return ChoiceChip(
																label: Text(resolucion.nombre),
																selected: estadoFormulario.resolucionId == resolucion.id,
																onSelected: (_) {
																	context.read<ServicioBloc>().add(
																			ServicioFormularioCambiado(resolucionId: resolucion.id),
																	);
																},
															);
														}).toList(),
											),
											const SizedBox(height: 12),
											TextField(
												controller: _observacionesController,
												maxLines: 3,
												decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
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
								);
							},
						);
					},
				);
			},
		);
	}

	void _limpiaFormularioDespuesDeExito(ServicioFormularioState estado) {
		if (estado.exitoMensaje == null || estado.exitoMensaje!.isEmpty) {
			return;
		}
		_limpiarFormularioVisual();
	}

	void _toggleProductoFalla(Producto producto) {
		setState(() {
			if (_productosFallaSeleccionados.containsKey(producto.id)) {
				_productosFallaSeleccionados.remove(producto.id);
			} else {
				_productosFallaSeleccionados[producto.id] = producto.nombre;
			}
		});
		_actualizarPartesFallaronEnBloc();
	}

	void _actualizarPartesFallaronEnBloc() {
		final valor = _productosFallaSeleccionados.values.join(', ');
		final productoIds = _productosFallaSeleccionados.keys.toList();

		if (_modeloIndicadorSeleccionadoId != null &&
				!_productosFallaSeleccionados.containsKey(_modeloIndicadorSeleccionadoId)) {
			_modeloIndicadorSeleccionadoId = null;
			context.read<ServicioBloc>().add(
				const ServicioFormularioCambiado(equipoModelo: ''),
			);
		}

		if (_serieIndicadorSeleccionada != null &&
				!_productosFallaSeleccionados.containsKey(_serieIndicadorSeleccionada)) {
			_serieIndicadorSeleccionada = null;
			context.read<ServicioBloc>().add(
				const ServicioFormularioCambiado(equipoNroSerie: ''),
			);
		}

		context.read<ServicioBloc>().add(
			ServicioFormularioCambiado(
				partesFallaronTexto: valor,
				productoIdsSeleccionados: productoIds,
			),
		);
	}

	Widget _builderSeleccionEquipoDesdeIndicadores(
		BuildContext context,
		bool esWeb,
	) {
		final opciones = _productosFallaSeleccionados.entries.toList();

		if (opciones.isEmpty) {
			return Container(
				width: double.infinity,
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
					borderRadius: BorderRadius.circular(8),
				),
				child: const Text(
					'Primero seleccioná indicadores en Partes que mostraban falla para elegir modelo y numero de serie.',
				),
			);
		}

		return _estructuraResponsiva(
			esWeb: esWeb,
			izquierda: DropdownButtonFormField<String>(
				value: _modeloIndicadorSeleccionadoId,
				decoration: const InputDecoration(labelText: 'Equipo modelo (desde indicadores)'),
				items: opciones
						.map(
							(entry) => DropdownMenuItem<String>(
								value: entry.key,
								child: Text(entry.value),
							),
						)
						.toList(),
				onChanged: (valor) {
					if (valor == null) {
						return;
					}
					setState(() {
						_modeloIndicadorSeleccionadoId = valor;
					});
					context.read<ServicioBloc>().add(
						ServicioFormularioCambiado(equipoModelo: _productosFallaSeleccionados[valor]),
					);
				},
			),
			derecha: DropdownButtonFormField<String>(
				value: _serieIndicadorSeleccionada,
				decoration: const InputDecoration(labelText: 'Equipo nro de serie (seleccionado)'),
				items: opciones
						.map(
							(entry) => DropdownMenuItem<String>(
								value: entry.key,
								child: Text(entry.key),
							),
						)
						.toList(),
				onChanged: (valor) {
					if (valor == null) {
						return;
					}
					setState(() {
						_serieIndicadorSeleccionada = valor;
					});
					context.read<ServicioBloc>().add(
						ServicioFormularioCambiado(equipoNroSerie: valor),
					);
				},
			),
		);
	}

	Widget _estructuraResponsiva({
		required bool esWeb,
		required Widget izquierda,
		required Widget derecha,
	}) {
		if (!esWeb) {
			return Column(
				children: [
					izquierda,
					const SizedBox(height: 12),
					derecha,
				],
			);
		}

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
			decoration: const InputDecoration(labelText: 'Zona / Provincia'),
			items: catalogos.zonas
					.where((zona) => zona.activo)
					.map(
						(zona) => DropdownMenuItem(
							value: zona.id,
							child: Text('${zona.nombre} - ${zona.provincia}'),
						),
					)
					.toList(),
			onChanged: (valor) {
				if (valor == null) {
					return;
				}
				context.read<ServicioBloc>().add(ServicioFormularioCambiado(zonaId: valor));
			},
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
}
