// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: clinical_record.dart
// Propósito: DTO y modelo de datos para el expediente clínico electrónico veterinario en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clinical_record.g.dart';

/// Convertidor para serialización y deserialización de fechas [Timestamp] en [DateTime].
class _NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const _NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? object) =>
      object != null ? Timestamp.fromDate(object) : null;
}

/// Instantánea inmutable con los datos de la mascota al momento exacto de la atención clínica.
@JsonSerializable(explicitToJson: true)
class PatientPetSnapshot {
  /// Nombre de la mascota.
  final String name;

  /// Especie biológica (ej. Canino, Felino).
  final String species;

  /// Raza de la mascota.
  final String breed;

  /// Sexo biológico (Macho / Hembra).
  final String sex;

  /// Estado reproductivo (ej. Castrado, Entero, Gestante).
  final String reproductiveStatus;

  /// Fecha de nacimiento registrada en formato ISO-8601.
  final String birthDate;

  /// Edad calculada de la mascota al momento de la consulta médica.
  final String ageAtAttention;

  /// Constructor inmutable de la instantánea de datos de la mascota.
  const PatientPetSnapshot({
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.reproductiveStatus,
    required this.birthDate,
    required this.ageAtAttention,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PatientPetSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PatientPetSnapshotFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PatientPetSnapshotToJson(this);
}

/// Instantánea inmutable con los datos del tutor o propietario al momento de la atención.
@JsonSerializable(explicitToJson: true)
class PatientOwnerSnapshot {
  /// Nombres y apellidos completos del tutor.
  final String fullName;

  /// Tipo de documento de identidad (Cédula / RUC / Pasaporte).
  final String documentType;

  /// Número del documento de identidad.
  final String documentNumber;

  /// Teléfono de contacto registrado.
  final String phone;

  /// Dirección domiciliaria del propietario.
  final String address;

  /// Correo electrónico del tutor.
  final String email;

  /// Constructor inmutable de la instantánea de datos del propietario.
  const PatientOwnerSnapshot({
    required this.fullName,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    required this.address,
    required this.email,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PatientOwnerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PatientOwnerSnapshotFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PatientOwnerSnapshotToJson(this);
}

/// Contenedor integral de la instantánea legal del paciente y su tutor.
@JsonSerializable(explicitToJson: true)
class PatientSnapshot {
  /// Datos congelados de la mascota.
  final PatientPetSnapshot pet;

  /// Datos congelados del propietario tutor.
  final PatientOwnerSnapshot owner;

  /// Constructor inmutable de la instantánea completa.
  const PatientSnapshot({
    required this.pet,
    required this.owner,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PatientSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PatientSnapshotFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PatientSnapshotToJson(this);
}

/// Bloque de anamnesis y motivo de consulta clínica veterinaria.
@JsonSerializable(explicitToJson: true)
class ConsultationBlock {
  /// Motivo principal de la consulta médica manifestado por el tutor.
  final String reason;

  /// Descripción detallada de la enfermedad actual y evolución sintomática.
  final String? currentIllness;

  /// Historial de enfermedades o antecedentes médicos relevantes.
  final String? medicalHistory;

  /// Historial de inmunizaciones, vacunas y desparasitaciones previas.
  final String? referredPreventionHistory;

  /// Medicación activa o tratamientos farmacológicos en curso.
  final String? medicationHistory;

  /// Tipo y régimen de alimentación de la mascota.
  final String? dietHistory;

  /// Hábitat y estilo de vida (ej. interior, patio, convivencia con otras mascotas).
  final String? lifestyleHistory;

  /// Constructor inmutable del bloque de consulta clínica.
  const ConsultationBlock({
    required this.reason,
    this.currentIllness,
    this.medicalHistory,
    this.referredPreventionHistory,
    this.medicationHistory,
    this.dietHistory,
    this.lifestyleHistory,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory ConsultationBlock.fromJson(Map<String, dynamic> json) =>
      _$ConsultationBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$ConsultationBlockToJson(this);
}

/// Registro cuantitativo de constantes fisiológicas y signos vitales del paciente.
@JsonSerializable(explicitToJson: true)
class VitalSignsBlock {
  /// Temperatura corporal en décimas de grado Celsius (ej. 385 equivale a 38.5 °C).
  final int? temperatureDeciC;

  /// Frecuencia cardíaca expresada en latidos por minuto (lpm/bpm).
  final int? heartRateBpm;

  /// Frecuencia respiratoria expresada en respiraciones por minuto (rpm).
  final int? respiratoryRateRpm;

  /// Peso corporal de la mascota expresado en gramos para máxima precisión.
  final int? weightGrams;

  /// Condición corporal en escala estandarizada (1 a 5 o 1 a 9).
  final int? bodyConditionScore;

  /// Constructor inmutable del registro de signos vitales.
  const VitalSignsBlock({
    this.temperatureDeciC,
    this.heartRateBpm,
    this.respiratoryRateRpm,
    this.weightGrams,
    this.bodyConditionScore,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory VitalSignsBlock.fromJson(Map<String, dynamic> json) =>
      _$VitalSignsBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$VitalSignsBlockToJson(this);
}

/// Resultado de la evaluación médica de un sistema anatómico o fisiológico específico.
@JsonSerializable(explicitToJson: true)
class SystemExamItem {
  /// Estado del sistema ('NOT_EXAMINED', 'NORMAL' o 'ABNORMAL').
  final String state;

  /// Hallazgos clínicos u observaciones detalladas en caso de anomalías.
  final String? findings;

  /// Constructor inmutable del examen por sistema.
  const SystemExamItem({
    this.state = 'NOT_EXAMINED',
    this.findings,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory SystemExamItem.fromJson(Map<String, dynamic> json) =>
      _$SystemExamItemFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$SystemExamItemToJson(this);
}

/// Bloque integral de examen físico general y por sistemas orgánicos.
@JsonSerializable(explicitToJson: true)
class PhysicalExamBlock {
  /// Constantes fisiológicas medidas.
  final VitalSignsBlock? vitals;

  /// Mapeo de sistemas examinados (ej. digestivo, respiratorio, dermatológico, etc.).
  final Map<String, SystemExamItem>? systems;

  /// Constructor inmutable del examen físico.
  const PhysicalExamBlock({
    this.vitals,
    this.systems,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PhysicalExamBlock.fromJson(Map<String, dynamic> json) =>
      _$PhysicalExamBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PhysicalExamBlockToJson(this);
}

/// Detalle de prescripción de un medicamento dentro del plan terapéutico.
@JsonSerializable(explicitToJson: true)
class TreatmentLineItem {
  /// Nombre comercial o principio activo del fármaco prescrito.
  final String medication;

  /// Dosis y concentración recomendada (ej. "5 mg/kg").
  final String dose;

  /// Vía de administración (Oral, Intramuscular, Subcutánea, Tópica, etc.).
  final String route;

  /// Duración planificada del tratamiento farmacológico (ej. "7 días").
  final String duration;

  /// Fecha de inicio de la medicación.
  final String startDate;

  /// Modalidad de dosificación o pauta horaria (ej. "Cada 12 horas con comida").
  final String modality;

  /// Constructor inmutable del ítem de tratamiento.
  const TreatmentLineItem({
    required this.medication,
    required this.dose,
    required this.route,
    required this.duration,
    required this.startDate,
    required this.modality,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory TreatmentLineItem.fromJson(Map<String, dynamic> json) =>
      _$TreatmentLineItemFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$TreatmentLineItemToJson(this);
}

/// Solicitud de examen complementario de diagnóstico.
@JsonSerializable(explicitToJson: true)
class RequestedTestItem {
  /// Tipo de examen solicitado (ej. Hemograma, Radiografía, Ecografía).
  final String type;

  /// Indicación médica o detalle de la solicitud diagnóstica.
  final String detail;

  /// Constructor inmutable de la solicitud de examen.
  const RequestedTestItem({
    required this.type,
    required this.detail,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory RequestedTestItem.fromJson(Map<String, dynamic> json) =>
      _$RequestedTestItemFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$RequestedTestItemToJson(this);
}

/// Registro de prueba diagnóstica ejecutada e interpretada durante la consulta.
@JsonSerializable(explicitToJson: true)
class PerformedTestItem {
  /// Tipo de análisis efectuado.
  final String type;

  /// Hallazgos e interpretación de los resultados obtenidos.
  final String findings;

  /// Constructor inmutable del examen realizado.
  const PerformedTestItem({
    required this.type,
    required this.findings,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PerformedTestItem.fromJson(Map<String, dynamic> json) =>
      _$PerformedTestItemFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PerformedTestItemToJson(this);
}

/// Plan terapéutico, diagnósticos y recomendaciones emitidas por el médico veterinario.
@JsonSerializable(explicitToJson: true)
class PlanBlock {
  /// Conclusión o juicio diagnóstico del facultativo.
  final String? diagnosis;

  /// Naturaleza diagnóstica (Presuntivo, Diferencial o Definitivo).
  final String? diagnosisType;

  /// Lista de prescripciones farmacológicas indicadas.
  final List<TreatmentLineItem>? treatment;

  /// Instrucciones de manejo y cuidados en casa para el propietario.
  final String? ownerInstructions;

  /// Lista de exámenes complementarios solicitados.
  final List<RequestedTestItem>? requestedTests;

  /// Pruebas o análisis rápidos ejecutados durante la consulta.
  final List<PerformedTestItem>? performedTests;

  /// Constructor inmutable del plan terapéutico.
  const PlanBlock({
    this.diagnosis,
    this.diagnosisType,
    this.treatment,
    this.ownerInstructions,
    this.requestedTests,
    this.performedTests,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PlanBlock.fromJson(Map<String, dynamic> json) =>
      _$PlanBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PlanBlockToJson(this);
}

/// Bloque de seguimiento y control de evolución de una atención previa.
@JsonSerializable(explicitToJson: true)
class FollowUpBlock {
  /// Identificador del registro clínico primario de consulta que se está evaluando.
  final String consultationRecordId;

  /// Respuesta observada al tratamiento instaurado previamente.
  final String treatmentResponse;

  /// Ajustes o modificaciones realizadas al esquema terapéutico.
  final String? planAdjustments;

  /// Resultados de análisis laboratoriales o de gabinete complementarios.
  final String? testResults;

  /// Observaciones adicionales de seguimiento.
  final String? observations;

  /// Constructor inmutable del bloque de seguimiento clínico.
  const FollowUpBlock({
    required this.consultationRecordId,
    required this.treatmentResponse,
    this.planAdjustments,
    this.testResults,
    this.observations,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory FollowUpBlock.fromJson(Map<String, dynamic> json) =>
      _$FollowUpBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$FollowUpBlockToJson(this);
}

/// Bloque para el registro de medicina preventiva (vacunación, desparasitación externa/interna).
@JsonSerializable(explicitToJson: true)
class PreventionBlock {
  /// Subtipo de medicina preventiva (ej. VACUNA, DESPARASITACION_INTERNA, DESPARASITACION_EXTERNA).
  final String subType;

  /// Fecha en que se suministró el biológico o producto antiparasitario.
  final String applicationDate;

  /// Nombre comercial del fármaco o principio activo inmunizante.
  final String productOrActiveIngredient;

  /// Número de lote de fabricación del biológico para trazabilidad sanitaria.
  final String? batch;

  /// Vía de inoculación (Subcutánea, Oral, Spot-on / Pipeta, etc.).
  final String? route;

  /// Resultado o reacción post-aplicación inmediata.
  final String? result;

  /// Fecha sugerida para el siguiente refuerzo o revacunación.
  final String? nextApplicationDate;

  /// Observaciones clínicas pertinentes.
  final String? observations;

  /// Constructor inmutable del registro preventivo.
  const PreventionBlock({
    required this.subType,
    required this.applicationDate,
    required this.productOrActiveIngredient,
    this.batch,
    this.route,
    this.result,
    this.nextApplicationDate,
    this.observations,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory PreventionBlock.fromJson(Map<String, dynamic> json) =>
      _$PreventionBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$PreventionBlockToJson(this);
}

/// Bloque que formaliza y audita la anulación legal de un registro clínico erróneo.
@JsonSerializable(explicitToJson: true)
class AnnulmentBlock {
  /// Identificador del registro clínico que se anula.
  final String targetRecordId;

  /// Justificación médica o administrativa detallada del motivo de la anulación.
  final String reason;

  /// Constructor inmutable del bloque de anulación.
  const AnnulmentBlock({
    required this.targetRecordId,
    required this.reason,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory AnnulmentBlock.fromJson(Map<String, dynamic> json) =>
      _$AnnulmentBlockFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$AnnulmentBlockToJson(this);
}

/// Representa un archivo adjunto complementario vinculado al expediente médico en Cloud Storage.
@JsonSerializable(explicitToJson: true)
class ClinicalAttachment {
  /// Identificador único del archivo adjunto.
  final String id;

  /// Ruta completa del archivo almacenado en Firebase Cloud Storage.
  final String storagePath;

  /// Tipo de formato o extensión del archivo (PDF, JPEG, PNG, etc.).
  final String fileType;

  /// Descripción o referencia médica del archivo adjunto (ej. "Radiografía de tórax lateral").
  final String description;

  /// Tamaño en bytes del documento.
  final int sizeBytes;

  /// Fecha y hora en que se cargó el archivo al almacenamiento en la nube.
  @_NullableTimestampConverter()
  final DateTime? uploadedAt;

  /// Constructor inmutable del archivo adjunto clínico.
  const ClinicalAttachment({
    required this.id,
    required this.storagePath,
    required this.fileType,
    required this.description,
    required this.sizeBytes,
    this.uploadedAt,
  });

  /// Construye una instancia a partir de un mapa JSON.
  factory ClinicalAttachment.fromJson(Map<String, dynamic> json) =>
      _$ClinicalAttachmentFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$ClinicalAttachmentToJson(this);
}

/// Entidad principal del Registro Clínico Electrónico Veterinario.
///
/// Modela los documentos almacenados en la subcolección `/pets/{petId}/clinical_records`
/// en Cloud Firestore. Incluye control de versiones, instantánea legal de datos,
/// bloques médicos opcionales y auditoría estricta de inmutabilidad y anulación.
@JsonSerializable(explicitToJson: true)
class ClinicalRecord {
  /// Identificador único del registro clínico en Firestore.
  final String? id;

  /// Identificador de la mascota a la cual pertenece la historia médica.
  final String petId;

  /// Identificador del tutor o dueño de la mascota al momento de la atención.
  final String ownerId;

  /// Tipo de registro ('CONSULTATION', 'FOLLOW_UP', 'PREVENTION', 'ANNULMENT', 'EMERGENCY').
  final String type;

  /// Estado legal del registro ('ACTIVE' para válido o 'ANNULLED' para invalidado formalmente).
  final String status;

  /// UID del médico veterinario autor de la entrada en Firebase Auth.
  final String authorUid;

  /// Nombre del médico veterinario responsable de la atención.
  final String authorName;

  /// Marca temporal del servidor en que se guardó el documento.
  @_NullableTimestampConverter()
  final DateTime? createdAt;

  /// Fecha de atención en formato legible (YYYY-MM-DD).
  final String attentionDate;

  /// Hora de atención en formato de 24 horas (HH:MM).
  final String attentionTime;

  /// Identificador de la cita de origen en caso de proceder de una reserva de agenda.
  final String? sourceAppointmentId;

  /// Instantánea legal inmutable de los datos de la mascota y del tutor al momento de la atención.
  final PatientSnapshot patientSnapshot;

  /// Bloque de motivo de consulta y anamnesis.
  final ConsultationBlock? consultation;

  /// Bloque de exploración física y constantes vitales.
  final PhysicalExamBlock? physicalExam;

  /// Bloque de plan diagnóstico, pruebas y tratamientos prescritos.
  final PlanBlock? plan;

  /// Bloque de control de evolución o seguimiento.
  final FollowUpBlock? followUp;

  /// Bloque de vacunas o desparasitaciones preventivas.
  final PreventionBlock? prevention;

  /// Bloque de anulación en caso de haberse emitido para invalidar otro registro.
  final AnnulmentBlock? annulment;

  /// Fecha y hora en que se anuló este registro, si corresponde.
  @_NullableTimestampConverter()
  final DateTime? annulledAt;

  /// UID del usuario administrativo o veterinario que ejecutó la anulación.
  final String? annulledBy;

  /// Identificador del registro de tipo ANNULMENT que generó la invalidación.
  final String? annulledByRecordId;

  /// Causa explícita por la cual se anuló la atención médica.
  final String? annulmentReason;

  /// Colección de archivos adjuntos (estudios de laboratorio, radiografías) vinculados a la atención.
  final List<ClinicalAttachment>? attachments;

  /// Indica si el registro original fue sometido a corrección o enmienda de texto.
  final bool isEdited;

  /// Número de versión del registro para trazabilidad de modificaciones.
  final int version;

  /// Fecha de la última edición realizada.
  @_NullableTimestampConverter()
  final DateTime? lastEditedAt;

  /// UID del usuario que efectuó la última edición.
  final String? lastEditedBy;

  /// Nombre legible del usuario que realizó la última edición.
  final String? lastEditedByName;

  /// Constructor inmutable completo del registro clínico electrónico.
  const ClinicalRecord({
    this.id,
    required this.petId,
    required this.ownerId,
    required this.type,
    required this.status,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    required this.attentionDate,
    required this.attentionTime,
    this.sourceAppointmentId,
    required this.patientSnapshot,
    this.consultation,
    this.physicalExam,
    this.plan,
    this.followUp,
    this.prevention,
    this.annulment,
    this.annulledAt,
    this.annulledBy,
    this.annulledByRecordId,
    this.annulmentReason,
    this.attachments,
    this.isEdited = false,
    this.version = 1,
    this.lastEditedAt,
    this.lastEditedBy,
    this.lastEditedByName,
  });

  /// Alias de acceso rápido al bloque de anamnesis.
  ConsultationBlock? get anamnesis => consultation;

  /// Alias de acceso rápido a las constantes vitales del paciente.
  VitalSignsBlock? get vitalSigns => physicalExam?.vitals;

  /// Alias de acceso rápido a la evaluación de sistemas orgánicos.
  Map<String, SystemExamItem>? get systemsExam => physicalExam?.systems;

  /// Alias de acceso rápido a la pauta de tratamiento farmacológico.
  List<TreatmentLineItem>? get treatment => plan?.treatment;

  /// Construye un [ClinicalRecord] a partir de un mapa deserializado de JSON.
  factory ClinicalRecord.fromJson(Map<String, dynamic> json) =>
      _$ClinicalRecordFromJson(json);

  /// Serializa la historia clínica completa en un mapa JSON.
  Map<String, dynamic> toJson() => _$ClinicalRecordToJson(this);

  /// Construye un [ClinicalRecord] desde un [DocumentSnapshot] de Cloud Firestore.
  ///
  /// Lanza un [StateError] si la información del documento no está disponible.
  factory ClinicalRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de entrada clínica no puede ser nula.');
    }
    return ClinicalRecord.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el registro en un mapa estructurado para persistir en Firestore, excluyendo el 'id'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }
}
