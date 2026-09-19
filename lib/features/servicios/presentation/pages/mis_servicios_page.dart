import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/filtro_estado_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

/// Atajo para leer el listado del estado sin repetir el chequeo de tipo.
MisServiciosLoaded? _listado(ServicioState state) {
	return state is MisServiciosLoaded ? state : null;
}

class MisServiciosPage extends StatefulWidget {
	const MisServiciosPage({super.key});

	@override
	State<MisServiciosPage> createState() => _MisServiciosPageState();
}

class _MisServiciosPageState extends State<MisServiciosPage> {
	final TextEditingController _busquedaController = TextEditingController();

	/// Ultima busqueda que el bloc le mostro a esta pantalla.
	String? _ultimaBusquedaDelBloc;

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
			body: MultiBlocListener(
				listeners: [
					// Cada efecto trae un token: si cambio, el pedido es nuevo y hay que
					// atenderlo; si no cambio, el estado se movio por otro motivo.
					BlocListener<ServicioBloc, ServicioState>(
						listenWhen: (anterior, actual) {
							final token = _listado(actual)?.pdfParaAbrir?.token;
							return token != null &&
									token != _listado(anterior)?.pdfParaAbrir?.token;
						},
						listener: (context, state) async {
							final efecto = _listado(state)?.pdfParaAbrir;
							if (efecto == null) {
								return;
							}
							await Printing.layoutPdf(
								name: efecto.nombreArchivo,
								onLayout: (_) async => efecto.bytes,
							);
						},
					),
					BlocListener<ServicioBloc, ServicioState>(
						listenWhen: (anterior, actual) {
							final token = _listado(actual)?.enlacePdfParaCopiar?.token;
							return token != null &&
									token != _listado(anterior)?.enlacePdfParaCopiar?.token;
						},
						listener: (context, state) async {
							final efecto = _listado(state)?.enlacePdfParaCopiar;
							if (efecto == null) {
								return;
							}
							await Clipboard.setData(ClipboardData(text: efecto.enlace));
						},
					),
					BlocListener<ServicioBloc, ServicioState>(
						listenWhen: (anterior, actual) {
							final mensaje = _mensaje(actual);
							return mensaje != null && mensaje != _mensaje(anterior);
						},
						listener: (context, state) {
							final mensaje = _mensaje(state);
							if (mensaje == null) {
								return;
							}
							ScaffoldMessenger.of(context).showSnackBar(
								SnackBar(content: Text(mensaje)),
							);
						},
					),
				],
				child: BlocBuilder<ServicioBloc, ServicioState>(
					builder: _construirCuerpo,
				),
			),
		);
	}

	String? _mensaje(ServicioState state) {
		final mensaje = (_listado(state)?.mensajePendientes ?? '').trim();
		return mensaje.isEmpty ? null : mensaje;
	}

	Widget _construirCuerpo(BuildContext context, ServicioState state) {
		if (state is MisServiciosLoading) {
			return const Center(child: CircularProgressIndicator());
		}

		if (state is ServicioError) {
			return Center(child: Text(state.mensaje));
		}

		if (state is! MisServiciosLoaded) {
			return const SizedBox.shrink();
		}

		// El campo refleja la busqueda que tiene el bloc (se conserva al recargar
		// y al volver a entrar). Solo se escribe cuando el bloc la cambio: si se
		// escribiera en cada rebuild, un emit ajeno llegado entre la tecla y el
		// estado nuevo le borraria al tecnico lo que acaba de tipear.
		if (_ultimaBusquedaDelBloc != state.busqueda) {
			_ultimaBusquedaDelBloc = state.busqueda;
			if (_busquedaController.text != state.busqueda) {
				_busquedaController.text = state.busqueda;
				_busquedaController.selection = TextSelection.fromPosition(
					TextPosition(offset: _busquedaController.text.length),
				);
			}
		}

		final panelPendientes = _PanelPendientesDocumentos(
			documentosPendientes: state.documentosPendientes,
			reintentandoPendientes: state.reintentandoPendientes,
			onReintentar: () {
				context.read<ServicioBloc>().add(
					const ServicioDocumentoPendientesReintentarSolicitado(),
				);
			},
		);

		if (state.servicios.isEmpty) {
			return Column(
				children: [
					panelPendientes,
					const Expanded(
						child: Center(child: Text('No hay servicios cargados.')),
					),
				],
			);
		}

		final serviciosFiltrados = state.serviciosFiltrados;

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
							context.read<ServicioBloc>().add(
								MisServiciosBusquedaCambiada(texto: valor),
							);
						},
					),
				),
				const SizedBox(height: 10),
				_FiltrosEstado(
					filtroSeleccionado: state.filtroEstado,
					onChanged: (filtro) {
						context.read<ServicioBloc>().add(
							MisServiciosFiltroEstadoCambiado(filtro: filtro),
						);
					},
				),
				panelPendientes,
				if (serviciosFiltrados.isEmpty)
					const Expanded(
						child: Center(
							child: Text('No hay servicios para los filtros aplicados.'),
						),
					)
				else ...[
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
									final servicioId = servicio.id.trim();
									return _TarjetaServicio(
										servicio: servicio,
										tienePdf: state.tienePdfDisponible(servicio),
										subiendoPdfAhora: state.servicioIdSubiendoPdf == servicioId,
										descargandoPdf: state.servicioIdDescargandoPdf == servicioId,
										copiandoEnlacePdf:
												state.servicioIdCopiandoEnlacePdf == servicioId,
										onVerPdf: () {
											context.read<ServicioBloc>().add(
												ServicioDocumentoPdfVerSolicitado(servicio: servicio),
											);
										},
										onCopiarEnlacePdf: () {
											context.read<ServicioBloc>().add(
												ServicioDocumentoEnlacePdfCopiarSolicitado(
													servicio: servicio,
												),
											);
										},
										onSubirPdfAhora: () {
											context.read<ServicioBloc>().add(
												ServicioDocumentoSubirAhoraSolicitado(servicio: servicio),
											);
										},
									);
								},
							),
						),
					),
				],
			],
		);
	}
}

