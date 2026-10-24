import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/falla.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/reparacion.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:equatable/equatable.dart';

/// Una placa o celda que entra a fabrica para revision.
class Ingreso extends Equatable {
	final String id;
	final int numero;
	final String unidadId;
	final Unidad unidad;
	final ClienteFabrica? clienteOrigen;
	final String? indicadorOrigenId;
	final IndicadorFabrica? indicadorOrigen;
	final String? recepcionId;
	final String? servicioId;
	final UsuarioFabrica? tecnico;
	final DateTime? fechaIngreso;
	final String? observacionTecnico;
	final EstadoIngreso estado;
	final Falla? falla;
	final Reparacion? reparacion;

	const Ingreso({
		required this.id,
		required this.numero,
		required this.unidadId,
		required this.unidad,
		this.clienteOrigen,
		this.indicadorOrigenId,
		this.indicadorOrigen,
		this.recepcionId,
		this.servicioId,
		this.tecnico,
		this.fechaIngreso,
		this.observacionTecnico,
		required this.estado,
		this.falla,
		this.reparacion,
	});

	@override
	List<Object?> get props => [
				id,
				numero,
				unidadId,
				unidad,
				clienteOrigen,
				indicadorOrigenId,
				indicadorOrigen,
				recepcionId,
				servicioId,
				tecnico,
				fechaIngreso,
				observacionTecnico,
				estado,
				falla,
				reparacion,
			];
}
