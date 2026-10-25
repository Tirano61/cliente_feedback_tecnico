import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/ingreso_detalle_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/nuevo_ingreso_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/servicio_fabrica_page.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_ingreso_badge.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_recepcion_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecepcionDetallePage extends StatefulWidget {
	final String recepcionId;

	/// La respuesta del alta: se muestra sin volver a pedirla.
	final Recepcion? recepcionInicial;

	const RecepcionDetallePage({
		required this.recepcionId,
		this.recepcionInicial,
		super.key,
	});

	@override
	State<RecepcionDetallePage> createState() => _RecepcionDetallePageState();
}

class _RecepcionDetallePageState extends State<RecepcionDetallePage> {
	@override
	void initState() {
		super.initState();
		context.read<RecepcionDetalleBloc>().add(
			RecepcionDetalleAbierto(
				recepcionId: widget.recepcionId,
				recepcion: widget.recepcionInicial,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<RecepcionDetalleBloc, RecepcionDetalleState>(
			listenWhen: (anterior, actual) =>
					actual.exitoMensaje != null || actual.errorMensaje != null,
			listener: (context, state) {
				final mensaje = state.exitoMensaje ?? state.errorMensaje;
				if (mensaje == null) {
					return;
				}
				ScaffoldMessenger.of(context)
					..hideCurrentSnackBar()
					..showSnackBar(SnackBar(content: Text(mensaje)));
			},
			builder: (context, state) {
				// Mientras llega la recepcion pedida no se muestra la anterior.
				final recepcion = state.recepcionId == widget.recepcionId ? state.recepcion : null;
				return Scaffold(
					appBar: AppBar(
						title: Text(
							recepcion == null ? 'Recepción' : 'Recepción N° ${recepcion.numero}',
						),
						actions: [
							IconButton(
								onPressed: state.cargando
										? null
										: () {
												context.read<RecepcionDetalleBloc>().add(
													const RecepcionDetalleRefrescado(),
												);
											},
								icon: const Icon(Icons.refresh),
								tooltip: 'Actualizar',
							),
						],
					),
					body: _construirCuerpo(context, state, recepcion),
				);
			},
		);
	}

	Widget _construirCuerpo(
		BuildContext context,
		RecepcionDetalleState state,
		Recepcion? recepcion,
	) {
		if (recepcion == null) {
			final errorCarga = state.errorCarga;
			if (errorCarga != null && !state.cargando) {
				return Center(
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 24),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Text(errorCarga, textAlign: TextAlign.center),
								const SizedBox(height: 12),
								OutlinedButton.icon(
									onPressed: () {
										context.read<RecepcionDetalleBloc>().add(
											RecepcionDetalleAbierto(recepcionId: widget.recepcionId),
										);
									},
									icon: const Icon(Icons.refresh),
									label: const Text('Reintentar'),
								),
							],
						),
					),
				);
			}
			return const Center(child: CircularProgressIndicator());
		}

		return Column(
			children: [
				SizedBox(
					height: 4,
					child: state.cargando ? const LinearProgressIndicator() : null,
				),
				Expanded(
					child: RefreshIndicator(
						onRefresh: () async {
							context.read<RecepcionDetalleBloc>().add(const RecepcionDetalleRefrescado());
						},
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								_Encabezado(recepcion: recepcion, dias: state.diasEnFabrica),
								const SizedBox(height: 12),
								_SeccionAcciones(state: state),
								const SizedBox(height: 12),
								_SeccionServicio(state: state),
								const SizedBox(height: 12),
								_SeccionDatos(recepcion: recepcion),
								const SizedBox(height: 12),
								_SeccionHistorial(historial: recepcion.historialEstados),
								const SizedBox(height: 12),
								_SeccionPiezasInstaladas(piezas: recepcion.piezasInstaladas),
								const SizedBox(height: 12),
								_SeccionIngresos(state: state, ingresos: recepcion.ingresos),
							],
						),
					),
				),
			],
		);
	}
}

class _Encabezado extends StatelessWidget {
	final Recepcion recepcion;
	final int? dias;

	const _Encabezado({required this.recepcion, required this.dias});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(14),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Expanded(
									child: Text(
										recepcion.cliente.nombre,
										style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
									),
								),
								const SizedBox(width: 8),
								EstadoRecepcionBadge(estado: recepcion.estado),
							],
						),
						const SizedBox(height: 6),
						Text('Indicador ${recepcion.indicador.nroSerie}'),
						const SizedBox(height: 4),
						Text(textoDiasEnFabrica(dias), style: textTheme.bodySmall),
					],
				),
			),
		);
	}
}

