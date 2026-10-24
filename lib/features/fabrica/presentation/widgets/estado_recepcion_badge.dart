import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_recepcion.dart';
import 'package:flutter/material.dart';

class EstadoRecepcionBadge extends StatelessWidget {
	final EstadoRecepcion estado;

	const EstadoRecepcionBadge({required this.estado, super.key});

	static Color color(EstadoRecepcion estado) {
		return switch (estado) {
			EstadoRecepcion.recibido => const Color(0xFF1D4E89),
			EstadoRecepcion.enReparacion => const Color(0xFFE65100),
			EstadoRecepcion.esperandoPresupuesto => const Color(0xFF5E35B1),
			EstadoRecepcion.listoParaDevolver => const Color(0xFF2E7D32),
			EstadoRecepcion.devuelto => const Color(0xFF455A64),
			EstadoRecepcion.desconocido => const Color(0xFF455A64),
		};
	}

	@override
	Widget build(BuildContext context) {
		final colorEstado = color(estado);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
			decoration: BoxDecoration(
				color: colorEstado.withValues(alpha: 0.14),
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				nombreEstadoRecepcion(estado),
				style: TextStyle(
					color: colorEstado,
					fontWeight: FontWeight.w700,
					fontSize: 12,
				),
			),
		);
	}
}
