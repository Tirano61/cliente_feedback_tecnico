import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/detalle_fabrica.dart'
		show iconoTipoUnidad;
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/widgets/selector_modelo_pieza.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/cambios_pieza_formulario.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Cambio de placa/celda" del servicio de campo (opcional, puede haber mas
/// de uno). Se registran en el indicador del equipo al guardar el servicio.
class SeccionCambiosPieza extends StatelessWidget {
	final ServicioFormularioState estado;

	const SeccionCambiosPieza({required this.estado, super.key});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final bloqueado = estado.guardando;
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text(
					'Cambio de placa/celda (opcional)',
					style: textTheme.titleSmall?.copyWith(fontSize: 11),
				),
				const SizedBox(height: 4),
				Text(estado.textoIndicadorCambiosPieza, style: textTheme.bodySmall),
				for (var i = 0; i < estado.cambiosPieza.length; i++) ...[
					const SizedBox(height: 8),
					_FilaCambioPieza(
						key: ValueKey<int>(estado.cambiosPieza[i].id),
						numero: i + 1,
						cambio: estado.cambiosPieza[i],
						reacondicionadas: estado.reacondicionadas[estado.cambiosPieza[i].tipo],
						bloqueado: bloqueado,
					),
				],
				const SizedBox(height: 8),
				Wrap(
					spacing: 8,
					runSpacing: 8,
					children: [
						for (final tipo in CambioPiezaFormulario.tipos)
							OutlinedButton.icon(
								onPressed: bloqueado
										? null
										: () {
												context.read<ServicioBloc>().add(ServicioCambioPiezaAgregado(tipo: tipo));
											},
								icon: Icon(iconoTipoUnidad(tipo), size: 18),
								label: Text('Agregar ${nombreTipoUnidad(tipo).toLowerCase()}'),
							),
					],
				),
			],
		);
	}
}

class _FilaCambioPieza extends StatefulWidget {
	final int numero;
	final CambioPiezaFormulario cambio;
	final ReacondicionadasPieza? reacondicionadas;
	final bool bloqueado;

	const _FilaCambioPieza({
		required this.numero,
		required this.cambio,
		required this.reacondicionadas,
		required this.bloqueado,
		super.key,
	});

	@override
	State<_FilaCambioPieza> createState() => _FilaCambioPiezaState();
}

class _FilaCambioPiezaState extends State<_FilaCambioPieza> {
	late final TextEditingController _nroSerieController =
			TextEditingController(text: widget.cambio.nroSerie);
	late final TextEditingController _retiradaController =
			TextEditingController(text: widget.cambio.retiradaNroSerie);

	@override
	void didUpdateWidget(covariant _FilaCambioPieza oldWidget) {
		super.didUpdateWidget(oldWidget);
		// Elegir una reacondicionada completa el campo; lo que se tipea no se pisa.
		_sincronizar(_nroSerieController, widget.cambio.nroSerie);
		_sincronizar(_retiradaController, widget.cambio.retiradaNroSerie);
	}

	@override
	void dispose() {
		_nroSerieController.dispose();
		_retiradaController.dispose();
		super.dispose();
	}

	static void _sincronizar(TextEditingController controller, String valor) {
		if (controller.text == valor) {
			return;
		}
		controller.value = TextEditingValue(
			text: valor,
			selection: TextSelection.collapsed(offset: valor.length),
		);
	}

	void _cambiar(ServicioCambioPiezaCambiado evento) {
		context.read<ServicioBloc>().add(evento);
	}

	@override
	Widget build(BuildContext context) {
		final cambio = widget.cambio;
		final bloqueado = widget.bloqueado;
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: colorScheme.outlineVariant),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Text('Cambio ${widget.numero}', style: textTheme.labelLarge),
							const SizedBox(width: 12),
							Expanded(
								child: Wrap(
									spacing: 8,
									children: [
										for (final tipo in CambioPiezaFormulario.tipos)
											ChoiceChip(
												avatar: Icon(iconoTipoUnidad(tipo), size: 18),
												showCheckmark: false,
												visualDensity: VisualDensity.compact,
												label: Text(nombreTipoUnidad(tipo)),
												selected: cambio.tipo == tipo,
												onSelected: bloqueado
														? null
														: (_) => _cambiar(ServicioCambioPiezaCambiado(id: cambio.id, tipo: tipo)),
											),
									],
								),
							),
							IconButton(
								tooltip: 'Quitar cambio',
								onPressed: bloqueado
										? null
										: () {
												context.read<ServicioBloc>().add(ServicioCambioPiezaQuitado(id: cambio.id));
											},
								icon: const Icon(Icons.delete_outline),
							),
						],
					),
					Padding(
						padding: const EdgeInsets.only(right: 8),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								_Reacondicionadas(
									cambio: cambio,
									reacondicionadas: widget.reacondicionadas,
									bloqueado: bloqueado,
								),
								const SizedBox(height: 8),
								TextField(
									controller: _nroSerieController,
									enabled: !bloqueado,
									textCapitalization: TextCapitalization.characters,
									decoration: InputDecoration(
										isDense: true,
										labelText: 'N° de serie de la ${cambio.nombreTipo} que se pone *',
										helperText: 'Si es nueva, queda registrada con este número.',
									),
									onChanged: (valor) => _cambiar(ServicioCambioPiezaCambiado(id: cambio.id, nroSerie: valor)),
								),
								const SizedBox(height: 8),
								SelectorModeloPieza(
									palabra: cambio.palabraModelo,
									productoId: cambio.productoId,
									habilitado: !bloqueado,
									onChanged: (valor) {
										_cambiar(
											ServicioCambioPiezaCambiado(
												id: cambio.id,
												productoId: valor,
												limpiarProducto: valor == null,
											),
										);
									},
								),
								const SizedBox(height: 8),
								TextField(
									controller: _retiradaController,
									enabled: !bloqueado,
									textCapitalization: TextCapitalization.characters,
									decoration: InputDecoration(
										isDense: true,
										labelText: 'N° de serie de la ${cambio.nombreTipo} que se saca (opcional)',
										helperText: cambio.avisoRetirada,
									),
									onChanged: (valor) {
										_cambiar(ServicioCambioPiezaCambiado(id: cambio.id, retiradaNroSerie: valor));
									},
								),
							],
						),
					),
				],
			),
		);
	}
}