class _SeccionAcciones extends StatelessWidget {
	final RecepcionDetalleState state;

	const _SeccionAcciones({required this.state});

	@override
	Widget build(BuildContext context) {
		final acciones = state.accionesEstado;
		if (acciones.isEmpty && !state.puedeDevolver) {
			return const SizedBox.shrink();
		}

		final bloqueos = {
			for (final accion in acciones)
				if (accion.motivoBloqueo != null) accion.motivoBloqueo!,
		};

		return SeccionDetalle(
			titulo: 'Acciones',
			children: [
				Wrap(
					spacing: 8,
					runSpacing: 8,
					children: [
						for (final accion in acciones)
							OutlinedButton.icon(
								onPressed: state.procesandoAccion || !accion.habilitada
										? null
										: () => _confirmarCambioEstado(context, accion),
								icon: state.estadoEnCurso == accion.destino
										? const SizedBox(
												height: 16,
												width: 16,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Icon(Icons.swap_horiz),
								label: Text(accion.etiqueta),
							),
						if (state.puedeDevolver)
							ElevatedButton.icon(
								onPressed: state.procesandoAccion ? null : () => _confirmarDevolucion(context),
								icon: state.devolviendo
										? const SizedBox(
												height: 16,
												width: 16,
												child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
											)
										: const Icon(Icons.local_shipping_outlined),
								label: const Text('Devolver al cliente'),
							),
					],
				),
				for (final motivo in bloqueos)
					Padding(
						padding: const EdgeInsets.only(top: 8),
						child: Text(
							motivo,
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: Theme.of(context).colorScheme.onSurfaceVariant,
									),
						),
					),
			],
		);
	}

	Future<void> _confirmarCambioEstado(BuildContext context, AccionEstadoRecepcion accion) {
		return showDialog<void>(
			context: context,
			builder: (_) => _DialogoCambioEstado(accion: accion),
		);
	}

	Future<void> _confirmarDevolucion(BuildContext context) {
		return showDialog<void>(
			context: context,
			builder: (_) => const _DialogoDevolucion(),
		);
	}
}

/// Cierra el dialogo cuando la accion termina bien. Si el backend la rechaza,
/// queda abierto con lo escrito y el mensaje tal cual.
bool _accionTerminoBien(RecepcionDetalleState anterior, RecepcionDetalleState actual) {
	return anterior.procesandoAccion && !actual.procesandoAccion && actual.errorAccion == null;
}

class _DialogoCambioEstado extends StatefulWidget {
	final AccionEstadoRecepcion accion;

	const _DialogoCambioEstado({required this.accion});

	@override
	State<_DialogoCambioEstado> createState() => _DialogoCambioEstadoState();
}

class _DialogoCambioEstadoState extends State<_DialogoCambioEstado> {
	final TextEditingController _observacionController = TextEditingController();

	@override
	void initState() {
		super.initState();
		context.read<RecepcionDetalleBloc>().add(const RecepcionErrorAccionDescartado());
	}

	@override
	void dispose() {
		_observacionController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<RecepcionDetalleBloc, RecepcionDetalleState>(
			listenWhen: _accionTerminoBien,
			listener: (context, _) => Navigator.of(context).pop(),
			builder: (context, state) {
				return AlertDialog(
					title: Text(widget.accion.etiqueta),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text('Pasa a "${nombreEstadoRecepcion(widget.accion.destino)}".'),
							const SizedBox(height: 12),
							TextField(
								controller: _observacionController,
								enabled: !state.procesandoAccion,
								minLines: 1,
								maxLines: 4,
								decoration: const InputDecoration(labelText: 'Observación (opcional)'),
							),
							ErrorAccionDetalle(mensaje: state.errorAccion),
						],
					),
					actions: [
						TextButton(
							onPressed: state.procesandoAccion ? null : () => Navigator.of(context).pop(),
							child: const Text('Cancelar'),
						),
						ElevatedButton(
							onPressed: state.procesandoAccion
									? null
									: () {
											context.read<RecepcionDetalleBloc>().add(
												RecepcionEstadoCambioSolicitado(
													estado: widget.accion.destino,
													observacion: _observacionController.text,
												),
											);
										},
							child: state.procesandoAccion
									? const SizedBox(
											height: 16,
											width: 16,
											child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
										)
									: const Text('Confirmar'),
						),
					],
				);
			},
		);
	}
}

