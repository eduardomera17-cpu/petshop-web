// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: profile_view_model.dart
// Propósito: ViewModel para la gestión, actualización y carga segura de fotografía del perfil del cliente autenticado.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/profile_repository.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

/// ViewModel para la visualización y edición del perfil del cliente.
///
/// Gestiona el estado reactivo de carga, la actualización de campos permitidos en la lista
/// blanca de seguridad (preservando la inmutabilidad de correo, rol y estado), la subida
/// de fotografía mediante intenciones temporales y la descarga de binarios de imagen sin
/// utilizar URLs públicas de descarga.
class ProfileViewModel extends ChangeNotifier {
  /// Repositorio de persistencia del perfil de usuario.
  final ProfileRepository repository;

  /// Constructor con inyección del repositorio de perfil.
  ProfileViewModel({required this.repository});

  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  Failure? _failure;
  String? _successMessage;
  Uint8List? _photoBytes;

  /// Entidad de perfil del usuario cargada en memoria.
  UserProfile? get profile => _profile;

  /// Indica si los datos del perfil se encuentran cargando desde Firestore.
  bool get isLoading => _isLoading;

  /// Indica si la actualización de datos personales se encuentra en proceso.
  bool get isSaving => _isSaving;

  /// Indica si se está subiendo una nueva fotografía de perfil.
  bool get isUploadingPhoto => _isUploadingPhoto;

  /// Mensaje de error para despliegue en la interfaz gráfica.
  String? get errorMessage => _errorMessage;

  /// Objeto de fallo tipado ante errores de infraestructura.
  Failure? get failure => _failure;

  /// Mensaje de éxito tras una actualización completada.
  String? get successMessage => _successMessage;

  /// Bytes de la fotografía de perfil descargada en memoria.
  Uint8List? get photoBytes => _photoBytes;

  /// Limpia los mensajes de error y éxito previos.
  void clearMessages() {
    _errorMessage = null;
    _failure = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Carga el perfil del usuario [uid] desde Firestore y recupera los bytes
  /// de la foto de perfil en memoria en caso de existir ruta configurada.
  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      final res = await repository.getUserProfile(uid);
      if (res.isErr) {
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _profile = res.dataOrNull;
      if (_profile?.photoPath != null && _profile!.photoPath!.isNotEmpty) {
        await _loadPhotoBytes(_profile!.photoPath!);
      } else {
        _photoBytes = null;
      }
    } catch (e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Descarga internamente los bytes de la foto desde Firebase Storage.
  Future<void> _loadPhotoBytes(String path) async {
    final photoRes = await repository.getPhotoBytes(path);
    if (photoRes.isOk) {
      _photoBytes = photoRes.dataOrNull;
    }
  }

  /// Actualiza los campos permitidos del perfil del cliente.
  ///
  /// El correo electrónico `email`, rol y estado son inmutables y no se incluyen en la mutación.
  /// En caso de éxito, actualiza la copia local en memoria sincronizando [searchName].
  Future<bool> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _failure = null;
    _successMessage = null;
    notifyListeners();

    try {
      final res = await repository.updateUserProfile(
        uid: uid,
        fullName: fullName,
        phone: phone,
        documentType: documentType,
        documentNumber: documentNumber,
        address: address,
      );

      if (res.isErr) {
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
        _isSaving = false;
        notifyListeners();
        return false;
      }

      // Actualizar copia local
      if (_profile != null) {
        _profile = _profile!.copyWith(
          fullName: fullName,
          phone: phone,
          documentType: documentType,
          documentNumber: documentNumber,
          address: address,
          searchName: ProfileRepository.normalizeSearchName(fullName),
        );
      }

      _successMessage = 'OK';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Sube la foto del usuario a través del pipeline seguro de intenciones.
  Future<bool> uploadPhoto({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      final res = await repository.uploadProfilePhoto(
        uid: uid,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      if (res.isErr) {
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
        _isUploadingPhoto = false;
        notifyListeners();
        return false;
      }

      // Inmediatamente asociar los bytes en memoria para respuesta visual rápida
      _photoBytes = bytes;
      _isUploadingPhoto = false;
      notifyListeners();
      return true;
    } catch (e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

}
