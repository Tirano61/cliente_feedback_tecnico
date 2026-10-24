import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/unidad.dart';
import 'package:equatable/equatable.dart';

/// Respuesta de poner una placa o celda en un indicador. `retiradas` quedan
/// en estado `retirada` hasta su ingreso a fabrica.
class ResultadoAsignacion extends Equatable {
	final IndicadorFabrica indicador;
	final Unidad instalada;
	final List<Unidad> retiradas;

	const ResultadoAsignacion({
		required this.indicador,
		required this.instalada,
		this.retiradas = const [],
	});

	@override
	List<Object?> get props => [indicador, instalada, retiradas];
}