class _DialogoDevolucion extends StatefulWidget {
	const _DialogoDevolucion();

	@override
	State<_DialogoDevolucion> createState() => _DialogoDevolucionState();
}

class _DialogoDevolucionState extends State<_DialogoDevolucion> {
	final TextEditingController _observacionController = TextEditingController();
	FormaDevolucion? _forma;

	@override
	void initState() {
		super.initState();
		context.read<RecepcionDetalleBloc>().add(const RecepcionErrorAccionDescartado());
	}

	@override
	void dispose() {
		_observacionController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<RecepcionDetalleBloc, RecepcionDetalleState>(
			listenWhen: _accionTerminoBien,
			listener: (context, _) => Navigator.of(context).pop(),
			builder: (context, state) {
				return AlertDialog(
					title: const Text('Devolver al cliente'),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Text('¿Cómo se devuelve el equipo?'),
							const SizedBox(height: 8),
							Wrap(
								spacing: 8,
								runSpacing: 8,
								children: [
									for (final forma in FormaDevolucion.values)
										ChoiceChip(
											label: Text(nombreFormaDevolucion(forma)),
											selected: _forma == forma,
											onSelected: state.procesandoAccion
													? null
													: (_) => setState(() => _forma = forma),
										),
								],
							),
							const SizedBox(height: 12),
							TextField(
								controller: _observacionController,
								enabled: !state.procesandoAccion,
								minLines: 1,
								maxLines: 4,
								decoration: const InputDecoration(
									labelText: 'Observación (opcional)',
									hintText: 'Ej: por Andreani',
								),
							),
							ErrorAccionDetalle(mensaje: state.errorAccion),
						],
					),
					actions: [
						TextButton(
							onPressed: state.procesandoAccion ? null : () => Navigator.of(context).pop(),
							child: const Text('Cancelar'),
						),
						ElevatedButton(
							onPressed: state.procesandoAccion
									? null
									: () {
											context.read<RecepcionDetalleBloc>().add(
												RecepcionDevolucionSolicitada(
													forma: _forma,
													observacion: _observacionController.text,
												),
											);
										},
							child: state.procesandoAccion
									? const SizedBox(
											height: 16,
											width: 16,
											child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
										)
									: const Text('Devolver'),
						),
					],
				);
			},
		);
	}
}

/// El servicio de fabrica (diagnostico, resolucion y facturacion) de la
/// recepcion: vinculado, esperando la vinculacion o para cargar.
class _SeccionServicio extends StatelessWidget {
	final RecepcionDetalleState state;

	const _SeccionServicio({required this.state});

	@override
	Widget build(BuildContext context) {
		final vinculadoId = state.servicioVinculadoId;
		final porVincular = state.servicioPorVincular;
		final textTheme = Theme.of(context).textTheme;
		final colorScheme = Theme.of(context).colorScheme;

		return SeccionDetalle(
			titulo: 'Servicio de fábrica',
			children: [
				if (vinculadoId != null) ...[
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(Icons.link, color: colorScheme.primary),
						title: const Text('Vinculado a la recepción'),
						subtitle: Text('Servicio $vinculadoId'),
					),
					_ResumenServicioVinculado(state: state),
				] else if (porVincular != null) ...[
					Container(
						width: double.infinity,
						padding: const EdgeInsets.all(10),
						decoration: BoxDecoration(
							color: state.errorVinculacion == null
									? colorScheme.surfaceContainerHighest
									: colorScheme.errorContainer,
							borderRadius: BorderRadius.circular(8),
						),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									state.vinculando
											? 'Vinculando el servicio $porVincular...'
											: 'El servicio $porVincular se guardó pero no quedó vinculado a la recepción.',
									style: TextStyle(
										color: state.errorVinculacion == null
												? colorScheme.onSurface
												: colorScheme.onErrorContainer,
									),
								),
								if (state.errorVinculacion != null && !state.vinculando) ...[
									const SizedBox(height: 4),
									Text(
										state.errorVinculacion!,
										style: textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
									),
								],
							],
						),
					),
					const SizedBox(height: 8),
					ElevatedButton.icon(
						onPressed: state.puedeReintentarVinculacion
								? () {
										context.read<RecepcionDetalleBloc>().add(
											const RecepcionVinculacionReintentada(),
										);
									}
								: null,
						icon: state.vinculando
								? const SizedBox(
										height: 16,
										width: 16,
										child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
									)
								: const Icon(Icons.link),
						label: const Text('Reintentar vinculación'),
					),
				] else if (state.puedeCargarServicio) ...[
					const Text(
						'Todavía no tiene servicio de fábrica. Ahí se cargan el diagnóstico, '
						'el trabajo realizado y la facturación.',
					),
					const SizedBox(height: 8),
					ElevatedButton.icon(
						onPressed: () => _cargarServicio(context),
						icon: const Icon(Icons.build_circle_outlined),
						label: const Text('Cargar servicio de fábrica'),
					),
				] else
					const Text('Sin servicio de fábrica vinculado.'),
			],
		);
	}

	void _cargarServicio(BuildContext context) {
		final recepcion = state.recepcion;
		final precarga = state.precargaServicio;
		if (recepcion == null || precarga == null) {
			return;
		}
		Navigator.of(context).push(
			MaterialPageRoute<void>(
				builder: (_) => ServicioFabricaPage(
					recepcionId: recepcion.id,
					numeroRecepcion: recepcion.numero,
					precarga: precarga,
				),
			),
		);
	}
}

