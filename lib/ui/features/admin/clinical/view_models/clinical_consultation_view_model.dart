// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clinical/view_models/clinical_consultation_view_model.dart
// Propósito: ViewModel de consulta clínica veterinaria, registro anamnésico, examen físico
//            por 10 sistemas anatómicos, signos vitales, plan terapéutico y versionado inmutable.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/validators/clinical.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/data/repositories/clinical_repository.dart';

/// Gestor de estado para el formulario de consulta clínica veterinaria.
///
/// Implementa las reglas del TRD para la historia clínica electrónica:
/// anamnesis completa, examen de los 10 sistemas anatómicos obligatorios
/// (inicializados en `NOT_EXAMINED`), captura de constantes fisiológicas,
/// prescripción farmacológica, gestión de hasta 20 adjuntos clínicos,
/// actualización con versionado inmutable auditable y anulación justificada.
class ClinicalConsultationViewModel extends ChangeNotifier {
  /// Repositorio de historias y registros clínicos veterinarios.
  final ClinicalRepository clinicalRepository;

  /// Identificador único del paciente (mascota) atendido.
  final String petId;

  /// Identificador del propietario de la mascota.
  final String ownerId;

  /// Instantánea inmutable de los datos del paciente en el momento de la consulta.
  final PatientSnapshot patientSnapshot;

  /// Identificador opcional de la cita origen que motivó la consulta.
  final String? sourceAppointmentId;

  /// Identificador del veterinario o personal que registra la atención.
  final String currentStaffUid;

  /// Nombre del veterinario o personal que registra la atención.
  final String currentStaffName;

  /// Rol del usuario autenticado ('VET', 'SUPERADMIN', etc.).
  final String currentStaffRole;

  /// Registro clínico previo en caso de encontrarse en modo de corrección/edición.
  final ClinicalRecord? existingRecord;

  // Anamnesis / Motivo

  /// Motivo principal de la consulta médica veterinaria.
  String reason = '';

  /// Descripción de la enfermedad actual o evolución de síntomas.
  String? currentIllness;

  /// Antecedentes patológicos relevantes o historial médico previo.
  String? medicalHistory;

  // Los 10 sistemas anatómicos oficiales (inicializados estrictamente en NOT_EXAMINED)

  /// Estados de evaluación para cada uno de los 10 sistemas anatómicos.
  final Map<String, String> systemStates = {};

  /// Hallazgos clínicos descritos para sistemas marcados como ABNORMAL.
  final Map<String, String> systemFindings = {};

  // Signos Vitales

  /// Temperatura corporal en décimas de grado Celsius (ej. 385 = 38.5 °C).
  int? temperatureDeciC;

  /// Frecuencia cardíaca en latidos por minuto (lpm / bpm).
  int? heartRateBpm;

  /// Frecuencia respiratoria en respiraciones por minuto (rpm).
  int? respiratoryRateRpm;

  /// Peso corporal de la mascota expresado en gramos.
  int? weightGrams;

  /// Condición corporal en escala estándar de 1 a 9 puntos.
  int? bodyConditionScore;

  // Plan

  /// Diagnóstico emitido por el profesional veterinario.
  String? diagnosis;

  /// Tipología del diagnóstico ('PRESUMPTIVE' o 'DEFINITIVE').
  String diagnosisType = 'PRESUMPTIVE';

  /// Instrucciones de manejo y cuidados en el hogar dirigidas al propietario.
  String? ownerInstructions;

  /// Lista de líneas de tratamiento farmacológico o prescripciones médicas.
  final List<TreatmentLineItem> treatmentLines = [];

  // Adjuntos (máximo 20)

  /// Lista de archivos adjuntos clínicos (estudios de imagen, análisis de laboratorio, etc.).
  final List<ClinicalAttachment> attachments = [];

  // Estados de control
  bool _isLoading = false;

  /// Indica si el formulario está guardando o procesando una operación clínica.
  bool get isLoading => _isLoading;

  bool _isUploadingAttachment = false;

  /// Indica si se encuentra subiendo un documento o adjunto clínico a Storage.
  bool get isUploadingAttachment => _isUploadingAttachment;

