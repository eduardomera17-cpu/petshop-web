// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clients/view_models/admin_clients_view_model.dart
// Propósito: ViewModel administrativo para la consulta de clientes, inspección de fichas
//            y mascotas, corrección clínica de atributos y reactivación de cuentas.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

/// Gestor de estado administrativo para el directorio de clientes y sus mascotas.
///
/// Facilita la búsqueda por prefijo de clientes registrados, visualización de fichas
/// de sólo lectura de clientes y sus pacientes asociados, corrección veterinaria de
/// atributos anatómicos de mascotas (sexo y estado reproductivo) y reactivación de
/// cuentas de usuarios o mascotas previamente desactivadas.
class AdminClientsViewModel extends ChangeNotifier {
  /// Repositorio de agenda y directorio de clientes/mascotas.
  final AgendaRepository agendaRepository;

  StreamSubscription<List<UserProfile>>? _clientsSub;
  StreamSubscription<List<UserProfile>>? _deactivatedSub;
  StreamSubscription<List<Pet>>? _petsSub;

  int _selectedTab = 0; // 0: Clientes Activos, 1: Cuentas Desactivadas

  /// Pestaña actualmente seleccionada (0: Clientes Activos, 1: Cuentas Desactivadas).
  int get selectedTab => _selectedTab;

  String _searchQuery = '';

  /// Cadena o prefijo de búsqueda para filtrar la lista de clientes.
  String get searchQuery => _searchQuery;

  List<UserProfile> _activeClients = [];

  /// Lista reactiva de clientes activos en la plataforma.
  List<UserProfile> get activeClients => _activeClients;

  List<UserProfile> _deactivatedUsers = [];

  /// Lista reactiva de usuarios cuyas cuentas se encuentran desactivadas.
  List<UserProfile> get deactivatedUsers => _deactivatedUsers;

  UserProfile? _selectedClient;

  /// Cliente seleccionado para inspeccionar su ficha de información y mascotas.
  UserProfile? get selectedClient => _selectedClient;

  List<Pet> _selectedClientPets = [];

  /// Lista de mascotas pertenecientes al cliente seleccionado.
  List<Pet> get selectedClientPets => _selectedClientPets;

  bool _isLoading = true;

  /// Indica si la lista de clientes está en proceso de carga inicial.
  bool get isLoading => _isLoading;

  bool _isActionInProgress = false;

  /// Indica si se encuentra en ejecución una acción administrativa de mutación.
  bool get isActionInProgress => _isActionInProgress;

  String? _errorMessage;

  /// Código o mensaje descriptivo en caso de anomalías operativas.
  String? get errorMessage => _errorMessage;

  Failure? _failure;

  /// Falla tipada reportada por las operaciones del repositorio.
  Failure? get failure => _failure;

  /// Inicializa el ViewModel y suscribe la escucha de clientes activos y desactivados.
  AdminClientsViewModel({
    required this.agendaRepository,
  }) {
    init();
  }

  /// Inicia la sincronización reactiva de clientes activos y desactivados.
  void init() {
    _isLoading = true;
    notifyListeners();

    _listenActiveClients();
    _listenDeactivatedUsers();
  }

  void _listenActiveClients() {
    _clientsSub?.cancel();
    _clientsSub = agendaRepository.streamClients(prefixQuery: _searchQuery).listen(
      (items) {
        _activeClients = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        notifyListeners();
      },
    );
  }

  void _listenDeactivatedUsers() {
    _deactivatedSub?.cancel();
    _deactivatedSub = agendaRepository.streamDeactivatedUsers().listen(
      (items) {
        _deactivatedUsers = items;
        notifyListeners();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        notifyListeners();
      },
    );
  }

  /// Alterna entre la pestaña de clientes activos y usuarios desactivados.
  void setSelectedTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  /// Actualiza la consulta de búsqueda y reactiva el filtrado de clientes.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _listenActiveClients();
  }

  /// Selecciona un cliente para desplegar su ficha de sólo lectura (CA-AD-27).
  void selectClient(UserProfile client) {
    _selectedClient = client;
    notifyListeners();

    _petsSub?.cancel();
    _petsSub = agendaRepository.streamClientPets(client.uid).listen(
      (pets) {
        _selectedClientPets = pets;
        notifyListeners();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        notifyListeners();
      },
    );
  }

  /// Limpia la selección actual del cliente y desuscribe la escucha de sus mascotas.
  void clearSelectedClient() {
    _selectedClient = null;
    _selectedClientPets = [];
    _petsSub?.cancel();
    notifyListeners();
  }

  /// Corrección de sexo y estado reproductivo de la mascota (CL-07, firestore.rules).
  Future<bool> updatePetStaffCorrection({
    required String petId,
    required String staffUid,
    required String sex,
    required String reproductiveStatus,
  }) async {
    _isActionInProgress = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.updatePetStaffCorrection(
      petId: petId,
      staffUid: staffUid,
      sex: sex,
      reproductiveStatus: reproductiveStatus,
    );
    _isActionInProgress = false;

    return result.when(
      ok: (_) {
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

  /// Reactivación de cuenta de usuario o mascota (CL-09, CF-12, CA-AD-38).
  Future<bool> reactivateAccountOrPet({
    required String entityType,
    required String entityId,
  }) async {
    _isActionInProgress = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.reactivateAccountOrPet(
      entityType: entityType,
      entityId: entityId,
    );
    _isActionInProgress = false;

    return result.when(
      ok: (_) {
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

  /// Libera suscripciones a clientes activos, desactivados y mascotas.
  @override
  void dispose() {
    _clientsSub?.cancel();
    _deactivatedSub?.cancel();
    _petsSub?.cancel();
    super.dispose();
  }
}
