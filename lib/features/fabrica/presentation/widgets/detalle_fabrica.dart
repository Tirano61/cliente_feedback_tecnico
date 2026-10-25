import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:flutter/material.dart';

// Piezas comunes de los detalles de fabrica (recepcion e ingreso).

/// Tarjeta con titulo de una seccion del detalle.
class SeccionDetalle extends StatelessWidget {
	final String titulo;
	final List<Widget> children;

	const SeccionDetalle({required this.titulo, required this.children, super.key});

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

/// Dato del detalle: etiqueta a la izquierda, valor a la derecha.
class FilaDetalle extends StatelessWidget {
	final String label;
	final String valor;

	const FilaDetalle({required this.label, required this.valor, super.key});

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

/// Por que el backend rechazo la accion, tal cual, dentro del dialogo.
class ErrorAccionDetalle extends StatelessWidget {
	final String? mensaje;

	const ErrorAccionDetalle({required this.mensaje, super.key});

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

/// Indicador de trabajo en un boton relleno.
class ProgresoBoton extends StatelessWidget {
	final Color? color;

	const ProgresoBoton({this.color = Colors.white, super.key});

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			height: 16,
			width: 16,
			child: CircularProgressIndicator(strokeWidth: 2, color: color),
		);
	}
}

IconData iconoTipoUnidad(TipoUnidad tipo) {
	return switch (tipo) {
		TipoUnidad.indicador => Icons.monitor_weight_outlined,
		TipoUnidad.placa => Icons.memory,
		TipoUnidad.celda => Icons.sensors,
		TipoUnidad.desconocido => Icons.help_outline,
	};
}

IconData iconoMovimiento(TipoMovimiento tipo) {
	return switch (tipo) {
		TipoMovimiento.alta => Icons.fiber_new_outlined,
		TipoMovimiento.instalacion => Icons.login,
		TipoMovimiento.retiro => Icons.logout,
		TipoMovimiento.recepcion => Icons.inventory_2_outlined,
		TipoMovimiento.devolucionCliente => Icons.local_shipping_outlined,
		TipoMovimiento.ingresoFabrica => Icons.move_to_inbox_outlined,
		TipoMovimiento.derivacionDesarrollo => Icons.engineering_outlined,
		TipoMovimiento.reparada => Icons.build_circle_outlined,
		TipoMovimiento.descartada => Icons.delete_outline,
		TipoMovimiento.vueltaAServicioTecnico => Icons.recycling,
		TipoMovimiento.desconocido => Icons.circle_outlined,
	};
}

String textoSeguro(String? valor) {
	final limpio = (valor ?? '').trim();
	return limpio.isEmpty ? 'Sin dato' : limpio;
}

String formatearFechaFabrica(DateTime? fecha) {
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
