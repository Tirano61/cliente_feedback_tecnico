import 'package:equatable/equatable.dart';

enum Canal { campo, remoto, fabrica }

class Servicio extends Equatable {
	final String id;
	final String tecnicoId;
	final String productoId;
	final String zonaId;
	final Canal canal;
	final DateTime fecha;
	final String sintoma;
	final String diagnosticoCatId;
	final String diagnosticoDetalle;
	final String resolucionId;
	final bool resuelto;
	final bool aprobado;
	final String? observaciones;

	const Servicio({
		required this.id,
		required this.tecnicoId,
		required this.productoId,
		required this.zonaId,
		required this.canal,
		required this.fecha,
		required this.sintoma,
		required this.diagnosticoCatId,
		required this.diagnosticoDetalle,
		required this.resolucionId,
		required this.resuelto,
		required this.aprobado,
		this.observaciones,
	});

	@override
	List<Object?> get props => [
				id,
				tecnicoId,
				productoId,
				zonaId,
				canal,
				fecha,
				sintoma,
				diagnosticoCatId,
				diagnosticoDetalle,
				resolucionId,
				resuelto,
				aprobado,
				observaciones,
			];
}
