/// Lectura tolerante de los campos de las respuestas de fabrica: un campo que
/// falta o viene con otro tipo no rompe el parseo.
class JsonFabrica {
	const JsonFabrica._();

	static String texto(dynamic valor) => valor?.toString() ?? '';

	/// null si falta o es un texto vacio.
	static String? textoOpcional(dynamic valor) {
		if (valor == null) {
			return null;
		}
		final texto = valor.toString().trim();
		return texto.isEmpty ? null : texto;
	}

	static int entero(dynamic valor) {
		if (valor is num) {
			return valor.toInt();
		}
		return int.tryParse(texto(valor)) ?? 0;
	}

	static bool booleano(dynamic valor, {required bool porDefecto}) {
		if (valor is bool) {
			return valor;
		}
		return switch (texto(valor).toLowerCase()) {
			'true' => true,
			'false' => false,
			_ => porDefecto,
		};
	}

	static DateTime? fecha(dynamic valor) => DateTime.tryParse(texto(valor));

	static Map<String, dynamic>? mapa(dynamic valor) {
		return valor is Map<String, dynamic> ? valor : null;
	}

	static List<Map<String, dynamic>> listaDeMapas(dynamic valor) {
		if (valor is List) {
			return valor.whereType<Map<String, dynamic>>().toList();
		}
		return const [];
	}
}
