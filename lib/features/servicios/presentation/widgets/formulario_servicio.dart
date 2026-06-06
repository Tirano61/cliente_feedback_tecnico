import 'dart:convert';
import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/politica_firma_canal.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';

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
	String? _ultimoServicioConFlujoDocumento;
	String? _clienteSeleccionadoVisualId;

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
		_clienteSeleccionadoVisualId = null;
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
		final formularioKey = GlobalKey<FormState>();
		final cuitController = TextEditingController();
		final nombreController = TextEditingController();
		final contactoController = TextEditingController();
		final telefonoController = TextEditingController();
		final localidadController = TextEditingController();

		await showDialog<void>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Alta rapida de cliente'),
					content: SizedBox(
						width: 560,
						child: Form(
							key: formularioKey,
							child: SingleChildScrollView(
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										const Text('Completa los datos del cliente para crear el registro.'),
										const SizedBox(height: 10),
										TextFormField(
											controller: cuitController,
											keyboardType: TextInputType.number,
											decoration: const InputDecoration(
												labelText: 'CUIT',
												border: OutlineInputBorder(),
											),
											validator: (valor) {
												if ((valor ?? '').trim().isEmpty) {
													return 'El CUIT es obligatorio.';
												}
												return null;
											},
										),
										const SizedBox(height: 10),
										TextFormField(
											controller: nombreController,
											decoration: const InputDecoration(
												labelText: 'Nombre',
												border: OutlineInputBorder(),
											),
											validator: (valor) {
												if ((valor ?? '').trim().isEmpty) {
													return 'El nombre es obligatorio.';
												}
												return null;
											},
										),
										const SizedBox(height: 10),
										TextFormField(
											controller: contactoController,
											decoration: const InputDecoration(
												labelText: 'Contacto',
												border: OutlineInputBorder(),
											),
											validator: (valor) {
												if ((valor ?? '').trim().isEmpty) {
													return 'El contacto es obligatorio.';
												}
												return null;
											},
										),
										const SizedBox(height: 10),
										TextFormField(
											controller: telefonoController,
											keyboardType: TextInputType.phone,
											decoration: const InputDecoration(
												labelText: 'Telefono',
												border: OutlineInputBorder(),
											),
											validator: (valor) {
												if ((valor ?? '').trim().isEmpty) {
													return 'El telefono es obligatorio.';
												}
												return null;
											},
										),
										const SizedBox(height: 10),
										TextFormField(
											controller: localidadController,
											decoration: const InputDecoration(
												labelText: 'Localidad',
												border: OutlineInputBorder(),
											),
											validator: (valor) {
												if ((valor ?? '').trim().isEmpty) {
													return 'La localidad es obligatoria.';
												}
												return null;
											},
										),
									],
								),
							),
						),
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(),
							child: const Text('Cancelar'),
						),
						ElevatedButton(
							onPressed: () {
								if (!(formularioKey.currentState?.validate() ?? false)) {
									return;
								}

								final payload = <String, dynamic>{
									'cuit': cuitController.text.trim(),
									'nombre': nombreController.text.trim(),
									'contacto': contactoController.text.trim(),
									'telefono': telefonoController.text.trim(),
									'localidad': localidadController.text.trim(),
								};
								context.read<ServicioBloc>().add(
										ServicioCrearClienteRapidoSolicitado(
											payloadJson: jsonEncode(payload),
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

		cuitController.dispose();
		nombreController.dispose();
		contactoController.dispose();
		telefonoController.dispose();
		localidadController.dispose();
	}


	Future<void> _mostrarFlujoDocumentoCierre({
		required BuildContext context,
		required OrdenServicioRespuesta orden,
		required Uint8List pdfBytes,
		required String nombreArchivo,
	}) async {
		if (!mounted) {
			return;
		}

		final canal = orden.servicio.canal;
		final firmaHabilitada = PoliticaFirmaCanal.firmaHabilitada(canal);
		var agregarFirma = false;
		var firmaFechaHora = DateTime.now();
		var nombreFirmante = '';
		var documentoFirmante = '';
		final firmaClienteController = SignatureController(
			penStrokeWidth: 2.4,
			penColor: Colors.black,
			exportBackgroundColor: Colors.white,
		);

		await showModalBottomSheet<void>(
			context: context,
			isScrollControlled: true,
			showDragHandle: true,
			builder: (sheetContext) {
				return StatefulBuilder(
					builder: (context, setModalState) {
						return BlocBuilder<ServicioBloc, ServicioState>(
							builder: (context, state) {
								final estadoFormulario = state is ServicioFormularioState
										? state
										: const ServicioFormularioState();
								return SafeArea(
									child: Padding(
										padding: EdgeInsets.only(
											left: 16,
											right: 16,
											top: 8,
											bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
										),
										child: SingleChildScrollView(
											child: Column(
												mainAxisSize: MainAxisSize.min,
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(
														'Cierre de orden y documento',
														style: Theme.of(context).textTheme.titleMedium,
													),
													const SizedBox(height: 8),
													Text('Servicio: ${orden.servicioId}'),
													Text('Canal: ${canal.name}'),
													const SizedBox(height: 8),
													SizedBox(
														width: double.infinity,
														child: OutlinedButton.icon(
															onPressed: () async {
																await Printing.layoutPdf(
																	name: nombreArchivo,
																	onLayout: (_) async => pdfBytes,
																);
															},
															icon: const Icon(Icons.picture_as_pdf_outlined),
															label: const Text('Ver / Guardar PDF'),
														),
													),
													const SizedBox(height: 10),
													if (!firmaHabilitada)
														Container(
															width: double.infinity,
															padding: const EdgeInsets.all(12),
															decoration: BoxDecoration(
																color: Theme.of(context)
																		.colorScheme
																		.surfaceContainerHighest,
																borderRadius: BorderRadius.circular(10),
															),
															child: const Text('Para este canal no se solicita firma.'),
														)
													else ...[
														SwitchListTile.adaptive(
															contentPadding: EdgeInsets.zero,
															title: const Text('Agregar firma ahora'),
															value: agregarFirma,
															onChanged: (valor) {
																setModalState(() {
																	agregarFirma = valor;
																	if (valor) {
																		firmaFechaHora = DateTime.now();
																	} else {
																		firmaClienteController.clear();
																	}
																});
															},
														),
														if (!agregarFirma)
															Container(
																width: double.infinity,
																padding: const EdgeInsets.all(12),
																decoration: BoxDecoration(
																	color: Theme.of(context)
																			.colorScheme
																			.surfaceContainerHighest,
																	borderRadius: BorderRadius.circular(10),
																),
																child: const Text(
																	'Se puede cerrar sin firma por cliente ausente.',
																),
															)
														else ...[
															const SizedBox(height: 8),
															TextField(
																decoration: const InputDecoration(
																	labelText: 'Nombre del firmante',
																),
																onChanged: (valor) => nombreFirmante = valor,
															),
															const SizedBox(height: 8),
															TextField(
																decoration: const InputDecoration(
																	labelText: 'Documento (opcional)',
																),
																onChanged: (valor) => documentoFirmante = valor,
															),
															const SizedBox(height: 10),
															Text(
																'Firma manuscrita del cliente',
																style: Theme.of(context).textTheme.labelLarge,
															),
															const SizedBox(height: 6),
															Container(
																height: 160,
																width: double.infinity,
																decoration: BoxDecoration(
																	border: Border.all(
																		color: Theme.of(context).colorScheme.outlineVariant,
																	),
																	borderRadius: BorderRadius.circular(10),
																	color: Colors.white,
																),
																child: Signature(
																	controller: firmaClienteController,
																	backgroundColor: Colors.white,
																),
															),
															Align(
																alignment: Alignment.centerRight,
																child: TextButton.icon(
																	onPressed: () {
																		firmaClienteController.clear();
																		setModalState(() {});
																	},
																	icon: const Icon(Icons.cleaning_services_outlined),
																	label: const Text('Limpiar firma'),
																),
															),
															const SizedBox(height: 8),
															Text(
																'Fecha/hora de firma: ${_formatearFechaHora(firmaFechaHora)}',
															),
														],
													],
													const SizedBox(height: 12),
													SizedBox(
														width: double.infinity,
														child: ElevatedButton.icon(
															onPressed: estadoFormulario.subiendoDocumento
																? null
																		: () async {
																	final nombreFirma = agregarFirma
																						? nombreFirmante.trim()
																			: null;
																	if (agregarFirma && (nombreFirma ?? '').isEmpty) {
												await showDialog<void>(
													context: sheetContext,
													builder: (dialogCtx) => AlertDialog(
														title: const Text('Dato requerido'),
														content: const Text(
															'Si agregás firma, el nombre del firmante es obligatorio.',
														),
														actions: [
															TextButton(
																onPressed: () => Navigator.of(dialogCtx).pop(),
																child: const Text('Aceptar'),
															),
														],
													),
												);
																		return;
																	}

																			Uint8List? firmaTrazoPng;
																			if (agregarFirma) {
																				if (firmaClienteController.isEmpty) {
																					await showDialog<void>(
																						context: sheetContext,
																						builder: (dialogCtx) => AlertDialog(
																							title: const Text('Firma requerida'),
																							content: const Text('Debés dibujar la firma del cliente en el recuadro.'),
																							actions: [
																								TextButton(
																									onPressed: () => Navigator.of(dialogCtx).pop(),
																									child: const Text('Aceptar'),
																								),
																							],
																						),
																					);
																					return;
																				}
																				firmaTrazoPng = await firmaClienteController.toPngBytes();
																				if (firmaTrazoPng == null || firmaTrazoPng.isEmpty) {
																					await showDialog<void>(
																						context: sheetContext,
																						builder: (dialogCtx) => AlertDialog(
																							title: const Text('Error al capturar firma'),
																							content: const Text('No se pudo capturar la firma. Limpiá el recuadro e intentá de nuevo.'),
																							actions: [
																								TextButton(
																									onPressed: () => Navigator.of(dialogCtx).pop(),
																									child: const Text('Aceptar'),
																								),
																							],
																						),
																					);
																					return;
																				}
																			}

																	context.read<ServicioBloc>().add(
																		ServicioDocumentoSubidaSolicitada(
																			servicioId: orden.servicioId,
																			orden: orden,
																			canal: canal,
																			pdfBytes: pdfBytes,
																					firmaClienteTrazoPng: firmaTrazoPng,
																			nombreArchivoPdf: nombreArchivo,
																			rutaPdfLocal:
																					'memoria://ordenes/$nombreArchivo',
																			firmaClienteNombre: agregarFirma
																					? nombreFirma
																					: null,
																			firmaClienteDocumento: agregarFirma
																									? documentoFirmante.trim()
																					: null,
																			firmaFechaHora: agregarFirma ? firmaFechaHora : null,
																		),
																	);
																	Navigator.of(sheetContext).pop();
																},
															icon: estadoFormulario.subiendoDocumento
																	? const SizedBox(
																		height: 16,
																		width: 16,
																		child: CircularProgressIndicator(strokeWidth: 2),
																	)
																	: const Icon(Icons.cloud_upload_outlined),
															label: const Text('Subir PDF y cerrar orden'),
														),
													),
													if (estadoFormulario.documentosPendientes > 0) ...[
														const SizedBox(height: 8),
														SizedBox(
															width: double.infinity,
															child: OutlinedButton.icon(
																onPressed: estadoFormulario.subiendoDocumento
																	? null
																	: () {
																		context.read<ServicioBloc>().add(
																			const ServicioDocumentoPendientesReintentarSolicitado(),
																		);
																	},
																icon: const Icon(Icons.refresh),
																label: Text(
																	'Reintentar pendientes (${estadoFormulario.documentosPendientes})',
																),
															),
														),
													],
												],
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

					final orden = state.ordenActual;
					final pdfBytes = state.pdfOrdenBytes;
					if (orden != null && pdfBytes != null && pdfBytes.isNotEmpty) {
						if (_ultimoServicioConFlujoDocumento != orden.servicioId) {
							_ultimoServicioConFlujoDocumento = orden.servicioId;
							_limpiarFormularioVisual();
							final pdfNombre =
									state.pdfOrdenNombre ?? 'orden_servicio_${orden.servicioId}.pdf';
							_mostrarFlujoDocumentoCierre(
								context: context,
								orden: orden,
								pdfBytes: pdfBytes,
								nombreArchivo: pdfNombre,
							);
						}
					}
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
				final clienteSeleccionado = estadoFormulario.clienteSeleccionado;
				if (clienteSeleccionado != null &&
						_clienteSeleccionadoVisualId != clienteSeleccionado.id) {
					final etiquetaCliente = _etiquetaClienteSeleccionado(clienteSeleccionado);
					_buscarClienteController.value = TextEditingValue(
						text: etiquetaCliente,
						selection: TextSelection.collapsed(offset: etiquetaCliente.length),
					);
					_clienteSeleccionadoVisualId = clienteSeleccionado.id;
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
													_buildZonaVisual(
														context: context,
																																																												titulo: '1. Tipo de orden',
																																																												icono: Icons.flag_outlined,
																																																												child: _buildZonaTipoOrden(
																																																													context: context,
																																																													estadoFormulario: estadoFormulario,
																																																												),
																																																											),
																																																											const SizedBox(height: 12),
																																																											_buildZonaVisual(
																																																												context: context,
																																																												titulo: '2. Datos de la orden y equipo',
																																																												icono: Icons.assignment_ind_outlined,
																																																												child: _buildZonaDatosOrdenEquipo(
															context: context,
															estadoFormulario: estadoFormulario,
															catalogos: catalogos,
															indicadoresActivos: indicadoresActivos,
														),
													),
													const SizedBox(height: 12),
													_buildZonaVisual(
														context: context,
																																																												titulo: '3. Falla, diagnostico y resolucion',
														icono: Icons.build_circle_outlined,
														child: _buildZonaFallaDiagnosticoResolucion(
															context: context,
															estadoFormulario: estadoFormulario,
															catalogos: catalogos,
															productosCategoriaFalla: productosCategoriaFalla,
															resolucionLabel: resolucionLabel,
														),
													),
													const SizedBox(height: 12),
													_buildSeccionFacturacion(context, estadoFormulario),
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
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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

	Widget _buildZonaTipoOrden({
		required BuildContext context,
		required ServicioFormularioState estadoFormulario,
	}) {
		final tipoSeleccionado = _labelTipoOrdenSeleccionado(estadoFormulario.canal);
		final fechaHora = estadoFormulario.fechaHoraServicio;
		final fechaHoraTexto = fechaHora == null
				? 'Sin fecha'
				: _formatearFechaHora(fechaHora);

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Row(
					children: [
						Expanded(
							child: Text(
								'Tipo seleccionado: $tipoSeleccionado',
								style: Theme.of(context).textTheme.titleSmall,
							),
						),
						Text(
							'Fecha y hora: $fechaHoraTexto',
							style: _estiloTextoCompacto(context),
							textAlign: TextAlign.right,
						),
					],
				),
				const SizedBox(height: 10),
				SingleChildScrollView(
					scrollDirection: Axis.horizontal,
					child: Row(
						children: Canal.values.map((canal) {
							return Padding(
								padding: const EdgeInsets.only(right: 8),
								child: ChoiceChip(
									visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
									materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
									labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
									padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
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
			],
		);
	}

	String _labelTipoOrdenSeleccionado(Canal? canal) {
		if (canal == null) {
			return 'Sin seleccionar';
		}
		return canal.name;
	}

	Widget _buildZonaVisual({
		required BuildContext context,
		required String titulo,
		required IconData icono,
		required Widget child,
	}) {
		final colorScheme = Theme.of(context).colorScheme;
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
			decoration: BoxDecoration(
				color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.16),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: colorScheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Icon(icono, size: 16),
							const SizedBox(width: 8),
							Text(
								titulo,
								style: Theme.of(context).textTheme.titleSmall?.copyWith(
									fontWeight: FontWeight.w700,
								),
							),
						],
					),
					const SizedBox(height: 10),
					child,
				],
			),
		);
	}

	Widget _buildZonaDatosOrdenEquipo({
		required BuildContext context,
		required ServicioFormularioState estadoFormulario,
		required CatalogoLoaded catalogos,
		required List<Producto> indicadoresActivos,
	}) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const SizedBox(height: 4),
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
				if (estadoFormulario.clienteSeleccionado != null) ...[
					const SizedBox(height: 10),
					_buildResumenClienteSeleccionado(
						context: context,
						cliente: estadoFormulario.clienteSeleccionado!,
					),
				],
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
				Text(
					'Equipo modelo y numero de serie',
					style: Theme.of(context).textTheme.titleSmall,
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
			],
		);
	}

	Widget _buildResumenClienteSeleccionado({
		required BuildContext context,
		required Cliente cliente,
	}) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(10),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Datos del cliente seleccionado',
						style: Theme.of(context).textTheme.titleSmall,
					),
					const SizedBox(height: 8),
					_filaDosCampos(
						izquierda: _buildCampoSoloLectura(
							context,
							label: 'Nombre',
							value: _textoClienteDetalle(cliente.nombre),
						),
						derecha: _buildCampoSoloLectura(
							context,
							label: 'CUIT',
							value: _textoClienteDetalle(cliente.cuit),
						),
					),
					const SizedBox(height: 8),
					_filaDosCampos(
						izquierda: _buildCampoSoloLectura(
							context,
							label: 'Contacto',
							value: _textoClienteDetalle(cliente.contacto),
						),
						derecha: _buildCampoSoloLectura(
							context,
							label: 'Telefono',
							value: _textoClienteDetalle(cliente.telefono),
						),
					),
					const SizedBox(height: 8),
					_buildCampoSoloLectura(
						context,
						label: 'Localidad',
						value: _textoClienteDetalle(cliente.localidad),
					),
				],
			),
		);
	}

	String _etiquetaClienteSeleccionado(Cliente cliente) {
		final nombre = _textoClienteDetalle(cliente.nombre, fallback: 'Cliente sin nombre');
		final cuit = (cliente.cuit ?? '').trim();
		if (cuit.isEmpty) {
			return nombre;
		}
		return '$nombre ($cuit)';
	}

	String _textoClienteDetalle(String? valor, {String fallback = 'No informado'}) {
		final normalizado = (valor ?? '').trim();
		return normalizado.isEmpty ? fallback : normalizado;
	}

	Widget _buildZonaFallaDiagnosticoResolucion({
		required BuildContext context,
		required ServicioFormularioState estadoFormulario,
		required CatalogoLoaded catalogos,
		required List<Producto> productosCategoriaFalla,
		required String resolucionLabel,
	}) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					'Partes que mostraban falla',
					style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13),
				),
				const SizedBox(height: 8),
				SingleChildScrollView(
					scrollDirection: Axis.horizontal,
					child: Row(
						children: catalogos.categorias
								.where((categoria) => categoria.activo)
								.map((categoria) {
									final seleccionada = _categoriasFallaSeleccionadasIds.contains(categoria.id);
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
								}).toList(),
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
					controller: _sintomaController,
					minLines: 2,
					maxLines: 2,
					style: _estiloTextoCompacto(context),
					decoration: _decoracionCampoCompacta(
						context,
						labelText: 'Escriba los detalles del síntoma',
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
									final seleccionado = estadoFormulario.diagnosticoCatIdsSeleccionados.contains(
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
												final seleccionados = estadoFormulario.diagnosticoCatIdsSeleccionados.toSet();
												if (seleccionar) {
													seleccionados.add(diagnostico.id);
												} else {
													seleccionados.remove(diagnostico.id);
												}
												context.read<ServicioBloc>().add(
														ServicioFormularioCambiado(
															diagnosticoCatIdsSeleccionados: seleccionados.toList(),
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
						labelText: 'Escriba los detalles del diagnóstico',
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
					style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 11),
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
			],
		);
	}

	Widget _buildSeccionFacturacion(
		BuildContext context,
		ServicioFormularioState estado,
	) {
		final anchoPantalla = MediaQuery.sizeOf(context).width;
		final mostrarTablaDetalle = anchoPantalla >= 860;
		final anchosTabla = _resolverAnchosDetalleFacturado(anchoPantalla);
		final kmCantidad = _doubleDesdeTextoLocal(estado.km);
		final hayViatico = kmCantidad > 0;
		final subtotalKmUsdCalculado = kmCantidad * estado.valorKmUsdSnapshot;
		final subtotalKmArsCalculado = subtotalKmUsdCalculado * estado.cotizacionDolarSnapshot;
		final descuentoPorcentaje = _doubleDesdeTextoLocal(estado.descuentoPorcentaje);
		final subtotalBrutoUsd = estado.subtotalKmUsd + estado.subtotalRepuestosUsd;
		final subtotalBrutoArs = estado.subtotalKmArs + estado.subtotalRepuestosArs;
		final descuentoMontoUsd = subtotalBrutoUsd * (descuentoPorcentaje / 100);
		final descuentoMontoArs = subtotalBrutoArs * (descuentoPorcentaje / 100);
		final terminoBusquedaRepuesto = _buscarRepuestoController.text.trim();
		final repuestosMostrados = estado.repuestosDisponibles.take(20).toList();

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.onPrimaryFixed.withValues(alpha: 0.2),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Facturacion (opcional)',
						style: Theme.of(context).textTheme.titleSmall,
					),
					const SizedBox(height: 8),
					if (estado.cargandoFacturacion) ...[
						const LinearProgressIndicator(minHeight: 2),
						const SizedBox(height: 8),
					],
					_filaDosCampos(
						izquierda: _buildCampoSoloLectura(
							context,
							label: 'Cotizacion dolar (servidor)',
							value: _formatearMonto(estado.cotizacionDolarSnapshot),
						),
						derecha: _buildCampoSoloLectura(
							context,
							label: 'Valor km USD (servidor)',
							value: _formatearMonto(estado.valorKmUsdSnapshot),
						),
					),
					const SizedBox(height: 8),
					_filaDosCampos(
						izquierda: Align(
							alignment: Alignment.centerLeft,
							child: Padding(
								padding: const EdgeInsets.only(top: 10),
								child: Text(
									'Calculo km: ${_formatearCantidad(kmCantidad)} x ${_formatearMonto(estado.valorKmUsdSnapshot)} USD = ${_formatearMonto(subtotalKmUsdCalculado)} USD / ${_formatearMonto(subtotalKmArsCalculado)} ARS',
									style: _estiloTextoCompacto(context),
								),
							),
						),
						derecha: TextField(
							controller: _kmController,
							keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
					),
					const SizedBox(height: 10),
					TextField(
						controller: _buscarRepuestoController,
						onChanged: (_) => setState(() {}),
						decoration: _decoracionCampoCompacta(
							context,
							labelText: 'Buscar repuesto (codigo o nombre)',
							suffixIcon: estado.buscandoRepuestos
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
													ServicioBuscarRepuestosSolicitado(
														query: _buscarRepuestoController.text,
													),
											);
										},
										icon: const Icon(Icons.search),
									),
						),
						onSubmitted: (valor) {
							context.read<ServicioBloc>().add(
									ServicioBuscarRepuestosSolicitado(query: valor.trim()),
							);
						},
					),
					if (terminoBusquedaRepuesto.isNotEmpty && repuestosMostrados.isNotEmpty) ...[
						const SizedBox(height: 8),
						SingleChildScrollView(
							scrollDirection: Axis.horizontal,
							child: Row(
								children: repuestosMostrados.map((repuesto) {
									final yaAgregado = estado.repuestosSeleccionados.any(
										(item) => item.repuesto.id == repuesto.id,
									);
									return Padding(
										padding: const EdgeInsets.only(right: 8),
										child: ActionChip(
											label: Text(
												'${repuesto.codigo} - ${repuesto.nombre} (${_formatearMonto(repuesto.precioUsd)} USD)',
												style: _estiloTextoCompacto(context),
											),
											onPressed: yaAgregado
													? null
													: () {
														context.read<ServicioBloc>().add(
																ServicioRepuestoAgregado(repuesto: repuesto),
														);
													},
										),
									);
								}).toList(),
							),
						),
					],
					if (terminoBusquedaRepuesto.isNotEmpty &&
							!estado.buscandoRepuestos &&
							repuestosMostrados.isEmpty) ...[
						const SizedBox(height: 8),
						Text(
							'No hay coincidencias para "$terminoBusquedaRepuesto".',
							style: _estiloTextoCompacto(context),
						),
					],
					const SizedBox(height: 10),
					Text(
						'Detalle facturado',
						style: Theme.of(context).textTheme.titleSmall,
					),
					const SizedBox(height: 6),
					if (mostrarTablaDetalle)
						_buildDetalleFacturadoTabla(
							context: context,
							estado: estado,
							hayViatico: hayViatico,
							kmCantidad: kmCantidad,
							subtotalKmArsCalculado: subtotalKmArsCalculado,
							anchos: anchosTabla,
						)
					else
						_buildDetalleFacturadoCompacto(
							context: context,
							estado: estado,
							hayViatico: hayViatico,
							kmCantidad: kmCantidad,
							subtotalKmArsCalculado: subtotalKmArsCalculado,
						),
					const SizedBox(height: 10),
					const SizedBox(height: 10),
					_buildTablaResumenFacturacion(
						context: context,
						filas: [
							_FilaResumenFacturacion(
								item: 'Subtotal km',
								dolares: estado.subtotalKmUsd,
								pesos: estado.subtotalKmArs,
							),
							_FilaResumenFacturacion(
								item: 'Subtotal repuestos',
								dolares: estado.subtotalRepuestosUsd,
								pesos: estado.subtotalRepuestosArs,
							),
							_FilaResumenFacturacion(
								item: 'Descuento aplicado',
								dolares: -descuentoMontoUsd,
								pesos: -descuentoMontoArs,
								mostrarInputDescuento: true,
								mostrarDolares: false,
							),
							_FilaResumenFacturacion(
								item: 'Subtotal general',
								dolares: estado.subtotalGeneralUsd,
								pesos: estado.subtotalGeneralArs,
							),
							_FilaResumenFacturacion(
								item: 'Total con IVA',
								dolares: 0,
								pesos: estado.totalConIvaArs,
								mostrarInputIva: true,
								mostrarDolares: false,
							),
							_FilaResumenFacturacion(
								item: 'Total final',
								dolares: 0,
								pesos: estado.totalFinalArs,
								esTotal: true,
								mostrarDolares: false,
							),
						],
					),
				],
			),
		);
	}

	Widget _buildDetalleFacturadoTabla({
		required BuildContext context,
		required ServicioFormularioState estado,
		required bool hayViatico,
		required double kmCantidad,
		required double subtotalKmArsCalculado,
		required _DetalleFacturadoAnchos anchos,
	}) {
		return SingleChildScrollView(
			scrollDirection: Axis.horizontal,
			child: ConstrainedBox(
				constraints: BoxConstraints(minWidth: anchos.anchoTotal),
				child: Column(
					children: [
						_buildFilaCabeceraDetalleFacturado(context, anchos: anchos),
						if (hayViatico)
							_buildFilaDetalleFacturado(
								context: context,
								descripcion: 'Viatico por km',
								cantidad: _formatearCantidad(kmCantidad),
								precioUsd: _formatearMonto(estado.valorKmUsdSnapshot),
								subtotalArs: _formatearMonto(subtotalKmArsCalculado),
								anchos: anchos,
							),
						...estado.repuestosSeleccionados.map((item) {
							final subtotalArs =
									item.cantidad * item.repuesto.precioUsd * estado.cotizacionDolarSnapshot;
							return _buildFilaDetalleFacturado(
								context: context,
								descripcion: '${item.repuesto.codigo} - ${item.repuesto.nombre}',
								cantidad: _formatearCantidad(item.cantidad),
								precioUsd: _formatearMonto(item.repuesto.precioUsd),
								subtotalArs: _formatearMonto(subtotalArs),
								cantidadEditable: true,
								repuestoId: item.repuesto.id,
								cantidadInicial: _formatearCantidad(item.cantidad),
								onEliminar: () {
									context.read<ServicioBloc>().add(
											ServicioRepuestoEliminado(repuestoId: item.repuesto.id),
									);
								},
								anchos: anchos,
							);
						}),
						if (!hayViatico && estado.repuestosSeleccionados.isEmpty)
							Container(
								width: anchos.anchoTotal,
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
								decoration: BoxDecoration(
									border: Border(
										left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
										right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
										bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
									),
								),
								child: Text(
									'Sin cargo: no hay km ni repuestos agregados.',
									style: _estiloTextoCompacto(context),
								),
							),
					],
				),
			),
		);
	}

	Widget _buildDetalleFacturadoCompacto({
		required BuildContext context,
		required ServicioFormularioState estado,
		required bool hayViatico,
		required double kmCantidad,
		required double subtotalKmArsCalculado,
	}) {
		if (!hayViatico && estado.repuestosSeleccionados.isEmpty) {
			return Container(
				width: double.infinity,
				padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
				decoration: BoxDecoration(
					borderRadius: BorderRadius.circular(8),
					border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
				),
				child: Text(
					'Sin cargo: no hay km ni repuestos agregados.',
					style: _estiloTextoCompacto(context),
				),
			);
		}

		return Column(
			children: [
				if (hayViatico)
					_buildTarjetaDetalleFacturado(
						context: context,
						descripcion: 'Viatico por km',
						cantidad: _formatearCantidad(kmCantidad),
						precioUsd: _formatearMonto(estado.valorKmUsdSnapshot),
						subtotalArs: _formatearMonto(subtotalKmArsCalculado),
					),
				...estado.repuestosSeleccionados.map((item) {
					final subtotalArs =
							item.cantidad * item.repuesto.precioUsd * estado.cotizacionDolarSnapshot;
					return _buildTarjetaDetalleFacturado(
						context: context,
						descripcion: '${item.repuesto.codigo} - ${item.repuesto.nombre}',
						cantidad: _formatearCantidad(item.cantidad),
						precioUsd: _formatearMonto(item.repuesto.precioUsd),
						subtotalArs: _formatearMonto(subtotalArs),
						cantidadEditable: true,
						repuestoId: item.repuesto.id,
						cantidadInicial: _formatearCantidad(item.cantidad),
						onEliminar: () {
							context.read<ServicioBloc>().add(
									ServicioRepuestoEliminado(repuestoId: item.repuesto.id),
							);
						},
					);
				}),
			],
		);
	}

	Widget _buildCampoSoloLectura(
		BuildContext context, {
		required String label,
		required String value,
	}) {
		return InputDecorator(
			decoration: _decoracionCampoCompacta(context, labelText: label),
			child: Text(value, style: _estiloTextoCompacto(context)),
		);
	}

	Widget _buildTarjetaDetalleFacturado({
		required BuildContext context,
		required String descripcion,
		required String cantidad,
		required String precioUsd,
		required String subtotalArs,
		bool cantidadEditable = false,
		String? repuestoId,
		String? cantidadInicial,
		VoidCallback? onEliminar,
	}) {
		return Container(
			width: double.infinity,
			margin: const EdgeInsets.only(bottom: 8),
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(8),
				border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Text(
									descripcion,
									style: _estiloTextoCompacto(context),
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
							),
							if (cantidadEditable)
								IconButton(
									padding: EdgeInsets.zero,
									visualDensity: VisualDensity.compact,
									onPressed: onEliminar,
									icon: const Icon(Icons.delete_outline, size: 18),
								),
						],
					),
					const SizedBox(height: 8),
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							SizedBox(
								width: 110,
								child: cantidadEditable
										? TextFormField(
												key: ValueKey('cant-mobile-${repuestoId ?? ''}-${cantidadInicial ?? ''}'),
												initialValue: cantidadInicial ?? cantidad,
												keyboardType: const TextInputType.numberWithOptions(decimal: true),
												style: _estiloTextoCompacto(context),
												decoration: const InputDecoration(
													labelText: 'Cantidad',
													isDense: true,
													contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
												),
												onChanged: (valor) {
													if (repuestoId == null) {
														return;
													}
													context.read<ServicioBloc>().add(
															ServicioRepuestoCantidadCambiada(
																repuestoId: repuestoId,
																cantidad: valor,
															),
													);
												},
										)
										: _buildDatoCompactoFacturacion(
												context,
												label: 'Cantidad',
												value: cantidad,
										),
							),
							_buildDatoCompactoFacturacion(
								context,
								label: 'Precio USD',
								value: precioUsd,
							),
							_buildDatoCompactoFacturacion(
								context,
								label: 'Subtotal ARS',
								value: subtotalArs,
							),
						],
					),
				],
			),
		);
	}

	Widget _buildDatoCompactoFacturacion(
		BuildContext context, {
		required String label,
		required String value,
	}) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainer,
				borderRadius: BorderRadius.circular(8),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						label,
						style: _estiloTextoCompacto(context).copyWith(
							fontSize: 11.5,
							color: Theme.of(context).colorScheme.onSurfaceVariant,
						),
					),
					const SizedBox(height: 2),
					Text(
						value,
						style: _estiloTextoCompacto(context).copyWith(fontWeight: FontWeight.w600),
					),
				],
			),
		);
	}

	Widget _buildFilaCabeceraDetalleFacturado(
		BuildContext context, {
		required _DetalleFacturadoAnchos anchos,
	}) {
		final textStyle = _estiloTextoCompacto(context).copyWith(fontWeight: FontWeight.w700);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surfaceContainer,
				border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
			),
			child: Row(
				children: [
					SizedBox(width: anchos.anchoDetalle, child: Text('Detalle', style: textStyle)),
					SizedBox(width: anchos.anchoCantidad, child: Text('Cantidad', style: textStyle)),
					SizedBox(width: anchos.anchoPrecioUsd, child: Text('Precio USD', style: textStyle)),
					SizedBox(width: anchos.anchoSubtotalArs, child: Text('Subtotal ARS', style: textStyle)),
					SizedBox(width: anchos.anchoAcciones),
				],
			),
		);
	}

	Widget _buildFilaDetalleFacturado({
		required BuildContext context,
		required String descripcion,
		required String cantidad,
		required String precioUsd,
		required String subtotalArs,
		required _DetalleFacturadoAnchos anchos,
		bool cantidadEditable = false,
		String? repuestoId,
		String? cantidadInicial,
		VoidCallback? onEliminar,
	}) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				border: Border(
					left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
					right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
					bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
				),
			),
			child: Row(
				children: [
					SizedBox(
						width: anchos.anchoDetalle,
						child: Text(
							descripcion,
							style: _estiloTextoCompacto(context),
							overflow: TextOverflow.ellipsis,
							maxLines: 1,
						),
					),
					SizedBox(
						width: anchos.anchoCantidad,
						child: cantidadEditable
								? TextFormField(
										key: ValueKey('cant-${repuestoId ?? ''}-${cantidadInicial ?? ''}'),
										initialValue: cantidadInicial ?? cantidad,
										keyboardType: const TextInputType.numberWithOptions(decimal: true),
										style: _estiloTextoCompacto(context),
										decoration: const InputDecoration(
											isDense: true,
											contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
										),
										onChanged: (valor) {
											if (repuestoId == null) {
												return;
											}
											context.read<ServicioBloc>().add(
													ServicioRepuestoCantidadCambiada(
														repuestoId: repuestoId,
														cantidad: valor,
													),
											);
										},
								)
								: Text(cantidad, style: _estiloTextoCompacto(context)),
					),
					SizedBox(
						width: anchos.anchoPrecioUsd,
						child: Text(precioUsd, style: _estiloTextoCompacto(context)),
					),
					SizedBox(
						width: anchos.anchoSubtotalArs,
						child: Text(subtotalArs, style: _estiloTextoCompacto(context)),
					),
					SizedBox(
						width: anchos.anchoAcciones,
						child: cantidadEditable
								? IconButton(
										padding: EdgeInsets.zero,
										visualDensity: VisualDensity.compact,
										onPressed: onEliminar,
										icon: const Icon(Icons.delete_outline, size: 18),
								)
								: const SizedBox.shrink(),
					),
				],
			),
		);
	}

	_DetalleFacturadoAnchos _resolverAnchosDetalleFacturado(double anchoPantalla) {
		if (anchoPantalla >= 1200) {
			return const _DetalleFacturadoAnchos(
				anchoDetalle: 360,
				anchoCantidad: 120,
				anchoPrecioUsd: 130,
				anchoSubtotalArs: 130,
				anchoAcciones: 36,
			);
		}
		if (anchoPantalla >= 1000) {
			return const _DetalleFacturadoAnchos(
				anchoDetalle: 330,
				anchoCantidad: 115,
				anchoPrecioUsd: 120,
				anchoSubtotalArs: 120,
				anchoAcciones: 34,
			);
		}
		return const _DetalleFacturadoAnchos(
			anchoDetalle: 300,
			anchoCantidad: 110,
			anchoPrecioUsd: 115,
			anchoSubtotalArs: 115,
			anchoAcciones: 32,
		);
	}

	Widget _buildTablaResumenFacturacion({
		required BuildContext context,
		required List<_FilaResumenFacturacion> filas,
	}) {
		final borderColor = Theme.of(context).colorScheme.outlineVariant;
		final headerStyle = _estiloTextoCompacto(context).copyWith(fontWeight: FontWeight.w700);

		return Container(
			width: double.infinity,
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(8),
				border: Border.all(color: borderColor),
			),
			child: Column(
				children: [
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
						decoration: BoxDecoration(
							color: Theme.of(context).colorScheme.surfaceContainer,
							borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
						),
						child: Row(
							children: [
								Expanded(flex: 5, child: Text('Item', style: headerStyle)),
								Expanded(
									flex: 3,
									child: Text('Dolares / %', style: headerStyle, textAlign: TextAlign.right),
								),
								Expanded(
									flex: 3,
									child: Text('Pesos', style: headerStyle, textAlign: TextAlign.right),
								),
							],
						),
					),
					...filas.asMap().entries.map((entry) {
						final index = entry.key;
						final fila = entry.value;
						final esUltima = index == filas.length - 1;
						final textStyle = _estiloTextoCompacto(context).copyWith(
							fontWeight: fila.esTotal ? FontWeight.w700 : FontWeight.w500,
						);

						return Container(
							padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
							decoration: BoxDecoration(
								color: fila.esTotal
										? Theme.of(context).colorScheme.primary.withValues(alpha: 0.07)
										: null,
								border: esUltima
										? null
										: Border(bottom: BorderSide(color: borderColor)),
							),
							child: Row(
								children: [
									Expanded(flex: 5, child: Text(fila.item, style: textStyle)),
									Expanded(
										flex: 3,
										child: fila.mostrarInputIva
												? SizedBox(
													width: 72,
													child: TextField(
														controller: _ivaController,
														keyboardType: const TextInputType.numberWithOptions(decimal: true),
														textAlign: TextAlign.right,
														style: _estiloTextoCompacto(context),
														decoration: const InputDecoration(
															isDense: true,
															labelText: 'IVA %',
															contentPadding: EdgeInsets.symmetric(
																horizontal: 8,
																vertical: 5,
															),
														),
														onChanged: (valor) {
															context.read<ServicioBloc>().add(
																	ServicioFacturacionParametrosCambiados(ivaPorcentaje: valor),
															);
														},
													),
												)
												: fila.mostrarInputDescuento
														? SizedBox(
															width: 80,
															child: TextField(
																controller: _descuentoController,
																keyboardType: const TextInputType.numberWithOptions(decimal: true),
																textAlign: TextAlign.right,
																style: _estiloTextoCompacto(context),
																decoration: const InputDecoration(
																	isDense: true,
																	labelText: 'Desc %',
																	contentPadding: EdgeInsets.symmetric(
																		horizontal: 8,
																		vertical: 5,
																	),
																),
																onChanged: (valor) {
																	context.read<ServicioBloc>().add(
																			ServicioFacturacionParametrosCambiados(descuentoPorcentaje: valor),
																	);
																},
															),
														)
												: Text(
													fila.mostrarDolares ? _formatearMonto(fila.dolares) : '',
													style: textStyle,
													textAlign: TextAlign.right,
												),
									),
									Expanded(
										flex: 3,
										child: Text(
											_formatearMonto(fila.pesos),
											style: textStyle,
											textAlign: TextAlign.right,
										),
									),
								],
							),
						);
					}),
				],
			),
		);
	}

	double _doubleDesdeTextoLocal(String valor) {
		final normalizado = valor.trim().replaceAll(',', '.');
		if (normalizado.isEmpty) {
			return 0;
		}
		return double.tryParse(normalizado) ?? 0;
	}

	String _formatearMonto(double valor) {
		return valor.toStringAsFixed(2);
	}

	String _formatearCantidad(double valor) {
		if (valor == valor.roundToDouble()) {
			return valor.toStringAsFixed(0);
		}
		return valor.toStringAsFixed(2);
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
				initialValue: _modeloIndicadorSeleccionadoId,
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
			initialValue: estado.lugarProvinciaId.isEmpty ? null : estado.lugarProvinciaId,
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

class _DetalleFacturadoAnchos {
	final double anchoDetalle;
	final double anchoCantidad;
	final double anchoPrecioUsd;
	final double anchoSubtotalArs;
	final double anchoAcciones;

	const _DetalleFacturadoAnchos({
		required this.anchoDetalle,
		required this.anchoCantidad,
		required this.anchoPrecioUsd,
		required this.anchoSubtotalArs,
		required this.anchoAcciones,
	});

	double get anchoTotal =>
			anchoDetalle + anchoCantidad + anchoPrecioUsd + anchoSubtotalArs + anchoAcciones;
}

class _FilaResumenFacturacion {
	final String item;
	final double dolares;
	final double pesos;
	final bool esTotal;
	final bool mostrarDolares;
	final bool mostrarInputIva;
	final bool mostrarInputDescuento;

	const _FilaResumenFacturacion({
		required this.item,
		required this.dolares,
		required this.pesos,
		this.esTotal = false,
		this.mostrarDolares = true,
		this.mostrarInputIva = false,
		this.mostrarInputDescuento = false,
	});
}
