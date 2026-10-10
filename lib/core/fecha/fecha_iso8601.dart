/// Serializa [fechaHora] en ISO-8601 con el offset explicito, por ejemplo
/// `2026-10-04T21:00:58.129-03:00`.
///
/// `DateTime.toIso8601String()` no sirve para el backend: en una fecha local
/// omite el offset y el servidor la interpreta en su propia zona (UTC en
/// Render), corriendo la hora.
///
/// [utcOffsetMinutos] fija la zona en la que se expresa la hora; si no viene se
/// usa el offset local del dispositivo para esa fecha. El instante es siempre
/// el mismo: solo cambia como se escribe.
String fechaIso8601ConOffset(DateTime fechaHora, {int? utcOffsetMinutos}) {
	final offsetMinutos = utcOffsetMinutos ?? fechaHora.toLocal().timeZoneOffset.inMinutes;
	// Los campos de este DateTime (UTC) son la hora de reloj en esa zona.
	final enZona = fechaHora.toUtc().add(Duration(minutes: offsetMinutos));

	final anio = enZona.year.toString().padLeft(4, '0');
	final mes = _dosDigitos(enZona.month);
	final dia = _dosDigitos(enZona.day);
	final hora = _dosDigitos(enZona.hour);
	final minuto = _dosDigitos(enZona.minute);
	final segundo = _dosDigitos(enZona.second);
	final milisegundo = enZona.millisecond.toString().padLeft(3, '0');

	final signo = offsetMinutos < 0 ? '-' : '+';
	final offsetAbsoluto = offsetMinutos.abs();
	final offsetHoras = _dosDigitos(offsetAbsoluto ~/ 60);
	final offsetResto = _dosDigitos(offsetAbsoluto % 60);

	return '$anio-$mes-${dia}T$hora:$minuto:$segundo.$milisegundo'
			'$signo$offsetHoras:$offsetResto';
}

String _dosDigitos(int valor) => valor.toString().padLeft(2, '0');
