import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_recepcion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/pages/servicio_fabrica_page.dart';
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
								_SeccionIngresos(ingresos: recepcion.ingresos),
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

		return _Seccion(
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
							_ErrorAccion(mensaje: state.errorAccion),
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
							_ErrorAccion(mensaje: state.errorAccion),
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

class _ErrorAccion extends StatelessWidget {
	final String? mensaje;

	const _ErrorAccion({required this.mensaje});

	@override
	Widget build(BuildContext context) {
		final texto = mensaje;
		if (texto == null) {
			return const SizedBox.shrink();
		}
		final colorScheme = Theme.of(context).colorScheme;
		return Container(
			width: double.infinity,
			margin: const EdgeInsets.only(top: 12),
			padding: const EdgeInsets.all(10),
			decoration: BoxDecoration(
				color: colorScheme.errorContainer,
				borderRadius: BorderRadius.circular(8),
			),
			child: Text(texto, style: TextStyle(color: colorScheme.onErrorContainer)),
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

		return _Seccion(
			titulo: 'Servicio de fábrica',
			children: [
				if (vinculadoId != null)
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(Icons.link, color: colorScheme.primary),
						title: const Text('Vinculado a la recepción'),
						subtitle: Text('Servicio $vinculadoId'),
					)
				else if (porVincular != null) ...[
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

class _SeccionDatos extends StatelessWidget {
	final Recepcion recepcion;

	const _SeccionDatos({required this.recepcion});

	@override
	Widget build(BuildContext context) {
		final formaDevolucion = recepcion.formaDevolucion;
		return _Seccion(
			titulo: 'Datos',
			children: [
				_Fila(label: 'Cliente', valor: recepcion.cliente.nombre),
				_Fila(label: 'CUIT', valor: _textoSeguro(recepcion.cliente.cuit)),
				_Fila(label: 'N° de serie del indicador', valor: recepcion.indicador.nroSerie),
				_Fila(label: 'Modelo', valor: _textoSeguro(recepcion.indicador.producto?.nombre)),
				_Fila(label: 'Qué llegó', valor: _textoSeguro(recepcion.queLlego)),
				_Fila(label: 'Qué reporta el cliente', valor: _textoSeguro(recepcion.sintomaReportado)),
				_Fila(label: 'Observaciones', valor: _textoSeguro(recepcion.observaciones)),
				_Fila(label: 'Recibió', valor: _textoSeguro(recepcion.tecnicoRecepcion?.fullName)),
				_Fila(label: 'Fecha de recepción', valor: _formatearFecha(recepcion.fechaRecepcion)),
				if (recepcion.fechaDevolucion != null)
					_Fila(label: 'Fecha de devolución', valor: _formatearFecha(recepcion.fechaDevolucion)),
				if (formaDevolucion != null)
					_Fila(label: 'Forma de devolución', valor: nombreFormaDevolucion(formaDevolucion)),
			],
		);
	}
}

class _SeccionHistorial extends StatelessWidget {
	final List<CambioEstadoRecepcion> historial;

	const _SeccionHistorial({required this.historial});

	@override
	Widget build(BuildContext context) {
		return _Seccion(
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
								_formatearFecha(cambio.fecha),
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
		return _Seccion(
			titulo: 'Piezas instaladas en el indicador',
			children: [
				if (piezas.isEmpty) const Text('No figuran piezas instaladas.'),
				for (final pieza in piezas)
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(_iconoTipo(pieza.tipo)),
						title: Text('${_nombreTipo(pieza.tipo)} ${pieza.nroSerie}'),
						subtitle: pieza.producto == null ? null : Text(pieza.producto!.nombre),
					),
			],
		);
	}
}

class _SeccionIngresos extends StatelessWidget {
	final List<Ingreso> ingresos;

	const _SeccionIngresos({required this.ingresos});

	@override
	Widget build(BuildContext context) {
		return _Seccion(
			titulo: 'Piezas ingresadas desde esta recepción',
			children: [
				if (ingresos.isEmpty) const Text('Todavía no se ingresaron piezas.'),
				for (final ingreso in ingresos)
					ListTile(
						dense: true,
						contentPadding: EdgeInsets.zero,
						leading: Icon(_iconoTipo(ingreso.unidad.tipo)),
						title: Text(
							'Ingreso N° ${ingreso.numero} · ${_nombreTipo(ingreso.unidad.tipo)} ${ingreso.unidad.nroSerie}',
						),
						subtitle: Text(_formatearFecha(ingreso.fechaIngreso)),
					),
			],
		);
	}
}

class _Seccion extends StatelessWidget {
	final String titulo;
	final List<Widget> children;

	const _Seccion({required this.titulo, required this.children});

	@override
	Widget build(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(14),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							titulo,
							style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
						),
						const SizedBox(height: 8),
						...children,
					],
				),
			),
		);
	}
}

class _Fila extends StatelessWidget {
	final String label;
	final String valor;

	const _Fila({required this.label, required this.valor});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 3),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Expanded(flex: 4, child: Text(label)),
					Expanded(
						flex: 6,
						child: Text(
							valor,
							textAlign: TextAlign.right,
							style: const TextStyle(fontWeight: FontWeight.w600),
						),
					),
				],
			),
		);
	}
}

IconData _iconoTipo(TipoUnidad tipo) {
	return switch (tipo) {
		TipoUnidad.indicador => Icons.monitor_weight_outlined,
		TipoUnidad.placa => Icons.memory,
		TipoUnidad.celda => Icons.sensors,
		TipoUnidad.desconocido => Icons.help_outline,
	};
}

String _nombreTipo(TipoUnidad tipo) {
	return switch (tipo) {
		TipoUnidad.indicador => 'Indicador',
		TipoUnidad.placa => 'Placa',
		TipoUnidad.celda => 'Celda',
		TipoUnidad.desconocido => 'Pieza',
	};
}

String _textoSeguro(String? valor) {
	final limpio = (valor ?? '').trim();
	return limpio.isEmpty ? 'Sin dato' : limpio;
}

String _formatearFecha(DateTime? fecha) {
	if (fecha == null) {
		return 'Sin dato';
	}

	final local = fecha.toLocal();
	final dia = local.day.toString().padLeft(2, '0');
	final mes = local.month.toString().padLeft(2, '0');
	final hora = local.hour.toString().padLeft(2, '0');
	final minuto = local.minute.toString().padLeft(2, '0');
	return '$dia/$mes/${local.year} $hora:$minuto';
}
