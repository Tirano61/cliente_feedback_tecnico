import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/textos_unidad.dart';
import 'package:flutter/material.dart';

class EstadoUnidadBadge extends StatelessWidget {
	final EstadoUnidad estado;

	const EstadoUnidadBadge({required this.estado, super.key});

	static Color color(EstadoUnidad estado) {
		return switch (estado) {
			EstadoUnidad.instalada => const Color(0xFF1D4E89),
			EstadoUnidad.retirada => const Color(0xFFEF6C00),
			EstadoUnidad.enServicioTecnico => const Color(0xFF00838F),
			EstadoUnidad.enDesarrollo => const Color(0xFF5E35B1),
			EstadoUnidad.reacondicionadaDisponible => const Color(0xFF2E7D32),
			EstadoUnidad.descartada => const Color(0xFFC62828),
			EstadoUnidad.desconocido => const Color(0xFF455A64),
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
				nombreEstadoUnidad(estado),
				style: TextStyle(
					color: colorEstado,
					fontWeight: FontWeight.w700,
					fontSize: 12,
				),
			),
		);
	}
}
