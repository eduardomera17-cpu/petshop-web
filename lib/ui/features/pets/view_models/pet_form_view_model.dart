// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: pet_form_view_model.dart
// Propósito: ViewModel para la creación y edición de fichas de mascotas, cálculo de edad aproximada con reloj de negocio y carga segura de fotografía.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';

/// ViewModel para el registro y edición de la ficha clínica/personal de una mascota.
///
/// Soporta tanto el ingreso directo de la fecha exacta de nacimiento (`YYYY-MM-DD`)
/// como el cálculo alternativo de fecha probable a partir de edad aproximada (años y meses)
/// utilizando estrictamente [BusinessClock.now] para mantener coherencia temporal.
/// Gestiona además la subida y visualización de la fotografía del paciente a través del
/// protocolo seguro de dos fases de Firebase Storage (cero URLs públicas).
class PetFormViewModel extends ChangeNotifier {
  /// Repositorio de gestión y persistencia de mascotas.
  final PetsRepository repository;

  /// Mascota inicial cargada en caso de edición (es `null` para nuevas mascotas).
  final Pet? initialPet;

  /// Constructor que inicializa los campos con los datos de [initialPet] si se encuentra en modo edición.
  PetFormViewModel({
    required this.repository,
    this.initialPet,
  }) {
    if (initialPet != null) {
      _petId = initialPet!.id;
      _name = initialPet!.name;
      _species = initialPet!.species;
      _sex = initialPet!.sex;
      _reproductiveStatus = initialPet!.reproductiveStatus;
      _breed = initialPet!.breed;
      _birthDate = initialPet!.birthDate;
      _allergies = initialPet!.allergies;
    }
  }

  /// Indica si el formulario se encuentra en modo de edición de una mascota existente.
  bool get isEditing => initialPet != null;

  String? _petId;
  String? get petId => _petId;

  String _name = '';
  /// Nombre o apodo de la mascota.
  String get name => _name;

  String _species = 'DOG';
  /// Especie de la mascota (`DOG`, `CAT`, etc.).
  String get species => _species;

  String _sex = 'MALE';
  /// Sexo biológico (`MALE`, `FEMALE`).
  String get sex => _sex;

  String _reproductiveStatus = 'INTACT';
  /// Estado reproductivo (`INTACT`, `NEUTERED`).
  String get reproductiveStatus => _reproductiveStatus;

  String? _breed;
  /// Raza de la mascota.
  String? get breed => _breed;

  String? _birthDate;
  /// Fecha de nacimiento en formato `YYYY-MM-DD`.
  String? get birthDate => _birthDate;

  String? _allergies;
  /// Alergias o condiciones médicas preexistentes.
  String? get allergies => _allergies;

  Uint8List? _photoBytes;
  /// Bytes binarios de la fotografía cargada en memoria.
  Uint8List? get photoBytes => _photoBytes;

  bool _isSaving = false;
  /// Indica si la operación de guardado se encuentra en curso.
  bool get isSaving => _isSaving;

  bool _isUploadingPhoto = false;
  /// Indica si se está subiendo una fotografía a Storage.
  bool get isUploadingPhoto => _isUploadingPhoto;

  String? _errorMessage;
  /// Mensaje de error para despliegue en interfaz.
  String? get errorMessage => _errorMessage;

  Failure? _failure;
  /// Objeto de fallo tipado ante errores de infraestructura o dominio.
  Failure? get failure => _failure;

  String? _createdPetId;
  /// Identificador asignado a la nueva mascota tras guardarse exitosamente.
  String? get createdPetId => _createdPetId;

  /// Asigna el nombre de la mascota y notifica a los oyentes.
  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  /// Asigna la especie biológica de la mascota (`DOG`, `CAT`, etc.).
  void setSpecies(String val) {
    _species = val;
    notifyListeners();
  }

