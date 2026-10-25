import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/falla.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/reparacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/ingreso_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_ingreso_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IngresoDetallePage extends StatefulWidget {
	final String ingresoId;

	/// La respuesta del alta: se muestra sin volver a pedirla.
	final Ingreso? ingresoInicial;

	const IngresoDetallePage({
		required this.ingresoId,
		this.ingresoInicial,
		super.key,
	});

	@override
	State<IngresoDetallePage> createState() => _IngresoDetallePageState();
}

class _IngresoDetallePageState extends State<IngresoDetallePage> {
	@override
	void initState() {
		super.initState();
		context.read<IngresoDetalleBloc>().add(
			IngresoDetalleAbierto(ingresoId: widget.ingresoId, ingreso: widget.ingresoInicial),
		);
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<IngresoDetalleBloc, IngresoDetalleState>(
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
				// Mientras llega el ingreso pedido no se muestra el anterior.
				final ingreso = state.ingresoId == widget.ingresoId ? state.ingreso : null;
				return Scaffold(
					appBar: AppBar(
						title: Text(ingreso == null ? 'Ingreso' : 'Ingreso N° ${ingreso.numero}'),
						actions: [
							IconButton(
								onPressed: state.cargando
										? null
										: () {
												context.read<IngresoDetalleBloc>().add(const IngresoDetalleRefrescado());
											},
								icon: const Icon(Icons.refresh),
								tooltip: 'Actualizar',
							),
						],
					),
					body: _construirCuerpo(context, state, ingreso),
				);
			},
		);
	}

	Widget _construirCuerpo(BuildContext context, IngresoDetalleState state, Ingreso? ingreso) {
		if (ingreso == null) {
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
										context.read<IngresoDetalleBloc>().add(
											IngresoDetalleAbierto(ingresoId: widget.ingresoId),
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
							context.read<IngresoDetalleBloc>().add(const IngresoDetalleRefrescado());
						},
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								_Encabezado(ingreso: ingreso, aviso: state.aviso),
								const SizedBox(height: 12),
								_SeccionAcciones(state: state),
								_SeccionDatos(ingreso: ingreso),
								if (ingreso.falla != null) ...[
									const SizedBox(height: 12),
									_SeccionFalla(falla: ingreso.falla!),
								],
								if (ingreso.reparacion != null) ...[
									const SizedBox(height: 12),
									_SeccionReparacion(reparacion: ingreso.reparacion!),
								],
							],
						),
					),
				),
			],
		);
	}
}

class _Encabezado extends StatelessWidget {
	final Ingreso ingreso;
	final String? aviso;

	const _Encabezado({required this.ingreso, required this.aviso});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final unidad = ingreso.unidad;
		final modelo = unidad.producto?.nombre;
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(14),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Icon(iconoTipoUnidad(unidad.tipo)),
								const SizedBox(width: 8),
								Expanded(
									child: Text(
										'${nombreTipoUnidad(unidad.tipo)} ${unidad.nroSerie}',
										style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
									),
								),
								const SizedBox(width: 8),
								EstadoIngresoBadge(estado: ingreso.estado),
							],
						),
						if ((modelo ?? '').isNotEmpty) ...[
							const SizedBox(height: 6),
							Text(modelo!),
						],
						if (aviso != null) ...[
							const SizedBox(height: 6),
							Text(aviso!, style: textTheme.bodySmall),
						],
					],
				),
			),
		);
	}
}

class _SeccionAcciones extends StatelessWidget {
	final IngresoDetalleState state;

	const _SeccionAcciones({required this.state});

