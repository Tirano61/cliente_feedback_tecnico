import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

abstract class ServicioState extends Equatable {
	const ServicioState();

	@override
	List<Object?> get props => [];
}

class ServicioInitial extends ServicioState {
	const ServicioInitial();
}

class ServicioFormularioState extends ServicioState {
	final Canal? canal;
	final String clienteId;
	final String lugarProvinciaId;
	final String lugarDetalle;
	final String equipoNroSerie;
	final String equipoModelo;
	final String equipoUbicacion;
	final String equipoAnio;
	final String partesFallaronTexto;
	final String km;
	final String sintoma;
	final List<String> diagnosticoCatIdsSeleccionados;
	final String diagnosticoDetalle;
	final String resolucionId;
	final String observaciones;
	final List<String> productoIdsSeleccionados;
	final bool guardando;
	final bool buscandoClientes;
	final bool creandoCliente;
	final List<Cliente> clientesEncontrados;
	final Cliente? clienteSeleccionado;
	final String? errorMensaje;
	final String? exitoMensaje;

	const ServicioFormularioState({
		this.canal,
		this.clienteId = '',
		this.lugarProvinciaId = '',
		this.lugarDetalle = '',
		this.equipoNroSerie = '',
		this.equipoModelo = '',
		this.equipoUbicacion = '',
		this.equipoAnio = '',
		this.partesFallaronTexto = '',
		this.km = '',
		this.sintoma = '',
		this.diagnosticoCatIdsSeleccionados = const [],
		this.diagnosticoDetalle = '',
		this.resolucionId = '',
		this.observaciones = '',
		this.productoIdsSeleccionados = const [],
		this.guardando = false,
		this.buscandoClientes = false,
		this.creandoCliente = false,
		this.clientesEncontrados = const [],
		this.clienteSeleccionado,
		this.errorMensaje,
		this.exitoMensaje,
	});

	ServicioFormularioState copyWith({
		Canal? canal,
		String? clienteId,
		String? lugarProvinciaId,
		String? lugarDetalle,
		String? equipoNroSerie,
		String? equipoModelo,
		String? equipoUbicacion,
		String? equipoAnio,
		String? partesFallaronTexto,
		String? km,
		String? sintoma,
		List<String>? diagnosticoCatIdsSeleccionados,
		String? diagnosticoDetalle,
		String? resolucionId,
		String? observaciones,
		List<String>? productoIdsSeleccionados,
		bool? guardando,
		bool? buscandoClientes,
		bool? creandoCliente,
		List<Cliente>? clientesEncontrados,
		Cliente? clienteSeleccionado,
		String? errorMensaje,
		String? exitoMensaje,
		bool limpiarMensajes = false,
		bool limpiarClienteSeleccionado = false,
	}) {
		return ServicioFormularioState(
			canal: canal ?? this.canal,
			clienteId: clienteId ?? this.clienteId,
			lugarProvinciaId: lugarProvinciaId ?? this.lugarProvinciaId,
			lugarDetalle: lugarDetalle ?? this.lugarDetalle,
			equipoNroSerie: equipoNroSerie ?? this.equipoNroSerie,
			equipoModelo: equipoModelo ?? this.equipoModelo,
			equipoUbicacion: equipoUbicacion ?? this.equipoUbicacion,
			equipoAnio: equipoAnio ?? this.equipoAnio,
			partesFallaronTexto: partesFallaronTexto ?? this.partesFallaronTexto,
			km: km ?? this.km,
			sintoma: sintoma ?? this.sintoma,
			diagnosticoCatIdsSeleccionados:
					diagnosticoCatIdsSeleccionados ?? this.diagnosticoCatIdsSeleccionados,
			diagnosticoDetalle: diagnosticoDetalle ?? this.diagnosticoDetalle,
			resolucionId: resolucionId ?? this.resolucionId,
			observaciones: observaciones ?? this.observaciones,
			productoIdsSeleccionados:
					productoIdsSeleccionados ?? this.productoIdsSeleccionados,
			guardando: guardando ?? this.guardando,
			buscandoClientes: buscandoClientes ?? this.buscandoClientes,
			creandoCliente: creandoCliente ?? this.creandoCliente,
			clientesEncontrados: clientesEncontrados ?? this.clientesEncontrados,
			clienteSeleccionado: limpiarClienteSeleccionado
					? null
					: (clienteSeleccionado ?? this.clienteSeleccionado),
			errorMensaje: limpiarMensajes ? null : errorMensaje,
			exitoMensaje: limpiarMensajes ? null : exitoMensaje,
		);
	}

	@override
	List<Object?> get props => [
				canal,
				clienteId,
				lugarProvinciaId,
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
				productoIdsSeleccionados,
				guardando,
				buscandoClientes,
				creandoCliente,
				clientesEncontrados,
				clienteSeleccionado,
				errorMensaje,
				exitoMensaje,
			];
}

class ServicioGuardando extends ServicioState {
	const ServicioGuardando();
}

class ServicioGuardadoExito extends ServicioState {
	const ServicioGuardadoExito();
}

class ServicioError extends ServicioState {
	final String mensaje;

	const ServicioError({required this.mensaje});

	@override
	List<Object> get props => [mensaje];
}

class MisServiciosLoading extends ServicioState {
	const MisServiciosLoading();
}

class MisServiciosLoaded extends ServicioState {
	final List<Servicio> servicios;

	const MisServiciosLoaded({required this.servicios});

	@override
	List<Object> get props => [servicios];
}


