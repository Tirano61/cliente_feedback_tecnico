import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/causa.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/componente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/ingreso.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/reglas_ingreso.dart';
import 'package:equatable/equatable.dart';

class IngresoDetalleState extends Equatable {
	final String? ingresoId;
	final Ingreso? ingreso;
	final bool cargando;

	/// El ingreso no se pudo cargar y no hay nada que mostrar.
	final String? errorCarga;

	/// Accion en curso (el boton y el dialogo muestran que esta trabajando).
	final AccionIngreso? accionEnCurso;

	/// Por que se rechazo la ultima accion, tal cual (lo muestra el dialogo,
	/// que queda abierto con lo que el tecnico cargo).
	final String? errorAccion;

	/// Catalogos para cargar la falla: componentes del modelo de la pieza y
	/// causas.
	final List<Componente> componentes;
	final List<Causa> causas;
	final bool cargandoCatalogosFalla;
	final String? errorCatalogosFalla;

	/// Ya se trajeron para este ingreso (no se vuelven a pedir en cada dialogo).
	final bool catalogosFallaCargados;

	/// Mensajes de un solo uso para el snackbar.
	final String? exitoMensaje;
	final String? errorMensaje;

	const IngresoDetalleState({
		this.ingresoId,
		this.ingreso,
		this.cargando = false,
		this.errorCarga,
		this.accionEnCurso,
		this.errorAccion,
		this.componentes = const [],
		this.causas = const [],
		this.cargandoCatalogosFalla = false,
		this.errorCatalogosFalla,
		this.catalogosFallaCargados = false,
		this.exitoMensaje,
		this.errorMensaje,
	});

	bool get procesandoAccion => accionEnCurso != null;

	/// Botones del detalle: solo los que corresponden al tipo y al estado.
	List<AccionIngresoDisponible> get acciones {
		final actual = ingreso;
		return actual == null ? const [] : ReglasIngreso.acciones(actual);
	}

	/// Que pasa con la pieza ahora, cuando no hay acciones para esta app.
	String? get aviso {
		final actual = ingreso;
		return actual == null ? null : ReglasIngreso.aviso(actual);
	}

	/// Sin modelo de la pieza no hay catalogo de componentes: solo "otro".
	bool get tieneModelo => (ingreso?.unidad.producto?.id ?? '').trim().isNotEmpty;

	/// `exitoMensaje` y `errorMensaje` no se arrastran: valen para un emit.
	IngresoDetalleState copyWith({
		Ingreso? ingreso,
		bool? cargando,
		String? errorCarga,
		bool limpiarErrorCarga = false,
		AccionIngreso? accionEnCurso,
		bool limpiarAccionEnCurso = false,
		String? errorAccion,
		bool limpiarErrorAccion = false,
		List<Componente>? componentes,
		List<Causa>? causas,
		bool? cargandoCatalogosFalla,
		String? errorCatalogosFalla,
		bool limpiarErrorCatalogosFalla = false,
		bool? catalogosFallaCargados,
		String? exitoMensaje,
		String? errorMensaje,
	}) {
		return IngresoDetalleState(
			ingresoId: ingresoId,
			ingreso: ingreso ?? this.ingreso,
			cargando: cargando ?? this.cargando,
			errorCarga: limpiarErrorCarga ? null : (errorCarga ?? this.errorCarga),
			accionEnCurso: limpiarAccionEnCurso ? null : (accionEnCurso ?? this.accionEnCurso),
			errorAccion: limpiarErrorAccion ? null : (errorAccion ?? this.errorAccion),
			componentes: componentes ?? this.componentes,
			causas: causas ?? this.causas,
			cargandoCatalogosFalla: cargandoCatalogosFalla ?? this.cargandoCatalogosFalla,
			errorCatalogosFalla: limpiarErrorCatalogosFalla
					? null
					: (errorCatalogosFalla ?? this.errorCatalogosFalla),
			catalogosFallaCargados: catalogosFallaCargados ?? this.catalogosFallaCargados,
			exitoMensaje: exitoMensaje,
			errorMensaje: errorMensaje,
		);
	}

	@override
	List<Object?> get props => [
				ingresoId,
				ingreso,
				cargando,
				errorCarga,
				accionEnCurso,
				errorAccion,
				componentes,
				causas,
				cargandoCatalogosFalla,
				errorCatalogosFalla,
				catalogosFallaCargados,
				exitoMensaje,
				errorMensaje,
			];
}