	@override
	Widget build(BuildContext context) {
		final acciones = state.acciones;
		if (acciones.isEmpty) {
			return const SizedBox.shrink();
		}

		final bloqueos = {
			for (final accion in acciones)
				if (accion.motivoBloqueo != null) accion.motivoBloqueo!,
		};

		return Padding(
			padding: const EdgeInsets.only(bottom: 12),
			child: SeccionDetalle(
				titulo: 'Acciones',
				children: [
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							for (final accion in acciones)
								ElevatedButton.icon(
									onPressed: state.procesandoAccion || !accion.habilitada
											? null
											: () => _abrirDialogo(context, accion),
									icon: state.accionEnCurso == accion.accion
											? const ProgresoBoton()
											: Icon(_icono(accion.accion)),
									label: Text(accion.etiqueta),
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
			),
		);
	}

	static IconData _icono(AccionIngreso accion) {
		return switch (accion) {
			AccionIngreso.derivar => Icons.science_outlined,
			AccionIngreso.cargarFalla => Icons.report_problem_outlined,
			AccionIngreso.cargarReparacion => Icons.handyman_outlined,
			AccionIngreso.recibirDeDesarrollo => Icons.assignment_return_outlined,
		};
	}

	Future<void> _abrirDialogo(BuildContext context, AccionIngresoDisponible accion) {
		final ingreso = state.ingreso;
		return showDialog<void>(
			context: context,
			builder: (_) => switch (accion.accion) {
				AccionIngreso.derivar => _DialogoObservacion(
						titulo: accion.etiqueta,
						texto: 'La placa pasa a desarrollo, que carga la falla y la reparación.',
						confirmar: 'Derivar',
						evento: (observacion) => IngresoDerivacionSolicitada(observacion: observacion),
					),
				AccionIngreso.recibirDeDesarrollo => _DialogoObservacion(
						titulo: accion.etiqueta,
						texto: 'La placa reparada vuelve a servicio técnico y queda reacondicionada '
								'disponible para recambio.',
						confirmar: 'Recibir',
						evento: (observacion) => IngresoVueltaDesarrolloSolicitada(observacion: observacion),
					),
				AccionIngreso.cargarFalla => _DialogoFalla(titulo: accion.etiqueta, anterior: ingreso?.falla),
				AccionIngreso.cargarReparacion => const _DialogoReparacion(),
			},
		);
	}
}

/// Cierra el dialogo cuando la accion termina bien. Si el backend la rechaza,
/// queda abierto con lo cargado y el mensaje tal cual.
bool _accionTerminoBien(IngresoDetalleState anterior, IngresoDetalleState actual) {
	return anterior.procesandoAccion && !actual.procesandoAccion && actual.errorAccion == null;
}

/// Botones del pie de los dialogos de accion.
List<Widget> _botonesDialogo(
	BuildContext context,
	IngresoDetalleState state, {
	required String confirmar,
	required VoidCallback onConfirmar,
}) {
	return [
		TextButton(
			onPressed: state.procesandoAccion ? null : () => Navigator.of(context).pop(),
			child: const Text('Cancelar'),
		),
		ElevatedButton(
			onPressed: state.procesandoAccion ? null : onConfirmar,
			child: state.procesandoAccion ? const ProgresoBoton() : Text(confirmar),
		),
	];
}

class _DialogoObservacion extends StatefulWidget {
	final String titulo;
	final String texto;
	final String confirmar;
	final IngresoDetalleEvent Function(String observacion) evento;

	const _DialogoObservacion({
		required this.titulo,
		required this.texto,
		required this.confirmar,
		required this.evento,
	});

	@override
	State<_DialogoObservacion> createState() => _DialogoObservacionState();
}

class _DialogoObservacionState extends State<_DialogoObservacion> {
	final TextEditingController _observacionController = TextEditingController();

	@override
	void initState() {
		super.initState();
		context.read<IngresoDetalleBloc>().add(const IngresoErrorAccionDescartado());
	}

	@override
	void dispose() {
		_observacionController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<IngresoDetalleBloc, IngresoDetalleState>(
			listenWhen: _accionTerminoBien,
			listener: (context, _) => Navigator.of(context).pop(),
			builder: (context, state) {
				return AlertDialog(
					title: Text(widget.titulo),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(widget.texto),
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
					actions: _botonesDialogo(
						context,
						state,
						confirmar: widget.confirmar,
						onConfirmar: () {
							context.read<IngresoDetalleBloc>().add(widget.evento(_observacionController.text));
						},
					),
				);
			},
		);
	}
}

class _DialogoFalla extends StatefulWidget {
	final String titulo;

	/// Al corregir, arranca con la falla cargada.
	final Falla? anterior;

	const _DialogoFalla({required this.titulo, required this.anterior});

	@override
	State<_DialogoFalla> createState() => _DialogoFallaState();
}

class _DialogoFallaState extends State<_DialogoFalla> {
	final TextEditingController _otroController = TextEditingController();
	final TextEditingController _detalleController = TextEditingController();
	String? _componenteId;
	bool _usarOtro = false;
	String? _causaId;

	@override
	void initState() {
		super.initState();
		final anterior = widget.anterior;
		if (anterior != null) {
			_componenteId = anterior.componente?.id;
			_usarOtro = anterior.componente == null && (anterior.componenteOtro ?? '').isNotEmpty;
			_otroController.text = anterior.componenteOtro ?? '';
			_causaId = anterior.causa?.id;
			_detalleController.text = anterior.detalle ?? '';
		}
		context.read<IngresoDetalleBloc>()
			..add(const IngresoErrorAccionDescartado())
			..add(const IngresoCatalogosFallaSolicitados());
	}

	@override
	void dispose() {
		_otroController.dispose();
		_detalleController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<IngresoDetalleBloc, IngresoDetalleState>(
			listenWhen: _accionTerminoBien,
			listener: (context, _) => Navigator.of(context).pop(),
			builder: (context, state) {
				final habilitado = !state.procesandoAccion;
				return AlertDialog(
					title: Text(widget.titulo),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								if (state.cargandoCatalogosFalla)
									const Padding(
										padding: EdgeInsets.only(bottom: 12),
										child: LinearProgressIndicator(),
									),
								if (state.errorCatalogosFalla != null) ...[
									Text(
										state.errorCatalogosFalla!,
										style: TextStyle(color: Theme.of(context).colorScheme.error),
									),
									TextButton.icon(
										onPressed: () {
											context.read<IngresoDetalleBloc>().add(const IngresoCatalogosFallaSolicitados());
										},
										icon: const Icon(Icons.refresh),
										label: const Text('Reintentar'),
									),
								],
								const Text('Componente que falló'),
								const SizedBox(height: 6),
								if (!state.tieneModelo)
									const Padding(
										padding: EdgeInsets.only(bottom: 6),
										child: Text('La pieza no tiene modelo cargado: escribí el componente.'),
									),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									children: [
										for (final componente in state.componentes)
											ChoiceChip(
												label: Text(componente.nombre),
												selected: !_usarOtro && _componenteId == componente.id,
												onSelected: habilitado
														? (_) => setState(() {
																_componenteId = componente.id;
																_usarOtro = false;
															})
														: null,
											),
										ChoiceChip(
											label: const Text('Otro'),
											selected: _usarOtro,
											onSelected: habilitado
													? (_) => setState(() {
															_usarOtro = true;
															_componenteId = null;
														})
													: null,
										),
									],
								),
								if (_usarOtro) ...[
									const SizedBox(height: 8),
									TextField(
										controller: _otroController,
										enabled: habilitado,
										decoration: const InputDecoration(labelText: '¿Qué componente?'),
									),
								],
								const SizedBox(height: 12),
								const Text('Causa'),
								const SizedBox(height: 6),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									children: [
										for (final causa in state.causas)
											ChoiceChip(
												label: Text(causa.nombre),
												selected: _causaId == causa.id,
												onSelected: habilitado ? (_) => setState(() => _causaId = causa.id) : null,
											),
									],
								),
								const SizedBox(height: 12),
								TextField(
									controller: _detalleController,
									enabled: habilitado,
									minLines: 2,
									maxLines: 5,
									decoration: const InputDecoration(labelText: 'Detalle (opcional)'),
								),
								ErrorAccionDetalle(mensaje: state.errorAccion),
							],
						),
					),
					actions: _botonesDialogo(
						context,
						state,
						confirmar: 'Guardar falla',
						onConfirmar: () {
							context.read<IngresoDetalleBloc>().add(
								IngresoFallaSolicitada(
									componenteId: _usarOtro ? null : _componenteId,
									componenteOtro: _usarOtro ? _otroController.text : '',
									causaId: _causaId,
									detalle: _detalleController.text,
								),
							);
						},
					),
				);
			},
		);
	}
}

