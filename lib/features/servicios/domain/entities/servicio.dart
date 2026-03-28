import 'package:equatable/equatable.dart';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/documento_orden.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';

enum Canal { campo, remoto, fabrica }

class Servicio extends Equatable {
	final String id;
	final String? idempotencyKey;
	final DateTime? fechaHoraServicio;
	final String? timezoneIana;
	final int? utcOffsetMinutos;
	final Canal canal;
	final String clienteId;
	final String lugarProvinciaId;
	final String lugarDetalle;
	final String equipoNroSerie;
	final String equipoModelo;
	final String equipoUbicacion;
	final int equipoAnio;
	final List<String> partesFallaron;
	final int km;
	final String sintoma;
	final String diagnosticoDetalle;
	final List<String> diagnosticoCatIds;
	final String resolucionId;
	final String? observaciones;
	final List<ProductoFalla> productosFalla;
	final Facturacion? facturacion;
	final List<FacturacionItem> facturacionItems;
	final DocumentoOrden? documento;

	final String tecnicoId;
	final DateTime? fecha;
	final bool resuelto;
	final bool aprobado;

	const Servicio({
		required this.id,
		this.idempotencyKey,
		this.fechaHoraServicio,
		this.timezoneIana,
		this.utcOffsetMinutos,
		required this.canal,
		required this.clienteId,
		required this.lugarProvinciaId,
		required this.lugarDetalle,
		required this.equipoNroSerie,
		required this.equipoModelo,
		required this.equipoUbicacion,
		required this.equipoAnio,
		required this.partesFallaron,
		required this.km,
		required this.sintoma,
		required this.diagnosticoDetalle,
		required this.diagnosticoCatIds,
		required this.resolucionId,
		this.observaciones,
		this.productosFalla = const [],
		this.facturacion,
		this.facturacionItems = const [],
		this.documento,
		this.tecnicoId = '',
		this.fecha,
		this.resuelto = true,
		this.aprobado = false,
	});

	@override
	List<Object?> get props => [
				id,
				idempotencyKey,
				fechaHoraServicio,
				timezoneIana,
				utcOffsetMinutos,
				canal,
				clienteId,
				lugarProvinciaId,
				lugarDetalle,
				equipoNroSerie,
				equipoModelo,
				equipoUbicacion,
				equipoAnio,
				partesFallaron,
				km,
				sintoma,
				diagnosticoDetalle,
				diagnosticoCatIds,
				resolucionId,
				observaciones,
				productosFalla,
				facturacion,
				facturacionItems,
				documento,
				tecnicoId,
				fecha,
				resuelto,
				aprobado,
			];
}