/// Reacondicionadas disponibles del tipo del cambio: tocar una completa el
/// numero de serie y el modelo.
class _Reacondicionadas extends StatelessWidget {
	final CambioPiezaFormulario cambio;
	final ReacondicionadasPieza? reacondicionadas;
	final bool bloqueado;

	const _Reacondicionadas({
		required this.cambio,
		required this.reacondicionadas,
		required this.bloqueado,
	});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;
		final colorScheme = Theme.of(context).colorScheme;
		final lista = reacondicionadas ?? const ReacondicionadasPieza.cargando();
		final error = lista.error;
		final aviso = lista.aviso(cambio.tipo);

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text('Reacondicionadas disponibles:', style: textTheme.bodySmall),
				const SizedBox(height: 6),
				if (lista.cargando)
					const LinearProgressIndicator(minHeight: 2)
				else if (error != null)
					Row(
						children: [
							Expanded(
								child: Text(error, style: textTheme.bodySmall?.copyWith(color: colorScheme.error)),
							),
							TextButton.icon(
								onPressed: () {
									context.read<ServicioBloc>().add(
										ServicioReacondicionadasSolicitadas(tipo: cambio.tipo),
									);
								},
								icon: const Icon(Icons.refresh),
								label: const Text('Reintentar'),
							),
						],
					)
				else if (lista.unidades.isNotEmpty)
					Wrap(
						spacing: 8,
						runSpacing: 8,
						children: [
							for (final unidad in lista.unidades)
								ChoiceChip(
									avatar: const Icon(Icons.recycling, size: 18),
									showCheckmark: false,
									visualDensity: VisualDensity.compact,
									label: Text(_etiquetaPieza(unidad)),
									selected: cambio.usa(unidad),
									onSelected: bloqueado
											? null
											: (_) {
													context.read<ServicioBloc>().add(
														ServicioCambioPiezaReacondicionadaElegida(id: cambio.id, unidad: unidad),
													);
												},
								),
						],
					),
				if (aviso != null) ...[
					const SizedBox(height: 6),
					Text(aviso, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
				],
			],
		);
	}
}

String _etiquetaPieza(Unidad pieza) {
	final modelo = (pieza.producto?.nombre ?? '').trim();
	return modelo.isEmpty ? pieza.nroSerie : '${pieza.nroSerie} · $modelo';
}

/// En el aviso de exito: que paso con cada cambio de placa/celda y
/// "Reintentar" para los que quedaron pendientes.
class ResultadoCambiosPiezaVista extends StatelessWidget {
	final ResultadoCambiosPieza resultado;
	final VoidCallback onReintentar;

	const ResultadoCambiosPiezaVista({
		required this.resultado,
		required this.onReintentar,
		super.key,
	});

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: colorScheme.surfaceContainerHighest,
				borderRadius: BorderRadius.circular(10),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text('Cambio de placa/celda', style: textTheme.titleSmall),
					for (final cambio in resultado.cambios) ...[
						ListTile(
							dense: true,
							contentPadding: EdgeInsets.zero,
							leading: Icon(
								cambio.pendiente ? Icons.sync_problem : Icons.check_circle,
								color: cambio.pendiente ? colorScheme.error : colorScheme.primary,
							),
							title: Text(cambio.texto),
							subtitle: cambio.pendiente
									? Text(cambio.error!, style: TextStyle(color: colorScheme.error))
									: null,
						),
						for (final retirada in cambio.textosRetiradas)
							ListTile(
								dense: true,
								contentPadding: const EdgeInsets.only(left: 40),
								leading: const Icon(Icons.outbox_outlined),
								title: Text('Sale: $retirada'),
							),
					],
					if (resultado.hayRetiradas) ...[
						const SizedBox(height: 4),
						Text(ResultadoCambiosPieza.recordatorioRetiradas, style: textTheme.bodySmall),
					],
					if (resultado.pendientes > 0) ...[
						const SizedBox(height: 8),
						Text(
							'El servicio ya quedó guardado. Lo pendiente queda en el dispositivo: '
							'reintentalo ahora o después desde Mis servicios.',
							style: textTheme.bodySmall,
						),
						const SizedBox(height: 8),
						SizedBox(
							width: double.infinity,
							child: OutlinedButton.icon(
								onPressed: resultado.reintentando ? null : onReintentar,
								icon: resultado.reintentando
										? const SizedBox(
												height: 16,
												width: 16,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Icon(Icons.refresh),
								label: Text('Reintentar cambios pendientes (${resultado.pendientes})'),
							),
						),
					],
				],
			),
		);
	}
}
