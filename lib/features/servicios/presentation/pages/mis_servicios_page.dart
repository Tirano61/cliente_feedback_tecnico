import 'dart:convert';
import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/core/auth/secure_storage.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

class MisServiciosPage extends StatefulWidget {
	const MisServiciosPage({super.key});

	@override
	State<MisServiciosPage> createState() => _MisServiciosPageState();
}

class _MisServiciosPageState extends State<MisServiciosPage> {
	FiltroEstado _filtroSeleccionado = FiltroEstado.todos;
	final TextEditingController _busquedaController = TextEditingController();
	String _busquedaTexto = '';
	final Set<String> _serviciosConPdfConfirmado = <String>{};
	final Set<String> _serviciosPdfVerificados = <String>{};
	bool _verificandoPdf = false;

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
			body: BlocConsumer<ServicioBloc, ServicioState>(
				listenWhen: (previous, current) {
					return current is MisServiciosLoaded;
				},
				listener: (context, state) {
					if (state is! MisServiciosLoaded) {
						return;
					}

					_dispararVerificacionPdf(state.servicios);

					final mensaje = (state.mensajePendientes ?? '').trim();
					if (mensaje.isEmpty) {
						return;
					}
					ScaffoldMessenger.of(context).showSnackBar(
						SnackBar(content: Text(mensaje)),
					);
				},
				builder: (context, state) {
					if (state is MisServiciosLoading) {
						return const Center(child: CircularProgressIndicator());
					}

					if (state is ServicioError) {
						return Center(child: Text(state.mensaje));
					}

					if (state is MisServiciosLoaded) {
						final serviciosFiltrados = _filtrarServicios(state.servicios);

						if (state.servicios.isEmpty) {
							return Column(
								children: [
									_PanelPendientesDocumentos(
										documentosPendientes: state.documentosPendientes,
										reintentandoPendientes: state.reintentandoPendientes,
										onReintentar: () {
											context.read<ServicioBloc>().add(
												const ServicioDocumentoPendientesReintentarSolicitado(),
											);
										},
									),
									const Expanded(
										child: Center(child: Text('No hay servicios cargados.')),
									),
								],
							);
						}

						if (serviciosFiltrados.isEmpty) {
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
												setState(() {
													_busquedaTexto = valor;
												});
											},
										),
									),
									const SizedBox(height: 10),
									_FiltrosEstado(
										filtroSeleccionado: _filtroSeleccionado,
										onChanged: (filtro) {
											setState(() => _filtroSeleccionado = filtro);
										},
									),
									_PanelPendientesDocumentos(
										documentosPendientes: state.documentosPendientes,
										reintentandoPendientes: state.reintentandoPendientes,
										onReintentar: () {
											context.read<ServicioBloc>().add(
												const ServicioDocumentoPendientesReintentarSolicitado(),
											);
										},
									),
									const Expanded(
										child: Center(
											child: Text('No hay servicios para los filtros aplicados.'),
										),
									),
								],
							);
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
											labelText: 'Buscar por sintoma, modelo, serie o ID',
										),
										onChanged: (valor) {
											setState(() {
												_busquedaTexto = valor;
											});
										},
									),
								),
								const SizedBox(height: 10),
								_FiltrosEstado(
									filtroSeleccionado: _filtroSeleccionado,
									onChanged: (filtro) {
										setState(() => _filtroSeleccionado = filtro);
									},
								),
								_PanelPendientesDocumentos(
									documentosPendientes: state.documentosPendientes,
									reintentandoPendientes: state.reintentandoPendientes,
									onReintentar: () {
										context.read<ServicioBloc>().add(
											const ServicioDocumentoPendientesReintentarSolicitado(),
										);
									},
								),
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
												final subiendoPdfAhora =
														state.servicioIdSubiendoPdf == servicio.id;
												final pdfConfirmadoServidor = _serviciosConPdfConfirmado
														.contains(servicio.id.trim());
												return _TarjetaServicio(
													servicio: servicio,
													onVerPdf: () => _verPdfServicio(servicio),
													onCopiarEnlacePdf: () => _copiarEnlacePdf(servicio),
													onSubirPdfAhora: () {
														context.read<ServicioBloc>().add(
															ServicioDocumentoSubirAhoraSolicitado(servicio: servicio),
														);
													},
													subiendoPdfAhora: subiendoPdfAhora,
													pdfConfirmadoServidor: pdfConfirmadoServidor,
												);
											},
										),
									),
								),
							],
						);
					}

					return const SizedBox.shrink();
				},
			),
		);
	}

	Future<void> _dispararVerificacionPdf(List<Servicio> servicios) async {
		if (_verificandoPdf) {
			return;
		}

		final candidatos = servicios.where((servicio) {
			final servicioId = servicio.id.trim();
			if (servicioId.isEmpty) {
				return false;
			}
			if (_serviciosPdfVerificados.contains(servicioId)) {
				return false;
			}
			if (_tieneDocumentoEnListado(servicio)) {
				return false;
			}
			return true;
		}).take(20).toList();

		if (candidatos.isEmpty) {
			return;
		}

		_verificandoPdf = true;
		try {
			final token = (await SecureStorage().obtenerToken() ?? '').trim();
			if (token.isEmpty) {
				return;
			}

			final futuros = candidatos.map((servicio) async {
				final servicioId = servicio.id.trim();
				try {
					final metadataEndpoint =
							'${ApiConstants.baseUrl}${ApiConstants.servicioDocumento(servicioId)}';
					final response = await http.get(
						Uri.parse(metadataEndpoint),
						headers: {'Authorization': 'Bearer $token'},
					);

					if (response.statusCode == 200) {
						final dynamic payload = jsonDecode(response.body);
						final documento = _extraerDocumentoDesdePayload(payload);
						final bruto = _extraerPdfUrlDesdeDocumento(documento);
						final pdfUrl = _normalizarUrlPdf(bruto);
						if ((pdfUrl ?? '').trim().isNotEmpty && mounted) {
							setState(() {
								_serviciosConPdfConfirmado.add(servicioId);
							});
						}
					}
				} catch (_) {
					// Ignorar errores puntuales; se reintentara con recarga de pantalla.
				} finally {
					_serviciosPdfVerificados.add(servicioId);
				}
			});

			await Future.wait(futuros);
		} finally {
			_verificandoPdf = false;
		}
	}

	bool _tieneDocumentoEnListado(Servicio servicio) {
		final documento = servicio.documento;
		if (documento == null) {
			return false;
		}

		final pdfUrl = (documento.pdfUrl ?? '').trim();
		if (pdfUrl.isNotEmpty) {
			return true;
		}

		final pdfHash = (documento.pdfHashSha256 ?? '').trim();
		if (pdfHash.isNotEmpty) {
			return true;
		}

		final firmaNombre = (documento.firmaClienteNombre ?? '').trim();
		final firmaDocumento = (documento.firmaClienteDocumento ?? '').trim();
		final firmaFecha = documento.firmaFechaHora;

		return firmaNombre.isNotEmpty || firmaDocumento.isNotEmpty || firmaFecha != null;
	}

	Future<void> _verPdfServicio(Servicio servicio) async {
		final servicioId = servicio.id.trim();
		if (servicioId.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Servicio invalido para abrir PDF.')),
			);
			return;
		}

		try {
			final token = (await SecureStorage().obtenerToken() ?? '').trim();
			if (token.isEmpty) {
				if (!mounted) {
					return;
				}
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('No hay sesion activa para descargar el PDF.')),
				);
				return;
			}

			final pdfEndpoint =
					'${ApiConstants.baseUrl}${ApiConstants.servicioDocumentoPdf(servicioId)}';
			final response = await http.get(
				Uri.parse(pdfEndpoint),
				headers: {'Authorization': 'Bearer $token'},
			);

			if (!mounted) {
				return;
			}
			if (response.statusCode == 404 || response.statusCode == 400) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Esta orden aun no tiene PDF disponible.')),
				);
				return;
			}
			if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(
							'No se pudo descargar el PDF de la orden (HTTP ${response.statusCode}).',
						),
					),
				);
				return;
			}

			final bytes = Uint8List.fromList(response.bodyBytes);
			final nombreArchivo =
					'orden_servicio_${servicio.id.trim().isEmpty ? 'sin_id' : servicio.id.trim()}.pdf';
			await Printing.layoutPdf(
				name: nombreArchivo,
				onLayout: (_) async => bytes,
			);
		} catch (_) {
			if (!mounted) {
				return;
			}
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Error al abrir el PDF. Intenta nuevamente.')),
			);
		}
	}

	Future<void> _copiarEnlacePdf(Servicio servicio) async {
		final servicioId = servicio.id.trim();
		if (servicioId.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Servicio invalido para obtener enlace PDF.')),
			);
			return;
		}

		final token = (await SecureStorage().obtenerToken() ?? '').trim();
		if (token.isEmpty) {
			if (!mounted) {
				return;
			}
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('No hay sesion activa para obtener enlace PDF.')),
			);
			return;
		}

		try {
			final metadataEndpoint =
					'${ApiConstants.baseUrl}${ApiConstants.servicioDocumento(servicioId)}';
			final response = await http.get(
				Uri.parse(metadataEndpoint),
				headers: {'Authorization': 'Bearer $token'},
			);

			if (response.statusCode == 404 || response.statusCode == 400) {
				if (!mounted) {
					return;
				}
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Esta orden aun no tiene enlace PDF.')),
				);
				return;
			}

			if (response.statusCode != 200) {
				if (!mounted) {
					return;
				}
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text(
							'No se pudo obtener el enlace PDF (HTTP ${response.statusCode}).',
						),
					),
				);
				return;
			}

			final dynamic payload = jsonDecode(response.body);
			final documento = _extraerDocumentoDesdePayload(payload);
			final bruto = _extraerPdfUrlDesdeDocumento(documento);
			final pdfUrl = _normalizarUrlPdf(bruto);

			if ((pdfUrl ?? '').trim().isEmpty) {
				if (!mounted) {
					return;
				}
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Esta orden aun no tiene enlace PDF.')),
				);
				return;
			}

			await Clipboard.setData(ClipboardData(text: pdfUrl!));
			if (!mounted) {
				return;
			}
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Enlace del PDF copiado. Ya podes compartirlo.')),
			);
		} catch (_) {
			if (!mounted) {
				return;
			}
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Error al obtener enlace PDF. Intenta nuevamente.')),
			);
		}
	}

	Map<String, dynamic>? _extraerDocumentoDesdePayload(dynamic payload) {
		if (payload is! Map<String, dynamic>) {
			return null;
		}

		final documentoDirecto = payload['documento'];
		if (documentoDirecto is Map<String, dynamic>) {
			return documentoDirecto;
		}

		final data = payload['data'];
		if (data is Map<String, dynamic>) {
			final documentoData = data['documento'];
			if (documentoData is Map<String, dynamic>) {
				return documentoData;
			}
		}

		final servicioPayload = payload['servicio'];
		if (servicioPayload is Map<String, dynamic>) {
			final documentoServicio = servicioPayload['documento'];
			if (documentoServicio is Map<String, dynamic>) {
				return documentoServicio;
			}
		}

		return null;
	}

	String? _extraerPdfUrlDesdeDocumento(Map<String, dynamic>? documento) {
		if (documento == null) {
			return null;
		}

		for (final clave in const [
			'pdfUrl',
			'pdf_url',
			'pdfPublicUrl',
			'pdf_public_url',
			'url',
			'secure_url',
		]) {
			final valor = documento[clave];
			if (valor == null) {
				continue;
			}
			final texto = valor.toString().trim();
			if (texto.isNotEmpty) {
				return texto;
			}
		}

		final pdf = documento['pdf'];
		if (pdf is Map<String, dynamic>) {
			for (final clave in const ['url', 'secure_url', 'pdfUrl', 'pdf_url']) {
				final valor = pdf[clave];
				if (valor == null) {
					continue;
				}
				final texto = valor.toString().trim();
				if (texto.isNotEmpty) {
					return texto;
				}
			}
		}

		return null;
	}

	String? _normalizarUrlPdf(String? bruto) {
		final valor = (bruto ?? '').trim();
		if (valor.isEmpty) {
			return null;
		}

		final uriBase = Uri.parse(ApiConstants.baseUrl);
		final origen = '${uriBase.scheme}://${uriBase.authority}';
		final prefijoApi = uriBase.path.endsWith('/')
				? uriBase.path.substring(0, uriBase.path.length - 1)
				: uriBase.path;

		if (valor.startsWith('http://') || valor.startsWith('https://')) {
			return valor;
		}
		if (valor.startsWith('//')) {
			return '${uriBase.scheme}:$valor';
		}
		if (valor.startsWith('/api/')) {
			return '$origen$valor';
		}
		if (valor.startsWith('/servicios/')) {
			return '$origen$prefijoApi$valor';
		}

		return uriBase.resolve(valor).toString();
	}

	List<Servicio> _filtrarServicios(List<Servicio> servicios) {
		final texto = _busquedaTexto.trim().toLowerCase();

		final filtrados = servicios.where((servicio) {
			final coincideEstado = switch (_filtroSeleccionado) {
				FiltroEstado.aprobados => servicio.aprobado,
				FiltroEstado.pendientes => !servicio.aprobado,
				FiltroEstado.todos => true,
			};

			if (!coincideEstado) {
				return false;
			}

			if (texto.isEmpty) {
				return true;
			}

			return servicio.sintoma.toLowerCase().contains(texto) ||
					servicio.equipoModelo.toLowerCase().contains(texto) ||
					servicio.equipoNroSerie.toLowerCase().contains(texto) ||
					servicio.id.toLowerCase().contains(texto);
		}).toList();

		filtrados.sort((a, b) {
			final fechaA = a.fechaHoraServicio ?? a.fecha;
			final fechaB = b.fechaHoraServicio ?? b.fecha;
			if (fechaA == null && fechaB == null) {
				return 0;
			}
			if (fechaA == null) {
				return 1;
			}
			if (fechaB == null) {
				return -1;
			}
			return fechaB.compareTo(fechaA);
		});

		return filtrados;
	}
}

