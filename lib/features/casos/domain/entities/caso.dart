import 'package:equatable/equatable.dart';

enum Canal { campo, remoto, fabrica }

class Caso extends Equatable {
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
	final String? observaciones;

	const Caso({
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
				observaciones,
			];
}