class _FiltrosEstado extends StatelessWidget {
	final FiltroEstadoServicio filtroSeleccionado;
	final ValueChanged<FiltroEstadoServicio> onChanged;

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
						selected: filtroSeleccionado == FiltroEstadoServicio.todos,
						onSelected: (_) => onChanged(FiltroEstadoServicio.todos),
					),
					const SizedBox(width: 8),
					ChoiceChip(
						label: const Text('Aprobados'),
						selected: filtroSeleccionado == FiltroEstadoServicio.aprobados,
						onSelected: (_) => onChanged(FiltroEstadoServicio.aprobados),
					),
					const SizedBox(width: 8),
					ChoiceChip(
						label: const Text('Pendientes'),
						selected: filtroSeleccionado == FiltroEstadoServicio.pendientes,
						onSelected: (_) => onChanged(FiltroEstadoServicio.pendientes),
					),
				],
			),
		);
	}
}

class _TarjetaServicio extends StatelessWidget {
	final Servicio servicio;
	final bool tienePdf;
	final bool subiendoPdfAhora;
	final bool descargandoPdf;
	final bool copiandoEnlacePdf;
	final VoidCallback onVerPdf;
	final VoidCallback onCopiarEnlacePdf;
	final VoidCallback onSubirPdfAhora;

	const _TarjetaServicio({
		required this.servicio,
		required this.tienePdf,
		required this.subiendoPdfAhora,
		required this.descargandoPdf,
		required this.copiandoEnlacePdf,
		required this.onVerPdf,
		required this.onCopiarEnlacePdf,
		required this.onSubirPdfAhora,
	});