enum FiltroEstado { todos, aprobados, pendientes }

class _FiltrosEstado extends StatelessWidget {
	final FiltroEstado filtroSeleccionado;
	final ValueChanged<FiltroEstado> onChanged;

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
						selected: filtroSeleccionado == FiltroEstado.todos,
						onSelected: (_) => onChanged(FiltroEstado.todos),
					),
					const SizedBox(width: 8),
					ChoiceChip(
						label: const Text('Aprobados'),
						selected: filtroSeleccionado == FiltroEstado.aprobados,
						onSelected: (_) => onChanged(FiltroEstado.aprobados),
					),
					const SizedBox(width: 8),
					ChoiceChip(
						label: const Text('Pendientes'),
						selected: filtroSeleccionado == FiltroEstado.pendientes,
						onSelected: (_) => onChanged(FiltroEstado.pendientes),
					),
				],
			),
		);
	}
}

class _TarjetaServicio extends StatelessWidget {
	final Servicio servicio;
	final VoidCallback onVerPdf;
	final VoidCallback onCopiarEnlacePdf;
	final VoidCallback onSubirPdfAhora;
	final bool subiendoPdfAhora;
	final bool pdfConfirmadoServidor;

	const _TarjetaServicio({
		required this.servicio,
		required this.onVerPdf,
		required this.onCopiarEnlacePdf,
		required this.onSubirPdfAhora,
		required this.subiendoPdfAhora,
		required this.pdfConfirmadoServidor,
	});

