import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/pieza_detalle_state.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/estado_unidad_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detalle de una pieza: datos, historial completo y, si es un indicador,
/// sus piezas instaladas.
class PiezaDetallePage extends StatefulWidget {
	final String unidadId;

	/// La del listado: se muestran sus datos mientras llega el resto.
	final Unidad? unidadInicial;

	const PiezaDetallePage({required this.unidadId, this.unidadInicial, super.key});

	@override
	State<PiezaDetallePage> createState() => _PiezaDetallePageState();
}

class _PiezaDetallePageState extends State<PiezaDetallePage> {
	@override
	void initState() {
		super.initState();
		_abrir(widget.unidadInicial);
	}

	void _abrir(Unidad? unidad) {
		context.read<PiezaDetalleBloc>().add(
			PiezaDetalleAbierta(unidadId: widget.unidadId, unidad: unidad),
		);
	}

	/// El detalle de una pieza instalada usa el mismo bloc: al volver se
	/// vuelve a abrir esta.
	Future<void> _abrirPieza(Unidad pieza) async {
		await Navigator.of(context).push(
			MaterialPageRoute<void>(
				builder: (_) => PiezaDetallePage(unidadId: pieza.id, unidadInicial: pieza),
			),
		);
		if (mounted) {
			_abrir(null);
		}
	}

	@override
	Widget build(BuildContext context) {
		return BlocConsumer<PiezaDetalleBloc, PiezaDetalleState>(
			listenWhen: (_, actual) => actual.errorMensaje != null,
			listener: (context, state) {
				ScaffoldMessenger.of(context)
					..hideCurrentSnackBar()
					..showSnackBar(SnackBar(content: Text(state.errorMensaje!)));
			},
			builder: (context, state) {
				// Mientras llega la pieza pedida no se muestra la anterior.
				final vigente = state.unidadId == widget.unidadId;
				final unidad = vigente ? state.unidad : null;
				return Scaffold(
					appBar: AppBar(
						title: Text(
							unidad == null ? 'Pieza' : '${nombreTipoUnidad(unidad.tipo)} ${unidad.nroSerie}',
						),
						actions: [
							IconButton(
								onPressed: state.cargando
										? null
										: () => context.read<PiezaDetalleBloc>().add(const PiezaDetalleRefrescada()),
								icon: const Icon(Icons.refresh),
								tooltip: 'Actualizar',
							),
						],
					),
					body: vigente ? _construirCuerpo(context, state, unidad) : const Center(child: CircularProgressIndicator()),
				);
			},
		);
	}

	Widget _construirCuerpo(BuildContext context, PiezaDetalleState state, Unidad? unidad) {
		final errorCarga = state.errorCarga;
		if (unidad == null) {
			if (errorCarga != null && !state.cargando) {
				return _ErrorCarga(mensaje: errorCarga, onReintentar: () => _abrir(null));
			}
			return const Center(child: CircularProgressIndicator());
		}

		return Column(
			children: [
				SizedBox(
					height: 4,
					child: state.cargando && state.completo ? const LinearProgressIndicator() : null,
				),
				Expanded(
					child: RefreshIndicator(
						onRefresh: () async {
							context.read<PiezaDetalleBloc>().add(const PiezaDetalleRefrescada());
						},
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								SeccionDetalle(
									titulo: 'Datos',
									children: [
										Row(
											children: [
												Icon(iconoTipoUnidad(unidad.tipo)),
												const SizedBox(width: 8),
												Expanded(child: Text(nombreTipoUnidad(unidad.tipo))),
												EstadoUnidadBadge(estado: unidad.estado),
											],
										),
										const SizedBox(height: 6),
										FilaDetalle(label: 'N° de serie', valor: unidad.nroSerie),
										FilaDetalle(label: 'Modelo', valor: textoSeguro(unidad.producto?.nombre)),
									],
								),
								if (state.esIndicador && state.completo) ...[
									const SizedBox(height: 12),
									SeccionDetalle(
										titulo: 'Piezas instaladas',
										children: [
											if (state.piezasInstaladas.isEmpty) const Text('No figuran piezas instaladas.'),
											for (final pieza in state.piezasInstaladas)
												ListTile(
													dense: true,
													contentPadding: EdgeInsets.zero,
													leading: Icon(iconoTipoUnidad(pieza.tipo)),
													title: Text('${nombreTipoUnidad(pieza.tipo)} ${pieza.nroSerie}'),
													subtitle: pieza.producto == null ? null : Text(pieza.producto!.nombre),
													trailing: const Icon(Icons.chevron_right),
													onTap: () => _abrirPieza(pieza),
												),
										],
									),
								],
								const SizedBox(height: 12),
								_SeccionHistorial(
									state: state,
									onReintentar: () => context.read<PiezaDetalleBloc>().add(const PiezaDetalleRefrescada()),
								),
							],
						),
					),
				),
			],
		);
	}
}

class _SeccionHistorial extends StatelessWidget {
	final PiezaDetalleState state;
	final VoidCallback onReintentar;

	const _SeccionHistorial({required this.state, required this.onReintentar});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final colorScheme = Theme.of(context).colorScheme;
		final errorCarga = state.errorCarga;

		return SeccionDetalle(
			titulo: 'Historial',
			children: [
				if (!state.completo && errorCarga != null && !state.cargando) ...[
					Text(errorCarga, style: textTheme.bodySmall?.copyWith(color: colorScheme.error)),
					TextButton.icon(
						onPressed: onReintentar,
						icon: const Icon(Icons.refresh),
						label: const Text('Reintentar'),
					),
				] else if (!state.completo)
					const LinearProgressIndicator()
				else if (state.pasos.isEmpty)
					const Text('Sin movimientos registrados.')
				else
					for (final paso in state.pasos)
						ListTile(
							dense: true,
							contentPadding: EdgeInsets.zero,
							leading: Icon(iconoMovimiento(paso.tipo), size: 20, color: colorScheme.primary),
							title: Text(paso.titulo),
							subtitle: Text(
								[
									[
										formatearFechaFabrica(paso.fecha),
										if (paso.usuario != null) paso.usuario!,
									].join(' · '),
									if (paso.observacion != null) paso.observacion!,
								].join('\n'),
							),
						),
			],
		);
	}
}

class _ErrorCarga extends StatelessWidget {
	final String mensaje;
	final VoidCallback onReintentar;

	const _ErrorCarga({required this.mensaje, required this.onReintentar});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 24),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text(mensaje, textAlign: TextAlign.center),
						const SizedBox(height: 12),
						OutlinedButton.icon(
							onPressed: onReintentar,
							icon: const Icon(Icons.refresh),
							label: const Text('Reintentar'),
						),
					],
				),
			),
		);
	}
}
