import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_ingreso.dart';
import 'package:flutter/material.dart';

class EstadoIngresoBadge extends StatelessWidget {
	final EstadoIngreso estado;

	const EstadoIngresoBadge({required this.estado, super.key});

	static Color color(EstadoIngreso estado) {
		return switch (estado) {
			EstadoIngreso.enServicioTecnico => const Color(0xFF1D4E89),
			EstadoIngreso.derivadoDesarrollo => const Color(0xFF5E35B1),
			EstadoIngreso.reparado => const Color(0xFF2E7D32),
			EstadoIngreso.devueltoAServicioTecnico => const Color(0xFF2E7D32),
			EstadoIngreso.descartado => const Color(0xFFC62828),
			EstadoIngreso.desconocido => const Color(0xFF455A64),
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
				nombreEstadoIngreso(estado),
				style: TextStyle(
					color: colorEstado,
					fontWeight: FontWeight.w700,
					fontSize: 12,
				),
			),
		);
	}
}
