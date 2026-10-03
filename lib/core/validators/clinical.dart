// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/validators/clinical.dart
// Propósito: Validaciones de dominio y límites clínicos normativos para consultas, anamnesis, constantes fisiológicas y prescripciones.
// =========================================================================

/// {@template clinical_validators}
/// Conjunto de validadores y límites estáticos de dominio para el módulo clínico veterinario (TRD §2.4.1, §3.4.A-C).
///
/// Centraliza la verificación de rangos fisiológicos (temperatura, frecuencias, peso),
/// estados de examen físico por sistemas, tratamiento farmacológico y anulación de entradas.
/// {@endtemplate}
class ClinicalValidators {
  /// Lista de sistemas orgánicos evaluados durante el examen físico general.
  static const List<String> validSystems = [
    'mucous',
    'skin',
    'eyes',
    'ears',
    'cardiovascular',
    'respiratory',
    'gastrointestinal',
    'nervous',
    'musculoskeletal',
    'genitourinary',
  ];

  /// Estados clínicos admitidos para la evaluación de un sistema anatómico.
  static const List<String> validSystemStates = [
    'NOT_EXAMINED',
    'NORMAL',
    'ABNORMAL',
  ];

  /// Vías de administración farmacológica autorizadas.
  static const List<String> validRoutes = [
    'ORAL',
    'TOPICAL',
    'SUBCUTANEOUS',
    'INTRAMUSCULAR',
    'INTRAVENOUS',
    'OTIC',
    'OPHTHALMIC',
    'OTHER',
  ];

  /// Modalidades de dispensación y administración de medicamentos.
  static const List<String> validModalities = [
    'PRESCRIBED',
    'ADMINISTERED_IN_CLINIC',
  ];

  /// Límite máximo de archivos adjuntos permitidos por cada entrada clínica.
  static const int maxAttachments = 20;

  /// Longitud máxima en caracteres para el motivo de consulta.
  static const int maxConsultationReasonLength = 500;

  /// Longitud máxima en caracteres para el motivo justificado de anulación.
  static const int maxAnnulmentReasonLength = 500;

  /// Longitud máxima en caracteres para la descripción de hallazgos anormales en un sistema.
  static const int maxSystemFindingsLength = 300;

  /// Valida el motivo de consulta (obligatorio, 1..500 caracteres)
  static String? validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El motivo de consulta es obligatorio.';
    }
    if (value.trim().length > maxConsultationReasonLength) {
      return 'El motivo no puede superar los $maxConsultationReasonLength caracteres.';
    }
    return null;
  }

  /// Valida el motivo de anulación (obligatorio, 1..500 caracteres, CL-08)
  static String? validateAnnulmentReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El motivo de anulación es obligatorio.';
    }
    if (value.trim().length > maxAnnulmentReasonLength) {
      return 'El motivo no puede superar los $maxAnnulmentReasonLength caracteres.';
    }
    return null;
  }

  /// Valida el estado y hallazgos de un sistema del examen físico
  static String? validateSystemExam(String state, String? findings) {
    if (!validSystemStates.contains(state)) {
      return 'Estado de sistema no válido.';
    }
    if (state == 'ABNORMAL') {
      if (findings == null || findings.trim().isEmpty) {
        return 'Debe detallar los hallazgos descriptivos para sistemas anormales.';
      }
      if (findings.trim().length > maxSystemFindingsLength) {
        return 'Los hallazgos no pueden superar los $maxSystemFindingsLength caracteres.';
      }
    }
    return null;
  }

  /// Valida la temperatura en décimas de grado Celsius (300..450 = 30.0 °C a 45.0 °C)
  static String? validateTemperature(int? tempDeciC) {
    if (tempDeciC == null) return null;
    if (tempDeciC < 300 || tempDeciC > 450) {
      return 'Temperatura fuera de rango fisiológico (30.0 °C - 45.0 °C).';
    }
    return null;
  }

  /// Valida la frecuencia cardíaca (10..400 bpm)
  static String? validateHeartRate(int? hrBpm) {
    if (hrBpm == null) return null;
    if (hrBpm < 10 || hrBpm > 400) {
      return 'Frecuencia cardíaca fuera de rango fisiológico (10 - 400 lpm).';
    }
    return null;
  }

  /// Valida la frecuencia respiratoria (5..200 rpm)
  static String? validateRespiratoryRate(int? rrRpm) {
    if (rrRpm == null) return null;
    if (rrRpm < 5 || rrRpm > 200) {
      return 'Frecuencia respiratoria fuera de rango fisiológico (5 - 200 rpm).';
    }
    return null;
  }

  /// Valida el peso en gramos (50..150000 g)
  static String? validateWeight(int? weightG) {
    if (weightG == null) return null;
    if (weightG < 50 || weightG > 150000) {
      return 'Peso fuera de rango fisiológico (0.05 kg - 150.0 kg).';
    }
    return null;
  }

  /// Valida la condición corporal (escala 1 a 9)
  static String? validateBodyCondition(int? bcs) {
    if (bcs == null) return null;
    if (bcs < 1 || bcs > 9) {
      return 'La condición corporal debe estar entre 1 y 9.';
    }
    return null;
  }

  /// Valida una línea de prescripción de tratamiento
  static String? validateTreatmentLine({
    required String? medication,
    required String? dose,
    required String? route,
    required String? duration,
    required String? startDate,
    required String? modality,
  }) {
    final hasMed = medication != null && medication.trim().isNotEmpty;
    if (!hasMed) return null;

    if (dose == null || dose.trim().isEmpty) {
      return 'La dosis es obligatoria cuando se prescribe un medicamento.';
    }
    if (route == null || !validRoutes.contains(route)) {
      return 'Vía de administración inválida.';
    }
    if (duration == null || duration.trim().isEmpty) {
      return 'La duración es obligatoria.';
    }
    if (startDate == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(startDate)) {
      return 'Fecha de inicio inválida (formato YYYY-MM-DD).';
    }
    if (modality == null || !validModalities.contains(modality)) {
      return 'Modalidad de administración inválida.';
    }
    return null;
  }

  /// Valida el número de adjuntos (máximo 20)
  static String? validateAttachmentsCount(int count) {
    if (count > maxAttachments) {
      return 'No se pueden superar los $maxAttachments adjuntos por entrada clínica.';
    }
    return null;
  }
}
