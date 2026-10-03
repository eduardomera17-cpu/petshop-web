// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatientPetSnapshot _$PatientPetSnapshotFromJson(Map<String, dynamic> json) =>
    PatientPetSnapshot(
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String,
      sex: json['sex'] as String,
      reproductiveStatus: json['reproductiveStatus'] as String,
      birthDate: json['birthDate'] as String,
      ageAtAttention: json['ageAtAttention'] as String,
    );

Map<String, dynamic> _$PatientPetSnapshotToJson(PatientPetSnapshot instance) =>
    <String, dynamic>{
      'name': instance.name,
      'species': instance.species,
      'breed': instance.breed,
      'sex': instance.sex,
      'reproductiveStatus': instance.reproductiveStatus,
      'birthDate': instance.birthDate,
      'ageAtAttention': instance.ageAtAttention,
    };

PatientOwnerSnapshot _$PatientOwnerSnapshotFromJson(
  Map<String, dynamic> json,
) => PatientOwnerSnapshot(
  fullName: json['fullName'] as String,
  documentType: json['documentType'] as String,
  documentNumber: json['documentNumber'] as String,
  phone: json['phone'] as String,
  address: json['address'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$PatientOwnerSnapshotToJson(
  PatientOwnerSnapshot instance,
) => <String, dynamic>{
  'fullName': instance.fullName,
  'documentType': instance.documentType,
  'documentNumber': instance.documentNumber,
  'phone': instance.phone,
  'address': instance.address,
  'email': instance.email,
};

PatientSnapshot _$PatientSnapshotFromJson(Map<String, dynamic> json) =>
    PatientSnapshot(
      pet: PatientPetSnapshot.fromJson(json['pet'] as Map<String, dynamic>),
      owner: PatientOwnerSnapshot.fromJson(
        json['owner'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PatientSnapshotToJson(PatientSnapshot instance) =>
    <String, dynamic>{
      'pet': instance.pet.toJson(),
      'owner': instance.owner.toJson(),
    };

ConsultationBlock _$ConsultationBlockFromJson(Map<String, dynamic> json) =>
    ConsultationBlock(
      reason: json['reason'] as String,
      currentIllness: json['currentIllness'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      referredPreventionHistory: json['referredPreventionHistory'] as String?,
      medicationHistory: json['medicationHistory'] as String?,
      dietHistory: json['dietHistory'] as String?,
      lifestyleHistory: json['lifestyleHistory'] as String?,
    );

Map<String, dynamic> _$ConsultationBlockToJson(ConsultationBlock instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'currentIllness': instance.currentIllness,
      'medicalHistory': instance.medicalHistory,
      'referredPreventionHistory': instance.referredPreventionHistory,
      'medicationHistory': instance.medicationHistory,
      'dietHistory': instance.dietHistory,
      'lifestyleHistory': instance.lifestyleHistory,
    };

VitalSignsBlock _$VitalSignsBlockFromJson(Map<String, dynamic> json) =>
    VitalSignsBlock(
      temperatureDeciC: (json['temperatureDeciC'] as num?)?.toInt(),
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt(),
      respiratoryRateRpm: (json['respiratoryRateRpm'] as num?)?.toInt(),
      weightGrams: (json['weightGrams'] as num?)?.toInt(),
      bodyConditionScore: (json['bodyConditionScore'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VitalSignsBlockToJson(VitalSignsBlock instance) =>
    <String, dynamic>{
      'temperatureDeciC': instance.temperatureDeciC,
      'heartRateBpm': instance.heartRateBpm,
      'respiratoryRateRpm': instance.respiratoryRateRpm,
      'weightGrams': instance.weightGrams,
      'bodyConditionScore': instance.bodyConditionScore,
    };

SystemExamItem _$SystemExamItemFromJson(Map<String, dynamic> json) =>
    SystemExamItem(
      state: json['state'] as String? ?? 'NOT_EXAMINED',
      findings: json['findings'] as String?,
    );

Map<String, dynamic> _$SystemExamItemToJson(SystemExamItem instance) =>
    <String, dynamic>{'state': instance.state, 'findings': instance.findings};

PhysicalExamBlock _$PhysicalExamBlockFromJson(Map<String, dynamic> json) =>
    PhysicalExamBlock(
      vitals: json['vitals'] == null
          ? null
          : VitalSignsBlock.fromJson(json['vitals'] as Map<String, dynamic>),
      systems: (json['systems'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, SystemExamItem.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$PhysicalExamBlockToJson(PhysicalExamBlock instance) =>
    <String, dynamic>{
      'vitals': instance.vitals?.toJson(),
      'systems': instance.systems?.map((k, e) => MapEntry(k, e.toJson())),
    };

TreatmentLineItem _$TreatmentLineItemFromJson(Map<String, dynamic> json) =>
    TreatmentLineItem(
      medication: json['medication'] as String,
      dose: json['dose'] as String,
      route: json['route'] as String,
      duration: json['duration'] as String,
      startDate: json['startDate'] as String,
      modality: json['modality'] as String,
    );

Map<String, dynamic> _$TreatmentLineItemToJson(TreatmentLineItem instance) =>
    <String, dynamic>{
      'medication': instance.medication,
      'dose': instance.dose,
      'route': instance.route,
      'duration': instance.duration,
      'startDate': instance.startDate,
      'modality': instance.modality,
    };

RequestedTestItem _$RequestedTestItemFromJson(Map<String, dynamic> json) =>
    RequestedTestItem(
      type: json['type'] as String,
      detail: json['detail'] as String,
    );

Map<String, dynamic> _$RequestedTestItemToJson(RequestedTestItem instance) =>
    <String, dynamic>{'type': instance.type, 'detail': instance.detail};

PerformedTestItem _$PerformedTestItemFromJson(Map<String, dynamic> json) =>
    PerformedTestItem(
      type: json['type'] as String,
      findings: json['findings'] as String,
    );

Map<String, dynamic> _$PerformedTestItemToJson(PerformedTestItem instance) =>
    <String, dynamic>{'type': instance.type, 'findings': instance.findings};

PlanBlock _$PlanBlockFromJson(Map<String, dynamic> json) => PlanBlock(
  diagnosis: json['diagnosis'] as String?,
  diagnosisType: json['diagnosisType'] as String?,
  treatment: (json['treatment'] as List<dynamic>?)
      ?.map((e) => TreatmentLineItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  ownerInstructions: json['ownerInstructions'] as String?,
  requestedTests: (json['requestedTests'] as List<dynamic>?)
      ?.map((e) => RequestedTestItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  performedTests: (json['performedTests'] as List<dynamic>?)
      ?.map((e) => PerformedTestItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlanBlockToJson(PlanBlock instance) => <String, dynamic>{
  'diagnosis': instance.diagnosis,
  'diagnosisType': instance.diagnosisType,
  'treatment': instance.treatment?.map((e) => e.toJson()).toList(),
  'ownerInstructions': instance.ownerInstructions,
  'requestedTests': instance.requestedTests?.map((e) => e.toJson()).toList(),
  'performedTests': instance.performedTests?.map((e) => e.toJson()).toList(),
};

FollowUpBlock _$FollowUpBlockFromJson(Map<String, dynamic> json) =>
    FollowUpBlock(
      consultationRecordId: json['consultationRecordId'] as String,
      treatmentResponse: json['treatmentResponse'] as String,
      planAdjustments: json['planAdjustments'] as String?,
      testResults: json['testResults'] as String?,
      observations: json['observations'] as String?,
    );

Map<String, dynamic> _$FollowUpBlockToJson(FollowUpBlock instance) =>
    <String, dynamic>{
      'consultationRecordId': instance.consultationRecordId,
      'treatmentResponse': instance.treatmentResponse,
      'planAdjustments': instance.planAdjustments,
      'testResults': instance.testResults,
      'observations': instance.observations,
    };

PreventionBlock _$PreventionBlockFromJson(Map<String, dynamic> json) =>
    PreventionBlock(
      subType: json['subType'] as String,
      applicationDate: json['applicationDate'] as String,
      productOrActiveIngredient: json['productOrActiveIngredient'] as String,
      batch: json['batch'] as String?,
      route: json['route'] as String?,
      result: json['result'] as String?,
      nextApplicationDate: json['nextApplicationDate'] as String?,
      observations: json['observations'] as String?,
    );

Map<String, dynamic> _$PreventionBlockToJson(PreventionBlock instance) =>
    <String, dynamic>{
      'subType': instance.subType,
      'applicationDate': instance.applicationDate,
      'productOrActiveIngredient': instance.productOrActiveIngredient,
      'batch': instance.batch,
      'route': instance.route,
      'result': instance.result,
      'nextApplicationDate': instance.nextApplicationDate,
      'observations': instance.observations,
    };

AnnulmentBlock _$AnnulmentBlockFromJson(Map<String, dynamic> json) =>
    AnnulmentBlock(
      targetRecordId: json['targetRecordId'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$AnnulmentBlockToJson(AnnulmentBlock instance) =>
    <String, dynamic>{
      'targetRecordId': instance.targetRecordId,
      'reason': instance.reason,
    };

ClinicalAttachment _$ClinicalAttachmentFromJson(Map<String, dynamic> json) =>
    ClinicalAttachment(
      id: json['id'] as String,
      storagePath: json['storagePath'] as String,
      fileType: json['fileType'] as String,
      description: json['description'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      uploadedAt: const _NullableTimestampConverter().fromJson(
        json['uploadedAt'],
      ),
    );

Map<String, dynamic> _$ClinicalAttachmentToJson(
  ClinicalAttachment instance,
) => <String, dynamic>{
  'id': instance.id,
  'storagePath': instance.storagePath,
  'fileType': instance.fileType,
  'description': instance.description,
  'sizeBytes': instance.sizeBytes,
  'uploadedAt': const _NullableTimestampConverter().toJson(instance.uploadedAt),
};

ClinicalRecord _$ClinicalRecordFromJson(
  Map<String, dynamic> json,
) => ClinicalRecord(
  id: json['id'] as String?,
  petId: json['petId'] as String,
  ownerId: json['ownerId'] as String,
  type: json['type'] as String,
  status: json['status'] as String,
  authorUid: json['authorUid'] as String,
  authorName: json['authorName'] as String,
  createdAt: const _NullableTimestampConverter().fromJson(json['createdAt']),
  attentionDate: json['attentionDate'] as String,
  attentionTime: json['attentionTime'] as String,
  sourceAppointmentId: json['sourceAppointmentId'] as String?,
  patientSnapshot: PatientSnapshot.fromJson(
    json['patientSnapshot'] as Map<String, dynamic>,
  ),
  consultation: json['consultation'] == null
      ? null
      : ConsultationBlock.fromJson(
          json['consultation'] as Map<String, dynamic>,
        ),
  physicalExam: json['physicalExam'] == null
      ? null
      : PhysicalExamBlock.fromJson(
          json['physicalExam'] as Map<String, dynamic>,
        ),
  plan: json['plan'] == null
      ? null
      : PlanBlock.fromJson(json['plan'] as Map<String, dynamic>),
  followUp: json['followUp'] == null
      ? null
      : FollowUpBlock.fromJson(json['followUp'] as Map<String, dynamic>),
  prevention: json['prevention'] == null
      ? null
      : PreventionBlock.fromJson(json['prevention'] as Map<String, dynamic>),
  annulment: json['annulment'] == null
      ? null
      : AnnulmentBlock.fromJson(json['annulment'] as Map<String, dynamic>),
  annulledAt: const _NullableTimestampConverter().fromJson(json['annulledAt']),
  annulledBy: json['annulledBy'] as String?,
  annulledByRecordId: json['annulledByRecordId'] as String?,
  annulmentReason: json['annulmentReason'] as String?,
  attachments: (json['attachments'] as List<dynamic>?)
      ?.map((e) => ClinicalAttachment.fromJson(e as Map<String, dynamic>))
      .toList(),
  isEdited: json['isEdited'] as bool? ?? false,
  version: (json['version'] as num?)?.toInt() ?? 1,
  lastEditedAt: const _NullableTimestampConverter().fromJson(
    json['lastEditedAt'],
  ),
  lastEditedBy: json['lastEditedBy'] as String?,
  lastEditedByName: json['lastEditedByName'] as String?,
);

Map<String, dynamic> _$ClinicalRecordToJson(
  ClinicalRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'petId': instance.petId,
  'ownerId': instance.ownerId,
  'type': instance.type,
  'status': instance.status,
  'authorUid': instance.authorUid,
  'authorName': instance.authorName,
  'createdAt': const _NullableTimestampConverter().toJson(instance.createdAt),
  'attentionDate': instance.attentionDate,
  'attentionTime': instance.attentionTime,
  'sourceAppointmentId': instance.sourceAppointmentId,
  'patientSnapshot': instance.patientSnapshot.toJson(),
  'consultation': instance.consultation?.toJson(),
  'physicalExam': instance.physicalExam?.toJson(),
  'plan': instance.plan?.toJson(),
  'followUp': instance.followUp?.toJson(),
  'prevention': instance.prevention?.toJson(),
  'annulment': instance.annulment?.toJson(),
  'annulledAt': const _NullableTimestampConverter().toJson(instance.annulledAt),
  'annulledBy': instance.annulledBy,
  'annulledByRecordId': instance.annulledByRecordId,
  'annulmentReason': instance.annulmentReason,
  'attachments': instance.attachments?.map((e) => e.toJson()).toList(),
  'isEdited': instance.isEdited,
  'version': instance.version,
  'lastEditedAt': const _NullableTimestampConverter().toJson(
    instance.lastEditedAt,
  ),
  'lastEditedBy': instance.lastEditedBy,
  'lastEditedByName': instance.lastEditedByName,
};
