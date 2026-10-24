import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:equatable/equatable.dart';

/// Un paso del historial de estados de una recepcion.
class CambioEstadoRecepcion extends Equatable {
	final EstadoRecepcion estado;
	final DateTime? fecha;
	final String? usuarioId;
	final String? usuarioNombre;
	final String? observacion;

	const CambioEstadoRecepcion({
		required this.estado,
		this.fecha,
		this.usuarioId,
		this.usuarioNombre,
		this.observacion,
	});

	@override
	List<Object?> get props => [estado, fecha, usuarioId, usuarioNombre, observacion];
}

/// Equipo de un cliente que llega a fabrica. Se identifica por el numero de
/// serie del indicador.
///
/// `ingresos`: piezas ingresadas desde esta recepcion. `piezasInstaladas`:
/// placas y celdas que hoy figuran en el indicador.
class Recepcion extends Equatable {
	final String id;
	final int numero;
	final ClienteFabrica cliente;
	final String indicadorId;
	final Unidad indicador;
	final String queLlego;
	final String sintomaReportado;
	final UsuarioFabrica? tecnicoRecepcion;
	final DateTime? fechaRecepcion;
	final EstadoRecepcion estado;
	final List<CambioEstadoRecepcion> historialEstados;
	final String? servicioId;
	final DateTime? fechaDevolucion;
	final FormaDevolucion? formaDevolucion;
	final String? observaciones;
	final List<Ingreso> ingresos;
	final List<Unidad> piezasInstaladas;

	const Recepcion({
		required this.id,
		required this.numero,
		required this.cliente,
		required this.indicadorId,
		required this.indicador,
		required this.queLlego,
		required this.sintomaReportado,
		this.tecnicoRecepcion,
		this.fechaRecepcion,
		required this.estado,
		this.historialEstados = const [],
		this.servicioId,
		this.fechaDevolucion,
		this.formaDevolucion,
		this.observaciones,
		this.ingresos = const [],
		this.piezasInstaladas = const [],
	});

	@override
	List<Object?> get props => [
				id,
				numero,
				cliente,
				indicadorId,
				indicador,
				queLlego,
				sintomaReportado,
				tecnicoRecepcion,
				fechaRecepcion,
				estado,
				historialEstados,
				servicioId,
				fechaDevolucion,
				formaDevolucion,
				observaciones,
				ingresos,
				piezasInstaladas,
			];
}