class _DialogoReparacion extends StatefulWidget {
	const _DialogoReparacion();

	@override
	State<_DialogoReparacion> createState() => _DialogoReparacionState();
}

class _DialogoReparacionState extends State<_DialogoReparacion> {
	static const List<ResultadoReparacion> _resultados = [
		ResultadoReparacion.reparada,
		ResultadoReparacion.irreparable,
	];

	final TextEditingController _trabajoController = TextEditingController();
	final TextEditingController _reemplazadosController = TextEditingController();
	ResultadoReparacion? _resultado;

	@override
	void initState() {
		super.initState();
		context.read<IngresoDetalleBloc>().add(const IngresoErrorAccionDescartado());
	}

	@override
	void dispose() {
		_trabajoController.dispose();
		_reemplazadosController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<IngresoDetalleBloc, IngresoDetalleState>(
			listenWhen: _accionTerminoBien,
			listener: (context, _) => Navigator.of(context).pop(),
			builder: (context, state) {
				final habilitado = !state.procesandoAccion;
				return AlertDialog(
					title: const Text('Cargar reparación'),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text('Se carga una sola vez: después no se puede cambiar la falla.'),
								const SizedBox(height: 12),
								Wrap(
									spacing: 8,
									children: [
										for (final resultado in _resultados)
											ChoiceChip(
												label: Text(nombreResultadoReparacion(resultado)),
												selected: _resultado == resultado,
												onSelected: habilitado ? (_) => setState(() => _resultado = resultado) : null,
											),
									],
								),
								const SizedBox(height: 12),
								TextField(
									controller: _trabajoController,
									enabled: habilitado,
									minLines: 2,
									maxLines: 5,
									decoration: const InputDecoration(labelText: 'Trabajo realizado'),
								),
								const SizedBox(height: 12),
								TextField(
									controller: _reemplazadosController,
									enabled: habilitado,
									decoration: const InputDecoration(
										labelText: 'Componentes reemplazados (opcional)',
									),
								),
								ErrorAccionDetalle(mensaje: state.errorAccion),
							],
						),
					),
					actions: _botonesDialogo(
						context,
						state,
						confirmar: 'Guardar reparación',
						onConfirmar: () {
							context.read<IngresoDetalleBloc>().add(
								IngresoReparacionSolicitada(
									resultado: _resultado,
									trabajoRealizado: _trabajoController.text,
									componentesReemplazados: _reemplazadosController.text,
								),
							);
						},
					),
				);
			},
		);
	}
}

