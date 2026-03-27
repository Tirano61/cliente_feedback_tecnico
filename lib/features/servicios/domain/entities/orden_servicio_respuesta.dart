import 'package:equatable/equatable.dart';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/documento_orden.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';

class OrdenServicioRespuesta extends Equatable {
	final bool replayed;
	final String servicioId;
	final String idempotencyKey;
	final String estadoOrden;
	final int version;
	final DateTime? fechaHoraServicio;
	final String? timezoneIana;
	final int? utcOffsetMinutos;
	final Servicio servicio;
	final Facturacion? facturacion;
	final List<FacturacionItem> facturacionItems;
	final DocumentoOrden? documento;

	const OrdenServicioRespuesta({
		required this.replayed,
		required this.servicioId,
		required this.idempotencyKey,
		required this.estadoOrden,
		required this.version,
		this.fechaHoraServicio,
		this.timezoneIana,
		this.utcOffsetMinutos,
		required this.servicio,
		this.facturacion,
		this.facturacionItems = const [],
		this.documento,
	});

	@override
	List<Object?> get props => [
				replayed,
				servicioId,
				idempotencyKey,
				estadoOrden,
				version,
				fechaHoraServicio,
				timezoneIana,
				utcOffsetMinutos,
				servicio,
				facturacion,
				facturacionItems,
				documento,
			];
}
