import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:equatable/equatable.dart';

/// Falla (feedback) cargada sobre un ingreso: componente que fallo + causa.
///
/// Si el componente no esta en el catalogo viene `componenteOtro` y
/// `componente` queda null.
class Falla extends Equatable {
	final String id;
	final Componente? componente;
	final String? componenteOtro;
	final Causa? causa;
	final String? detalle;
	final UsuarioFabrica? usuario;
	final DateTime? fecha;

	const Falla({
		required this.id,
		this.componente,
		this.componenteOtro,
		this.causa,
		this.detalle,
		this.usuario,
		this.fecha,
	});

	@override
	List<Object?> get props => [
				id,
				componente,
				componenteOtro,
				causa,
				detalle,
				usuario,
				fecha,
			];
}