  /// Asigna el sexo de la mascota (`MALE`, `FEMALE`).
  void setSex(String val) {
    _sex = val;
    notifyListeners();
  }

  /// Asigna el estado reproductivo (`INTACT`, `NEUTERED`).
  void setReproductiveStatus(String val) {
    _reproductiveStatus = val;
    notifyListeners();
  }

  /// Asigna la raza o cruce de la mascota.
  void setBreed(String? val) {
    _breed = val;
    notifyListeners();
  }

  /// Establece la fecha de nacimiento en formato `YYYY-MM-DD`.
  void setBirthDate(String? val) {
    _birthDate = val;
    notifyListeners();
  }

  /// Registra alergias o notas médicas preventivas.
  void setAllergies(String? val) {
    _allergies = val;
    notifyListeners();
  }

  /// Fija los bytes de la fotografía seleccionada para previsualización inmediata.
  void setPhotoBytes(Uint8List bytes) {
    _photoBytes = bytes;
    notifyListeners();
  }

  /// Calcula la fecha de nacimiento aproximada a partir de años y meses.
  ///
  /// Utiliza estrictamente [BusinessClock.now()] para garantizar paridad y
  /// evitar el uso directo de `DateTime.now()`. Resta el número estimado de días
  /// y formatea el resultado en `YYYY-MM-DD`.
  void setAgeApproximate({required int years, required int months}) {
    final now = BusinessClock.now();
    final totalDays = (years * 365) + (months * 30);
    final approxDate = now.subtract(Duration(days: totalDays));

    final yearStr = approxDate.year.toString().padLeft(4, '0');
    final monthStr = approxDate.month.toString().padLeft(2, '0');
    final dayStr = approxDate.day.toString().padLeft(2, '0');

    _birthDate = '$yearStr-$monthStr-$dayStr';
    notifyListeners();
  }

  /// Carga la foto existente de la mascota usando descarga binaria segura en memoria.
  Future<void> loadExistingPhoto(String photoPath) async {
    final res = await repository.getPhotoBytes(photoPath);
    if (res.isOk && res.dataOrNull != null) {
      _photoBytes = res.dataOrNull;
      notifyListeners();
    }
  }

  /// Guarda la mascota ejecutando creación o actualización según [isEditing].
  ///
  /// Recibe el identificador del dueño [ownerId].
  Future<bool> savePet({
    required String ownerId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      if (isEditing) {
        final result = await repository.updatePet(
          petId: initialPet!.id,
          uid: ownerId,
          name: _name,
          species: _species,
          sex: _sex,
          reproductiveStatus: _reproductiveStatus,
          breed: _breed,
          birthDate: _birthDate,
          allergies: _allergies,
        );

        _isSaving = false;
        if (result.isOk) {
          notifyListeners();
          return true;
        } else {
          _failure = result.failureOrNull;
          _errorMessage = _failure?.code;
          notifyListeners();
          return false;
        }
      } else {
        final result = await repository.createPet(
          ownerId: ownerId,
          name: _name,
          species: _species,
          sex: _sex,
          reproductiveStatus: _reproductiveStatus,
          breed: _breed,
          birthDate: _birthDate,
          allergies: _allergies,
        );

        _isSaving = false;
        if (result.isOk) {
          _createdPetId = result.dataOrNull;
          notifyListeners();
          return true;
        } else {
          _failure = result.failureOrNull;
          _errorMessage = _failure?.code;
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Sube la foto de la mascota a través del protocolo de intención de subida.
  ///
  /// Deposita los [bytes] en `uploads/{uid}/{intentId}/{fileName}` con metadatos de tipo [mimeType].
  Future<bool> uploadPhoto({
    required String uid,
    required String petId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      final res = await repository.uploadPetPhoto(
        uid: uid,
        petId: petId,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      _isUploadingPhoto = false;
      if (res.isOk) {
        _photoBytes = bytes;
        notifyListeners();
        return true;
      } else {
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }
}
