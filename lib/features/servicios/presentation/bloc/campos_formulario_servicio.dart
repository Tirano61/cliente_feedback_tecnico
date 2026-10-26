import 'package:equatable/equatable.dart';

/// Pasos del formulario, en el orden en que se muestran.
enum PasoFormularioServicio { tipo, datos, falla, facturacion, observaciones }

/// Campos que valida el BLoC al guardar, con el paso donde se cargan.
enum CampoFormularioServicio {
	canal(PasoFormularioServicio.tipo),
	cliente(PasoFormularioServicio.datos),
	zona(PasoFormularioServicio.datos),
	lugarDetalle(PasoFormularioServicio.datos),
	equipoNroSerie(PasoFormularioServicio.datos),
	equipoModelo(PasoFormularioServicio.datos),
	equipoUbicacion(PasoFormularioServicio.datos),
	equipoAnio(PasoFormularioServicio.datos),
	partesFallaron(PasoFormularioServicio.falla),
	sintoma(PasoFormularioServicio.falla),
	diagnosticoCategoria(PasoFormularioServicio.falla),
	diagnosticoDetalle(PasoFormularioServicio.falla),
	resolucion(PasoFormularioServicio.falla),
	productosFalla(PasoFormularioServicio.falla),
	cambiosPieza(PasoFormularioServicio.falla),
	km(PasoFormularioServicio.facturacion),
	precioServicio(PasoFormularioServicio.facturacion),
	valoresFacturacion(PasoFormularioServicio.facturacion);

	final PasoFormularioServicio paso;

	const CampoFormularioServicio(this.paso);
}

/// Aviso de un solo uso al tocar "Guardar" con algo sin completar. El `token`
/// cambia en cada intento: el mismo error dos veces se vuelve a mostrar.
class AvisoValidacionFormulario extends Equatable {
	final int token;
	final CampoFormularioServicio campo;
	final String mensaje;

	const AvisoValidacionFormulario({
		required this.token,
		required this.campo,
		required this.mensaje,
	});

	/// El paso al que hay que llevar al tecnico para corregirlo.
	PasoFormularioServicio get paso => campo.paso;

	@override
	List<Object?> get props => [token, campo, mensaje];
}
