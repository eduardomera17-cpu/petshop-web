// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: pets_list_view_model.dart
// Propósito: ViewModel para la visualización reactiva de mascotas del cliente, con precarga y caché en memoria de fotografías binarias.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';

/// ViewModel para la lista de mascotas del cliente.
///
/// Gestiona la sincronización en tiempo real de la colección de mascotas pertenecientes al usuario,
/// la descarga binaria segura de fotos mediante [PetsRepository.getPhotoBytes] (evitando URLs públicas)
/// y el almacenamiento en caché local de imágenes en memoria para una renderización fluida.
class PetsListViewModel extends ChangeNotifier {
  /// Repositorio de gestión de mascotas.
  final PetsRepository repository;

  /// Constructor con inyección del repositorio de mascotas.
  PetsListViewModel({required this.repository});

  bool _isLoading = false;
  /// Indica si la lista de mascotas se encuentra en proceso de carga.
  bool get isLoading => _isLoading;

  String? _errorMessage;
  /// Mensaje de error para despliegue en la interfaz gráfica.
  String? get errorMessage => _errorMessage;

  Failure? _failure;
  /// Fallo tipado en caso de error en la consulta.
  Failure? get failure => _failure;

  List<Pet> _pets = [];
  /// Lista reactiva de mascotas del cliente autenticado.
  List<Pet> get pets => _pets;

  final Map<String, Uint8List?> _photoCache = {};
  /// Obtiene los bytes de la fotografía en caché correspondientes a [petId].
  Uint8List? getPhoto(String petId) => _photoCache[petId];

  StreamSubscription<List<Pet>>? _petsSubscription;

  /// Inicia la escucha en tiempo real de las mascotas pertenecientes a [ownerId].
  ///
  /// Actualiza automáticamente la lista local y dispara la precarga en segundo plano
  /// de las fotografías de cada mascota.
  void startListening(String ownerId) {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    _petsSubscription?.cancel();
    _petsSubscription = repository.streamPets(ownerId).listen(
      (petsList) {
        _pets = petsList;
        _isLoading = false;
        _errorMessage = null;
        _failure = null;
        notifyListeners();
        _preloadPhotos();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Carga puntual de mascotas sin suscripción reactiva (útil en pruebas unitarias o inicialización estática).
  Future<void> loadPets(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final result = await repository.getPets(ownerId);
    if (result.isOk) {
      _pets = result.dataOrNull ?? [];
      _isLoading = false;
      notifyListeners();
      await _preloadPhotos();
    } else {
      _failure = result.failureOrNull;
      _errorMessage = _failure?.code;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Descarga en memoria las imágenes de las mascotas que aún no residan en [_photoCache].
  Future<void> _preloadPhotos() async {
    for (final pet in _pets) {
      if (pet.photoPath != null &&
          pet.photoPath!.isNotEmpty &&
          !_photoCache.containsKey(pet.id)) {
        final res = await repository.getPhotoBytes(pet.photoPath);
        if (res.isOk && res.dataOrNull != null) {
          _photoCache[pet.id] = res.dataOrNull;
          notifyListeners();
        }
      }
    }
  }

  /// Asocia directamente una foto en la memoria caché (utilizado para vistas previas inmediatas tras subida).
  void setPhotoCache(String petId, Uint8List bytes) {
    _photoCache[petId] = bytes;
    notifyListeners();
  }

  /// Cancela la suscripción al flujo de mascotas de Firestore.
  @override
  void dispose() {
    _petsSubscription?.cancel();
    super.dispose();
  }
}