class _ResumenServicioVinculado extends StatelessWidget {
	final RecepcionDetalleState state;

	const _ResumenServicioVinculado({required this.state});

	@override
	Widget build(BuildContext context) {
		final resumen = state.resumenServicioVinculado;
		if (resumen != null) {
			return Column(
				children: [
					FilaDetalle(label: 'Fecha', valor: formatearFechaFabrica(resumen.fecha)),
					FilaDetalle(label: 'Técnico', valor: textoSeguro(resumen.tecnicoNombre)),
					FilaDetalle(
						label: 'Diagnóstico',
						valor: resumen.diagnosticos.isEmpty ? 'Sin dato' : resumen.diagnosticos.join(', '),
					),
					if ((resumen.diagnosticoDetalle ?? '').trim().isNotEmpty)
						FilaDetalle(label: 'Detalle técnico', valor: resumen.diagnosticoDetalle!.trim()),
					FilaDetalle(
						label: 'Trabajo realizado',
						valor: resumen.resoluciones.isEmpty ? 'Sin dato' : resumen.resoluciones.join(', '),
					),
				],
			);
		}

		if (state.cargandoServicioVinculado) {
			return const Padding(
				padding: EdgeInsets.symmetric(vertical: 8),
				child: LinearProgressIndicator(),
			);
		}

		// 403/404: queda el id, sin error.
		final error = state.errorServicioVinculado;
		if (error == null) {
			return const SizedBox.shrink();
		}
		return Row(
			children: [
				Expanded(
					child: Text(
						error,
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: Theme.of(context).colorScheme.error,
								),
					),
				),
				TextButton.icon(
					onPressed: () {
						context.read<RecepcionDetalleBloc>().add(
							const RecepcionServicioVinculadoSolicitado(),
						);
					},
					icon: const Icon(Icons.refresh),
					label: const Text('Reintentar'),
				),
			],
		);
	}
}

class _SeccionDatos extends StatelessWidget {
	final Recepcion recepcion;

	const _SeccionDatos({required this.recepcion});

	@override
	Widget build(BuildContext context) {
		final formaDevolucion = recepcion.formaDevolucion;
		return SeccionDetalle(
			titulo: 'Datos',
			children: [
				FilaDetalle(label: 'Cliente', valor: recepcion.cliente.nombre),
				FilaDetalle(label: 'CUIT', valor: textoSeguro(recepcion.cliente.cuit)),
				FilaDetalle(label: 'N° de serie del indicador', valor: recepcion.indicador.nroSerie),
				FilaDetalle(label: 'Modelo', valor: textoSeguro(recepcion.indicador.producto?.nombre)),
				FilaDetalle(label: 'Qué llegó', valor: textoSeguro(recepcion.queLlego)),
				FilaDetalle(label: 'Qué reporta el cliente', valor: textoSeguro(recepcion.sintomaReportado)),
				FilaDetalle(label: 'Observaciones', valor: textoSeguro(recepcion.observaciones)),
				FilaDetalle(label: 'Recibió', valor: textoSeguro(recepcion.tecnicoRecepcion?.fullName)),
				FilaDetalle(label: 'Fecha de recepción', valor: formatearFechaFabrica(recepcion.fechaRecepcion)),
				if (recepcion.fechaDevolucion != null)
					FilaDetalle(label: 'Fecha de devolución', valor: formatearFechaFabrica(recepcion.fechaDevolucion)),
				if (formaDevolucion != null)
					FilaDetalle(label: 'Forma de devolución', valor: nombreFormaDevolucion(formaDevolucion)),
			],
		);
	}
}

