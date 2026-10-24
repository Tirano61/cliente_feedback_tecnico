import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:equatable/equatable.dart';

/// Reparacion (dato operativo) de un ingreso. Se carga una sola vez.
class Reparacion extends Equatable {
	final String? id;
	final ResultadoReparacion resultado;
	final String? trabajoRealizado;
	final String? componentesReemplazados;
	final UsuarioFabrica? usuario;
	final DateTime? fecha;

	const Reparacion({
		this.id,
		required this.resultado,
		this.trabajoRealizado,
		this.componentesReemplazados,
		this.usuario,
		this.fecha,
	});

	@override
	List<Object?> get props => [
				id,
				resultado,
				trabajoRealizado,
				componentesReemplazados,
				usuario,
				fecha,
			];
}