  bool _isUploadingPhoto = false;

  /// Indica si se encuentra actualizando la fotografía del paciente.
  bool get isUploadingPhoto => _isUploadingPhoto;

  String? _errorMessage;

  /// Mensaje o código descriptivo de error ante anomalías de validación o red.
  String? get errorMessage => _errorMessage;

  Failure? _failure;

  /// Detalle tipado de la falla reportada por el repositorio.
  Failure? get failure => _failure;

  String? _successMessage;

  /// Mensaje de éxito tras guardar, corregir o anular la consulta médica.
  String? get successMessage => _successMessage;

  /// Identificador asignado por Firestore a la consulta médica creada.
  String? createdRecordId;

  /// Indica si los cambios del formulario han sido persistidos con éxito.
  bool isSaved = false;

  /// Determina si el ViewModel opera sobre un registro existente en modo corrección.
  bool get isEditMode => existingRecord != null;

  /// Control de permisos de corrección: Sólo autor original o SUPERADMIN
  bool get canEditRecord {
    if (existingRecord == null) return true;
    if (existingRecord!.status == 'ANNULLED') return false;
    return existingRecord!.authorUid == currentStaffUid || currentStaffRole == 'SUPERADMIN';
  }

  /// Control de anulación: No anulable si ya está anulado
  bool get canAnnulRecord {
    if (existingRecord == null) return false;
    return existingRecord!.status != 'ANNULLED';
  }

  /// Construye e inicializa el ViewModel del formulario de consulta clínica.
  ClinicalConsultationViewModel({
    required this.clinicalRepository,
    required this.petId,
    required this.ownerId,
    required this.patientSnapshot,
    this.sourceAppointmentId,
    required this.currentStaffUid,
    required this.currentStaffName,
    required this.currentStaffRole,
    this.existingRecord,
  }) {
    _initForm();
  }

  void _initForm() {
    // Inicialización de los diez sistemas anatómicos en NOT_EXAMINED (CL-03, AUD-144)
    for (final sys in ClinicalValidators.validSystems) {
      systemStates[sys] = 'NOT_EXAMINED';
      systemFindings[sys] = '';
    }

    if (existingRecord != null) {
      final rec = existingRecord!;
      if (rec.consultation != null) {
        reason = rec.consultation!.reason;
        currentIllness = rec.consultation!.currentIllness;
        medicalHistory = rec.consultation!.medicalHistory;
      }
      if (rec.physicalExam != null) {
        final pe = rec.physicalExam!;
        if (pe.vitals != null) {
          temperatureDeciC = pe.vitals!.temperatureDeciC;
          heartRateBpm = pe.vitals!.heartRateBpm;
          respiratoryRateRpm = pe.vitals!.respiratoryRateRpm;
          weightGrams = pe.vitals!.weightGrams;
          bodyConditionScore = pe.vitals!.bodyConditionScore;
        }
        if (pe.systems != null) {
          pe.systems!.forEach((k, v) {
            if (systemStates.containsKey(k)) {
              systemStates[k] = v.state;
              systemFindings[k] = v.findings ?? '';
            }
          });
        }
      }
      if (rec.plan != null) {
        diagnosis = rec.plan!.diagnosis;
        diagnosisType = rec.plan!.diagnosisType ?? 'PRESUMPTIVE';
        ownerInstructions = rec.plan!.ownerInstructions;
        if (rec.plan!.treatment != null) {
          treatmentLines.addAll(rec.plan!.treatment!);
        }
      }
      if (rec.attachments != null) {
        attachments.addAll(rec.attachments!);
      }
    }
  }

