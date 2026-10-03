// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: service.dart
// Propósito: Entidad inmutable de dominio que modela los servicios prestados por el negocio y sus tarifas.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';

/// Entidad inmutable de dominio que representa un Servicio ofrecido por el Petshop.
///
/// Modela los servicios disponibles para agendamiento, su costo base en centavos,
/// duración en minutos para reservas de turnos y necesidad de registro clínico.
@freezed
class Service with _$Service {
  /// Constructor de fábrica inmutable para la entidad [Service].
  const factory Service({
    /// Identificador único del servicio.
    required String id,

    /// Nombre comercial del servicio.
    required String name,

    /// Nombre en minúsculas y sin acentos para facilitar filtros de búsqueda.
    required String searchName,

    /// Descripción de las atenciones o procedimientos que abarca.
    required String description,

    /// Precio base sin impuestos en centavos de dólar.
    required int basePriceCents,

    /// Puntos base del gravamen ICE (0 si no aplica).
    @Default(0) int iceBp,

    /// Indica si el servicio requiere atención médica veterinaria y ficha clínica.
    required bool isClinical,

    /// Tiempo estimado en minutos que toma brindar el servicio.
    required int estimatedDurationMinutes,

    /// Indica si el servicio está habilitado para ser reservado en línea.
    required bool isActive,
  }) = _Service;
}
