class ApiConstants {
	//static const String baseUrl = 'https://l002n256-3000.brs.devtunnels.ms/api/v1';
	static const String baseUrl = 'https://backend-feedback-11c2.onrender.com/api/v1';

	static const String login = '/auth/login';
	static const String register = '/auth/register';

	static const String diagnosticos = '/cat/diagnosticos';
	static const String resoluciones = '/cat/resoluciones';
	static const String zonas = '/zonas';
	static const String categoriasProducto = '/categorias-producto';
	static const String productos = '/productos';
	static const String clientesBuscar = '/clientes/buscar';
	static const String clientes = '/clientes';
	static const String repuestos = '/repuestos';
	static const String cotizacion = '/cotizacion';
	static const String tarifaKm = '/tarifa-km';

	static const String servicios = '/servicios';
	static const String serviciosMios = '/servicios/mios';
	static const String liquidacionesMias = '/liquidaciones/mias';

	static String servicio(String servicioId) {
		return '/servicios/$servicioId';
	}

	static String servicioDocumento(String servicioId) {
		return '/servicios/$servicioId/documento';
	}

	static String servicioDocumentoPdf(String servicioId) {
		return '/servicios/$servicioId/documento/pdf';
	}

	static String servicioDocumentoFirmado(String servicioId) {
		return '/servicios/$servicioId/documento/firmado';
	}

	static String liquidacionItems(String liquidacionId) {
		return '/liquidaciones/$liquidacionId/items';
	}

	static const String fabricaComponentes = '/fabrica/componentes';
	static const String fabricaCausas = '/fabrica/causas';
	static const String fabricaUnidades = '/fabrica/unidades';
	static const String fabricaAsignaciones = '/fabrica/unidades/asignaciones';
	static const String fabricaRecepciones = '/fabrica/recepciones';
	static const String fabricaIngresos = '/fabrica/ingresos';

	static String fabricaUnidad(String unidadId) {
		return '/fabrica/unidades/$unidadId';
	}

	static String fabricaUnidadHistorial(String unidadId) {
		return '/fabrica/unidades/$unidadId/historial';
	}

	static String fabricaRecepcion(String recepcionId) {
		return '/fabrica/recepciones/$recepcionId';
	}

	static String fabricaRecepcionEstado(String recepcionId) {
		return '/fabrica/recepciones/$recepcionId/estado';
	}

	static String fabricaRecepcionServicio(String recepcionId) {
		return '/fabrica/recepciones/$recepcionId/servicio';
	}

	static String fabricaRecepcionDevolucion(String recepcionId) {
		return '/fabrica/recepciones/$recepcionId/devolucion';
	}

	static String fabricaIngreso(String ingresoId) {
		return '/fabrica/ingresos/$ingresoId';
	}

	static String fabricaIngresoDerivar(String ingresoId) {
		return '/fabrica/ingresos/$ingresoId/derivar';
	}

	static String fabricaIngresoFalla(String ingresoId) {
		return '/fabrica/ingresos/$ingresoId/falla';
	}

	static String fabricaIngresoReparacion(String ingresoId) {
		return '/fabrica/ingresos/$ingresoId/reparacion';
	}

	static String fabricaIngresoVueltaServicioTecnico(String ingresoId) {
		return '/fabrica/ingresos/$ingresoId/vuelta-servicio-tecnico';
	}
}