class _SeccionDatos extends StatelessWidget {
	final Ingreso ingreso;

	const _SeccionDatos({required this.ingreso});

	@override
	Widget build(BuildContext context) {
		final unidad = ingreso.unidad;
		final producto = unidad.producto;
		final modelo = producto == null
				? null
				: [producto.nombre, if ((producto.version ?? '').isNotEmpty) producto.version!].join(' ');
		return SeccionDetalle(
			titulo: 'Datos',
			children: [
				FilaDetalle(label: 'Tipo', valor: nombreTipoUnidad(unidad.tipo)),
				FilaDetalle(label: 'N° de serie', valor: unidad.nroSerie),
				FilaDetalle(label: 'Modelo', valor: textoSeguro(modelo)),
				FilaDetalle(label: 'Cliente o sucursal', valor: textoSeguro(ingreso.clienteOrigen?.nombre)),
				FilaDetalle(label: 'Indicador del que salió', valor: textoSeguro(ingreso.indicadorOrigen?.nroSerie)),
				FilaDetalle(
					label: 'Origen',
					valor: (ingreso.recepcionId ?? '').isEmpty ? 'Sin recepción' : 'Desde una recepción',
				),
				FilaDetalle(label: 'Qué observó el técnico', valor: textoSeguro(ingreso.observacionTecnico)),
				FilaDetalle(label: 'Ingresó', valor: textoSeguro(ingreso.tecnico?.fullName)),
				FilaDetalle(label: 'Fecha de ingreso', valor: formatearFechaFabrica(ingreso.fechaIngreso)),
			],
		);
	}
}

class _SeccionFalla extends StatelessWidget {
	final Falla falla;

	const _SeccionFalla({required this.falla});

	@override
	Widget build(BuildContext context) {
		return SeccionDetalle(
			titulo: 'Falla',
			children: [
				FilaDetalle(
					label: 'Componente',
					valor: textoSeguro(falla.componente?.nombre ?? falla.componenteOtro),
				),
				FilaDetalle(label: 'Causa', valor: textoSeguro(falla.causa?.nombre)),
				FilaDetalle(label: 'Detalle', valor: textoSeguro(falla.detalle)),
				FilaDetalle(label: 'Cargó', valor: textoSeguro(falla.usuario?.fullName)),
				FilaDetalle(label: 'Fecha', valor: formatearFechaFabrica(falla.fecha)),
			],
		);
	}
}

class _SeccionReparacion extends StatelessWidget {
	final Reparacion reparacion;

	const _SeccionReparacion({required this.reparacion});

	@override
	Widget build(BuildContext context) {
		return SeccionDetalle(
			titulo: 'Reparación',
			children: [
				FilaDetalle(label: 'Resultado', valor: nombreResultadoReparacion(reparacion.resultado)),
				FilaDetalle(label: 'Trabajo realizado', valor: textoSeguro(reparacion.trabajoRealizado)),
				FilaDetalle(
					label: 'Componentes reemplazados',
					valor: textoSeguro(reparacion.componentesReemplazados),
				),
				FilaDetalle(label: 'Cargó', valor: textoSeguro(reparacion.usuario?.fullName)),
				FilaDetalle(label: 'Fecha', valor: formatearFechaFabrica(reparacion.fecha)),
			],
		);
	}
}
