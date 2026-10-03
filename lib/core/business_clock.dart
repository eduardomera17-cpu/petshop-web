// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/business_clock.dart
// Propósito: Reloj de negocio canónico e inmutable, único punto autorizado para la obtención de fecha y hora bajo la zona horaria 'America/Guayaquil' (UTC-5).
// =========================================================================

import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// {@template business_clock}
/// Reloj de negocio centralizado (TRD §1.3.5, N-12).
///
/// La zona horaria canónica del negocio es 'America/Guayaquil' (UTC-5).
/// Esta clase abstracta final es el ÚNICO lugar autorizado en toda la base de código para
/// invocar `DateTime.now()`. La zona horaria del cliente o navegador nunca decide
/// a qué día del negocio pertenece ningún evento (citas, vencimientos o auditorías).
/// {@endtemplate}
abstract final class BusinessClock {
  /// Zona horaria canónica de operación del negocio.
  static const String defaultTimezone = 'America/Guayaquil';

  static bool _isTimezoneDataLoaded = false;
  static tz.Location? _businessLocation;
  static DateTime Function()? _customNow;

  /// Inicializa la base de datos de zonas horarias y establece la ubicación de negocio.
  ///
  /// Admite inyección de [customNow] para pruebas deterministas.
  static void init({
    String timezone = defaultTimezone,
    DateTime Function()? customNow,
  }) {
    if (!_isTimezoneDataLoaded) {
      tz_data.initializeTimeZones();
      _isTimezoneDataLoaded = true;
    }

    try {
      _businessLocation = tz.getLocation(timezone);
    } catch (_) {
      _businessLocation = tz.getLocation(defaultTimezone);
    }

    _customNow = customNow;
  }

  /// Restablece el reloj a su configuración predeterminada.
  static void reset() {
    _customNow = null;
    _businessLocation = null;
  }

  /// Retorna la ubicación de zona horaria actual de negocio.
  static tz.Location get location {
    if (_businessLocation == null) {
      init();
    }
    return _businessLocation!;
  }

  /// Retorna el instante actual en la zona horaria del negocio.
  static tz.TZDateTime now() {
    final baseDate = _customNow != null ? _customNow!() : DateTime.now();
    return tz.TZDateTime.from(baseDate, location);
  }

  /// Retorna la fecha de negocio actual en formato canónico 'YYYY-MM-DD' (TRD §1.3.5).
  static String todayBusinessDate() {
    final current = now();
    return _formatDate(current);
  }

  /// Convierte cualquier [DateTime] a la fecha calendario del negocio en 'YYYY-MM-DD'.
  static String toBusinessDate(DateTime dt) {
    final tzDate = tz.TZDateTime.from(dt, location);
    return _formatDate(tzDate);
  }

  /// Evalúa si la fecha provista en formato 'YYYY-MM-DD' es estrictamente posterior
  /// a la fecha actual del negocio.
  static bool isFutureBusinessDate(String dateString) {
    final today = todayBusinessDate();
    return dateString.compareTo(today) > 0;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