class _SeccionHistorial extends StatelessWidget {
	final List<CambioEstadoRecepcion> historial;

	const _SeccionHistorial({required this.historial});

	@override
	Widget build(BuildContext context) {
		return SeccionDetalle(
			titulo: 'Historial de estados',
			children: [
				if (historial.isEmpty) const Text('Sin cambios registrados.'),
				for (final cambio in historial)
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(
							Icons.circle,
							size: 12,
							color: EstadoRecepcionBadge.color(cambio.estado),
						),
						title: Text(nombreEstadoRecepcion(cambio.estado)),
						subtitle: Text(
							[
								formatearFechaFabrica(cambio.fecha),
								if ((cambio.usuarioNombre ?? '').trim().isNotEmpty) cambio.usuarioNombre!.trim(),
								if ((cambio.observacion ?? '').trim().isNotEmpty) cambio.observacion!.trim(),
							].join(' · '),
						),
					),
			],
		);
	}
}

class _SeccionPiezasInstaladas extends StatelessWidget {
	final List<Unidad> piezas;

	const _SeccionPiezasInstaladas({required this.piezas});

	@override
	Widget build(BuildContext context) {
		return SeccionDetalle(
			titulo: 'Piezas instaladas en el indicador',
			children: [
				if (piezas.isEmpty) const Text('No figuran piezas instaladas.'),
				for (final pieza in piezas)
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(iconoTipoUnidad(pieza.tipo)),
						title: Text('${nombreTipoUnidad(pieza.tipo)} ${pieza.nroSerie}'),
						subtitle: pieza.producto == null ? null : Text(pieza.producto!.nombre),
					),
			],
		);
	}
}

class _SeccionIngresos extends StatelessWidget {
	final RecepcionDetalleState state;
	final List<Ingreso> ingresos;

	const _SeccionIngresos({required this.state, required this.ingresos});

	@override
	Widget build(BuildContext context) {
		return SeccionDetalle(
			titulo: 'Piezas ingresadas desde esta recepción',
			children: [
				if (ingresos.isEmpty) const Text('Todavía no se ingresaron piezas.'),
				for (final ingreso in ingresos)
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(iconoTipoUnidad(ingreso.unidad.tipo)),
						title: Text(
							'Ingreso N° ${ingreso.numero} · ${nombreTipoUnidad(ingreso.unidad.tipo)} ${ingreso.unidad.nroSerie}',
						),
						subtitle: Text(formatearFechaFabrica(ingreso.fechaIngreso)),
						trailing: EstadoIngresoBadge(estado: ingreso.estado),
						onTap: () => _abrirIngreso(context, ingreso),
					),
				if (state.puedeIngresarPieza) ...[
					const SizedBox(height: 8),
					OutlinedButton.icon(
						onPressed: () => _ingresarPieza(context),
						icon: const Icon(Icons.move_to_inbox_outlined),
						label: const Text('Ingresar pieza retirada'),
					),
				],
			],
		);
	}

	Future<void> _abrirIngreso(BuildContext context, Ingreso ingreso) async {
		final bloc = context.read<RecepcionDetalleBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(builder: (_) => IngresoDetallePage(ingresoId: ingreso.id)),
		);
		bloc.add(const RecepcionDetalleRefrescado());
	}

	Future<void> _ingresarPieza(BuildContext context) async {
		final precarga = state.precargaIngreso;
		if (precarga == null) {
			return;
		}
		final bloc = context.read<RecepcionDetalleBloc>();
		await Navigator.of(context).push(
			MaterialPageRoute<void>(builder: (_) => NuevoIngresoPage(recepcion: precarga)),
		);
		bloc.add(const RecepcionDetalleRefrescado());
	}
}