  /// Actualiza el estado de exploración de uno de los 10 sistemas anatómicos oficiales.
  void setSystemState(String systemKey, String newState) {
    if (!ClinicalValidators.validSystems.contains(systemKey)) return;
    if (!ClinicalValidators.validSystemStates.contains(newState)) return;

    systemStates[systemKey] = newState;
    if (newState != 'ABNORMAL') {
      systemFindings[systemKey] = '';
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// Registra los hallazgos patológicos detallados para un sistema en estado ABNORMAL.
  void setSystemFindings(String systemKey, String findings) {
    if (!ClinicalValidators.validSystems.contains(systemKey)) return;
    systemFindings[systemKey] = findings;
    _errorMessage = null;
    notifyListeners();
  }

  /// Añade una nueva línea de tratamiento farmacológico al plan terapéutico.
  void addTreatmentLine(TreatmentLineItem line) {
    treatmentLines.add(line);
    _errorMessage = null;
    notifyListeners();
  }

  /// Elimina una línea de tratamiento farmacológico por su índice de posición.
  void removeTreatmentLine(int index) {
    if (index >= 0 && index < treatmentLines.length) {
      treatmentLines.removeAt(index);
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Sube un adjunto clínico respetando el tope de 20 archivos (CL-03, ADR-005)
  Future<bool> uploadAttachment({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    required String description,
  }) async {
    if (attachments.length >= ClinicalValidators.maxAttachments) {
      _errorMessage = 'Se ha alcanzado el límite máximo de ${ClinicalValidators.maxAttachments} adjuntos.';
      notifyListeners();
      return false;
    }

    _isUploadingAttachment = true;
    _errorMessage = null;
    notifyListeners();

    final result = await clinicalRepository.uploadClinicalAttachment(
      staffUid: currentStaffUid,
      petId: petId,
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      description: description,
    );

    _isUploadingAttachment = false;
    return result.when(
      ok: (attachment) {
        attachments.add(attachment);
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Sube la fotografía de la mascota mediante upload_intents
  Future<bool> uploadPetPhoto({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    _isUploadingPhoto = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await clinicalRepository.uploadPetPhoto(
      ownerUid: ownerId,
      petId: petId,
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
    );

    _isUploadingPhoto = false;
    return result.when(
      ok: (path) {
        _successMessage = 'Foto de mascota actualizada correctamente.';
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Envía el formulario de consulta clínica aplicando validaciones de dominio
  Future<bool> submitConsultation() async {
    // 1. Validar motivo de consulta
    final reasonErr = ClinicalValidators.validateReason(reason);
    if (reasonErr != null) {
      _errorMessage = reasonErr;
      notifyListeners();
      return false;
    }

    // 2. Validar sistemas anormales sin hallazgos
    for (final entry in systemStates.entries) {
      if (entry.value == 'ABNORMAL') {
        final findings = systemFindings[entry.key];
        final sysErr = ClinicalValidators.validateSystemExam(entry.value, findings);
        if (sysErr != null) {
          _errorMessage = sysErr;
          notifyListeners();
          return false;
        }
      }
    }

    // 3. Validar signos vitales dentro de rangos fisiológicos
    final tempErr = ClinicalValidators.validateTemperature(temperatureDeciC);
    if (tempErr != null) {
      _errorMessage = tempErr;
      notifyListeners();
      return false;
    }

    final hrErr = ClinicalValidators.validateHeartRate(heartRateBpm);
    if (hrErr != null) {
      _errorMessage = hrErr;
      notifyListeners();
      return false;
    }

    final rrErr = ClinicalValidators.validateRespiratoryRate(respiratoryRateRpm);
    if (rrErr != null) {
      _errorMessage = rrErr;
      notifyListeners();
      return false;
    }

    final wErr = ClinicalValidators.validateWeight(weightGrams);
    if (wErr != null) {
      _errorMessage = wErr;
      notifyListeners();
      return false;
    }

    final bcsErr = ClinicalValidators.validateBodyCondition(bodyConditionScore);
    if (bcsErr != null) {
      _errorMessage = bcsErr;
      notifyListeners();
      return false;
    }

    // 4. Validar adjuntos
    final attErr = ClinicalValidators.validateAttachmentsCount(attachments.length);
    if (attErr != null) {
      _errorMessage = attErr;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Construcción de cargas de datos
    final consultationMap = <String, dynamic>{
      'reason': reason.trim(),
      if (currentIllness != null && currentIllness!.trim().isNotEmpty)
        'currentIllness': currentIllness!.trim(),
      if (medicalHistory != null && medicalHistory!.trim().isNotEmpty)
        'medicalHistory': medicalHistory!.trim(),
    };

    final systemsMap = <String, dynamic>{};
    for (final sys in ClinicalValidators.validSystems) {
      systemsMap[sys] = {
        'state': systemStates[sys] ?? 'NOT_EXAMINED',
        if (systemFindings[sys] != null && systemFindings[sys]!.trim().isNotEmpty)
          'findings': systemFindings[sys]!.trim(),
      };
    }

    final vitalsMap = <String, dynamic>{
      if (temperatureDeciC != null) 'temperatureDeciC': temperatureDeciC,
      if (heartRateBpm != null) 'heartRateBpm': heartRateBpm,
      if (respiratoryRateRpm != null) 'respiratoryRateRpm': respiratoryRateRpm,
      if (weightGrams != null) 'weightGrams': weightGrams,
      if (bodyConditionScore != null) 'bodyConditionScore': bodyConditionScore,
    };

    final physicalExamMap = <String, dynamic>{
      if (vitalsMap.isNotEmpty) 'vitals': vitalsMap,
      'systems': systemsMap,
    };

    final planMap = <String, dynamic>{
      if (diagnosis != null && diagnosis!.trim().isNotEmpty)
        'diagnosis': diagnosis!.trim(),
      'diagnosisType': diagnosisType,
      if (ownerInstructions != null && ownerInstructions!.trim().isNotEmpty)
        'ownerInstructions': ownerInstructions!.trim(),
      if (treatmentLines.isNotEmpty)
        'treatment': treatmentLines.map((e) => e.toJson()).toList(),
    };

    final attachmentsList = attachments.map((e) => e.toJson()).toList();

    if (isEditMode) {
      // Corrección con versionado inmutable
      final result = await clinicalRepository.updateClinicalRecord(
        petId: petId,
        recordId: existingRecord!.id!,
        consultation: consultationMap,
        physicalExam: physicalExamMap,
        plan: planMap,
        attachments: attachmentsList,
      );

      _isLoading = false;
      return result.when(
        ok: (_) {
          isSaved = true;
          _successMessage = 'Consulta clínica corregida y versionada con éxito.';
          notifyListeners();
          return true;
        },
        err: (failure) {
          _failure = failure;
          _errorMessage = failure.code;
          notifyListeners();
          return false;
        },
      );
    } else {
      // Creación de nueva consulta clínica
      final attentionDate = BusinessClock.todayBusinessDate();
      final result = await clinicalRepository.createClinicalRecord(
        petId: petId,
        type: 'CONSULTATION',
        attentionDate: attentionDate,
        attentionTime: '10:00',
        sourceAppointmentId: sourceAppointmentId,
        consultation: consultationMap,
        physicalExam: physicalExamMap,
        plan: planMap,
        attachments: attachmentsList,
      );

      _isLoading = false;
      return result.when(
        ok: (recordId) {
          createdRecordId = recordId;
          isSaved = true;
          _successMessage = 'Consulta clínica guardada exitosamente.';
          notifyListeners();
          return true;
        },
        err: (failure) {
          _failure = failure;
          _errorMessage = failure.code;
          notifyListeners();
          return false;
        },
      );
    }
  }

  /// Anula inmutablemente la entrada clínica con motivo obligatorio
  Future<bool> annul(String annulmentReason) async {
    if (existingRecord == null || existingRecord!.id == null) {
      _errorMessage = 'No hay un registro existente para anular.';
      notifyListeners();
      return false;
    }

    final reasonErr = ClinicalValidators.validateAnnulmentReason(annulmentReason);
    if (reasonErr != null) {
      _errorMessage = reasonErr;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await clinicalRepository.annulClinicalRecord(
      petId: petId,
      recordId: existingRecord!.id!,
      reason: annulmentReason.trim(),
    );

    _isLoading = false;
    return result.when(
      ok: (_) {
        isSaved = true;
        _successMessage = 'Registro clínico anulado correctamente.';
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }
}