	@override
	Widget build(BuildContext context) {
		final estadoVisual = _resolverEstadoVisual(servicio);
		final fechaOrden = servicio.fechaHoraServicio ?? servicio.fecha;
		final fecha = fechaOrden == null ? 'Sin fecha informada' : _formatearFecha(fechaOrden);
		final nombreFirmante = (servicio.documento?.firmaClienteNombre ?? '').trim();
		final nombreCliente = _resolverNombreCliente(servicio);
		final kmTexto = servicio.km > 0 ? '${servicio.km}' : 'No informado';

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
							'Cliente: $nombreCliente',
							style: TextStyle(
								color: Theme.of(context).colorScheme.onSurfaceVariant,
								fontSize: 12,
							),
						),
						const SizedBox(height: 6),
						Text(
							'Modelo: ${servicio.equipoModelo} | Serie: ${servicio.equipoNroSerie} | Km: $kmTexto',
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
						const SizedBox(height: 8),
						if (tienePdf)
							Wrap(
								spacing: 8,
								runSpacing: 8,
								children: [
									OutlinedButton.icon(
										onPressed: descargandoPdf ? null : onVerPdf,
										icon: descargandoPdf
												? const SizedBox(
													height: 14,
													width: 14,
													child: CircularProgressIndicator(strokeWidth: 2),
												)
												: const Icon(Icons.picture_as_pdf_outlined),
										label: Text(
											descargandoPdf ? 'Abriendo PDF...' : 'Ver / Guardar PDF',
										),
									),
									OutlinedButton.icon(
										onPressed: copiandoEnlacePdf ? null : onCopiarEnlacePdf,
										icon: copiandoEnlacePdf
												? const SizedBox(
													height: 14,
													width: 14,
													child: CircularProgressIndicator(strokeWidth: 2),
												)
												: const Icon(Icons.link),
										label: Text(
											copiandoEnlacePdf ? 'Copiando...' : 'Copiar enlace',
										),
									),
								],
							)
						else
							Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									OutlinedButton.icon(
										onPressed: subiendoPdfAhora ? null : onSubirPdfAhora,
										icon: subiendoPdfAhora
												? const SizedBox(
													height: 14,
													width: 14,
													child: CircularProgressIndicator(strokeWidth: 2),
												)
												: const Icon(Icons.cloud_upload_outlined),
										label: Text(
											subiendoPdfAhora ? 'Subiendo PDF...' : 'Subir PDF ahora',
										),
									),
									const SizedBox(height: 6),
									Text(
										'PDF pendiente de carga.',
										style: TextStyle(
											fontSize: 12,
											color: Theme.of(context).colorScheme.onSurfaceVariant,
										),
									),
								],
							),
						if (nombreFirmante.isNotEmpty) ...[
							const SizedBox(height: 6),
							Text(
								'Firmado por: $nombreFirmante',
								style: TextStyle(
									fontSize: 12,
									color: Theme.of(context).colorScheme.onSurfaceVariant,
								),
							),
						],
					],
				),
			),
		);
	}

	_EstadoServicioVisual _resolverEstadoVisual(Servicio servicio) {
		if (servicio.resuelto) {
			return const _EstadoServicioVisual(
				color: Colors.blue,
				texto: 'Resuelto',
				icono: Icons.task_alt,
			);
		}
		return const _EstadoServicioVisual(
			color: Colors.orange,
			texto: 'En proceso',
			icono: Icons.pending_actions,
		);
	}

	String _resolverNombreCliente(Servicio servicio) {
		final nombre = (servicio.clienteNombre ?? '').trim();
		if (nombre.isNotEmpty) {
			return nombre;
		}

		final contacto = (servicio.clienteContacto ?? '').trim();
		if (contacto.isNotEmpty) {
			return contacto;
		}

		return 'Sin nombre informado';
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

class _PanelPendientesDocumentos extends StatelessWidget {
	final int documentosPendientes;
	final bool reintentandoPendientes;
	final VoidCallback onReintentar;

	const _PanelPendientesDocumentos({
		required this.documentosPendientes,
		required this.reintentandoPendientes,
		required this.onReintentar,
	});

	@override
	Widget build(BuildContext context) {
		final hayPendientes = documentosPendientes > 0;

		return Padding(
			padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
			child: Container(
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
					color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.45),
					borderRadius: BorderRadius.circular(12),
				),
				child: Row(
					children: [
						const Icon(Icons.cloud_off_outlined),
						const SizedBox(width: 10),
						Expanded(
							child: Text(
								hayPendientes
										? 'Documentos pendientes de subida: $documentosPendientes'
										: 'No hay documentos pendientes de subida.',
							),
						),
						const SizedBox(width: 10),
						OutlinedButton.icon(
							onPressed: (!hayPendientes || reintentandoPendientes)
									? null
									: onReintentar,
							icon: reintentandoPendientes
									? const SizedBox(
											height: 14,
											width: 14,
											child: CircularProgressIndicator(strokeWidth: 2),
										)
									: const Icon(Icons.refresh),
							label: Text(
								reintentandoPendientes ? 'Reintentando...' : 'Reintentar',
							),
						),
					],
				),
			),
		);
	}
}


