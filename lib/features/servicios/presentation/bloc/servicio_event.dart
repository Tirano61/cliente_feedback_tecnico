import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

abstract class ServicioEvent extends Equatable {
	const ServicioEvent();

	@override
	List<Object?> get props => [];
}

class ServicioFormularioCambiado extends ServicioEvent {
	final Canal? canal;
	final String? zonaId;
	final List<String>? productoIdsSeleccionados;
	final String? clienteId;
	final String? lugarDetalle;
	final String? equipoNroSerie;
	final String? equipoModelo;
	final String? equipoUbicacion;
	final String? equipoAnio;
	final String? partesFallaronTexto;
	final String? km;
	final String? sintoma;
	final List<String>? diagnosticoCatIdsSeleccionados;
	final String? diagnosticoDetalle;
	final String? resolucionId;
	final String? observaciones;

	const ServicioFormularioCambiado({
		this.canal,
		this.zonaId,
		this.productoIdsSeleccionados,
		this.clienteId,
		this.lugarDetalle,
		this.equipoNroSerie,
		this.equipoModelo,
		this.equipoUbicacion,
		this.equipoAnio,
		this.partesFallaronTexto,
		this.km,
		this.sintoma,
		this.diagnosticoCatIdsSeleccionados,
		this.diagnosticoDetalle,
		this.resolucionId,
		this.observaciones,
	});

	@override
	List<Object?> get props => [
				canal,
				zonaId,
				productoIdsSeleccionados,
				clienteId,
				lugarDetalle,
				equipoNroSerie,
				equipoModelo,
				equipoUbicacion,
				equipoAnio,
				partesFallaronTexto,
				km,
				sintoma,
				diagnosticoCatIdsSeleccionados,
				diagnosticoDetalle,
				resolucionId,
				observaciones,
			];
}

class ServicioBuscarClienteSolicitado extends ServicioEvent {
	final String query;

	const ServicioBuscarClienteSolicitado({required this.query});

	@override
	List<Object?> get props => [query];
}

class ServicioClienteSeleccionado extends ServicioEvent {
	final Cliente cliente;

	const ServicioClienteSeleccionado({required this.cliente});

	@override
	List<Object?> get props => [cliente];
}

class ServicioCrearClienteRapidoSolicitado extends ServicioEvent {
	final String payloadJson;

	const ServicioCrearClienteRapidoSolicitado({required this.payloadJson});

	@override
	List<Object?> get props => [payloadJson];
}

class ServicioGuardarPressed extends ServicioEvent {
	const ServicioGuardarPressed();
}

class MisServiciosSolicitados extends ServicioEvent {
	const MisServiciosSolicitados();
}

class ServicioFormularioReiniciado extends ServicioEvent {
	const ServicioFormularioReiniciado();
}