	@override
	Widget build(BuildContext context) {
		final estadoVisual = _resolverEstadoVisual(servicio);
		final fechaOrden = servicio.fechaHoraServicio ?? servicio.fecha;
		final fecha = fechaOrden == null ? 'Sin fecha informada' : _formatearFecha(fechaOrden);
		final tienePdf = _tieneDocumentoSubido(servicio) || pdfConfirmadoServidor;
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
										onPressed: onVerPdf,
										icon: const Icon(Icons.picture_as_pdf_outlined),
										label: const Text('Ver / Guardar PDF'),
									),
									OutlinedButton.icon(
										onPressed: onCopiarEnlacePdf,
										icon: const Icon(Icons.link),
										label: const Text('Copiar enlace'),
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

	bool _tieneDocumentoSubido(Servicio servicio) {
		final documento = servicio.documento;
		if (documento == null) {
			return false;
		}

		final pdfUrl = (documento.pdfUrl ?? '').trim();
		if (pdfUrl.isNotEmpty) {
			return true;
		}

		final pdfHash = (documento.pdfHashSha256 ?? '').trim();
		if (pdfHash.isNotEmpty) {
			return true;
		}

		final firmaNombre = (documento.firmaClienteNombre ?? '').trim();
		final firmaDocumento = (documento.firmaClienteDocumento ?? '').trim();
		final firmaFecha = documento.firmaFechaHora;

		return firmaNombre.isNotEmpty || firmaDocumento.isNotEmpty || firmaFecha != null;
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


