import 'package:equatable/equatable.dart';

enum Canal { campo, remoto, fabrica }

class Servicio extends Equatable {
	final String id;
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
	final String diagnosticoCatId;
	final String resolucionId;
	final String? observaciones;
	final List<String> productoIds;

	final String tecnicoId;
	final DateTime? fecha;
	final bool resuelto;
	final bool aprobado;

	const Servicio({
		required this.id,
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
		required this.diagnosticoCatId,
		required this.resolucionId,
		this.observaciones,
		required this.productoIds,
		this.tecnicoId = '',
		this.fecha,
		this.resuelto = true,
		this.aprobado = false,
	});

	@override
	List<Object?> get props => [
				id,
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
				diagnosticoCatId,
				resolucionId,
				observaciones,
				productoIds,
				tecnicoId,
				fecha,
				resuelto,
				aprobado,
			];
}
