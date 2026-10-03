// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/governance/view_models/governance_view_model.dart
// Propósito: ViewModel para el gobierno institucional de cuentas, configuración
//            de parámetros de negocio y auditoría inmutable de eventos (SUPERADMIN).
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/governance_repository.dart';
import 'package:mipetshop/domain/models/audit_log_entry.dart';
import 'package:mipetshop/domain/models/operating_parameters.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

/// ViewModel para la administración del gobierno institucional bajo el patrón MVVM (D-T1).
///
/// Desacoplado de la infraestructura directa de Firebase; todas las consultas y mutaciones
/// son canalizadas mediante [GovernanceRepository]. Administra el aprovisionamiento de cuentas,
/// restablecimiento seguro de claves, baja y reactivación de usuarios, configuración operativa
/// del petshop y la supervisión del registro de auditoría inmutable del sistema.
class GovernanceViewModel extends ChangeNotifier {
  /// Repositorio de operaciones y llamadas de gobierno institucional.
  final GovernanceRepository repository;

  /// Construye el ViewModel y dispara la carga unificada de usuarios, parámetros y auditoría.
  GovernanceViewModel({
    required this.repository,
  }) {
    loadAll();
  }

  Failure? _usersFailure;

  /// Detalle de falla suscitada al cargar el listado de usuarios.
  Failure? get usersFailure => _usersFailure;

  Failure? _paramsFailure;

  /// Detalle de falla suscitada al cargar los parámetros operativos.
  Failure? get paramsFailure => _paramsFailure;

  Failure? _auditFailure;

  /// Detalle de falla suscitada al consultar la bitácora de auditoría.
  Failure? get auditFailure => _auditFailure;

  Failure? _actionFailure;

  /// Detalle de falla resultante de la última acción administrativa ejecutada.
  Failure? get actionFailure => _actionFailure;

  /// Falla consolidada activa para despliegue prioritario de alertas en pantalla.
  Failure? get failure => _actionFailure ?? _usersFailure ?? _paramsFailure ?? _auditFailure;

  // ────────────────────────────────────────────────────────────────────────────
  // PESTAÑAS Y NAVEGACIÓN
  // ────────────────────────────────────────────────────────────────────────────
  int _selectedTab = 0;

  /// Índice de la pestaña activa en la vista de gobierno (0: Usuarios, 1: Parámetros, 2: Auditoría).
  int get selectedTab => _selectedTab;

  /// Cambia de pestaña activa y notifica a la interfaz de usuario.
  void setTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GESTIÓN DE CUENTAS DE USUARIO
  // ────────────────────────────────────────────────────────────────────────────
  List<UserProfile> _users = [];

  /// Lista global de usuarios del sistema cargados desde Firestore.
  List<UserProfile> get users => _users;

  bool _isLoadingUsers = false;

  /// Indica si el listado de usuarios se encuentra en proceso de carga.
  bool get isLoadingUsers => _isLoadingUsers;

  String? _usersError;

  /// Código o mensaje de error en la consulta de usuarios.
  String? get usersError => _usersError;

  String _searchQuery = '';

  /// Término de búsqueda textual para filtrar usuarios por nombre, correo o cédula.
  String get searchQuery => _searchQuery;

  String _roleFilter = 'ALL';

  /// Filtro activo por rol de usuario ('ALL', 'CLIENT', 'ADMIN', 'VET', 'SUPERADMIN').
  String get roleFilter => _roleFilter;

  /// Establece la consulta de búsqueda textual sobre los usuarios.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Establece el filtro de rol operativo para la tabla de usuarios.
  void setRoleFilter(String role) {
    _roleFilter = role;
    notifyListeners();
  }

  /// Lista de usuarios filtrados según el rol y término de búsqueda vigentes.
  List<UserProfile> get filteredUsers {
    return _users.where((u) {
      final matchesRole = _roleFilter == 'ALL' || u.role == _roleFilter;
      if (!matchesRole) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.trim().toLowerCase();
      final inName = u.fullName.toLowerCase().contains(query);
      final inEmail = u.email.toLowerCase().contains(query);
      final inDoc = u.documentNumber.toLowerCase().contains(query);
      return inName || inEmail || inDoc;
    }).toList();
  }

  /// Recupera el listado completo de usuarios desde el repositorio.
  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    final result = await repository.getUsers();
    result.when(
      ok: (data) {
        _users = data;
        _isLoadingUsers = false;
        _usersFailure = null;
        notifyListeners();
      },
      err: (failure) {
        _usersFailure = failure;
        _usersError = failure.code;
        _isLoadingUsers = false;
        notifyListeners();
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PARÁMETROS OPERATIVOS DEL NEGOCIO
  // ────────────────────────────────────────────────────────────────────────────
  OperatingParameters _operatingParameters = const OperatingParameters();

  /// Parámetros de negocio vigentes (horarios de atención, días laborales, umbrales de stock).
  OperatingParameters get operatingParameters => _operatingParameters;

  bool _isLoadingParams = false;

  /// Indica si se encuentra consultando la configuración operativa.
  bool get isLoadingParams => _isLoadingParams;

  String? _paramsError;

  /// Mensaje o código de fallo al cargar la configuración operativa.
  String? get paramsError => _paramsError;

  /// Consulta la configuración de parámetros operativos del negocio.
  Future<void> loadOperatingParameters() async {
    _isLoadingParams = true;
    _paramsError = null;
    notifyListeners();

    final result = await repository.getOperatingParameters();
    result.when(
      ok: (data) {
        _operatingParameters = data;
        _isLoadingParams = false;
        _paramsFailure = null;
        notifyListeners();
      },
      err: (failure) {
        _paramsFailure = failure;
        _paramsError = failure.code;
        _isLoadingParams = false;
        notifyListeners();
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // REGISTRO INMUTABLE DE AUDITORÍA
  // ────────────────────────────────────────────────────────────────────────────
  List<AuditLogEntry> _auditLogs = [];

  /// Bitácora inmutable de eventos de auditoría administrativa.
  List<AuditLogEntry> get auditLogs => _auditLogs;

  bool _isLoadingAudit = false;

  /// Indica si la bitácora de auditoría se encuentra en proceso de consulta.
  bool get isLoadingAudit => _isLoadingAudit;

  String? _auditError;

  /// Código o descripción de error en la consulta de registros de auditoría.
  String? get auditError => _auditError;

  String _auditActionFilter = 'ALL';

  /// Filtro activo por tipo de acción de auditoría ('ALL' o acción específica).
  String get auditActionFilter => _auditActionFilter;

  /// Aplica un filtro específico sobre el tipo de acción en la bitácora de auditoría.
  void setAuditActionFilter(String action) {
    _auditActionFilter = action;
    notifyListeners();
  }

  /// Lista de eventos de auditoría filtrados según la acción seleccionada.
  List<AuditLogEntry> get filteredAuditLogs {
    if (_auditActionFilter == 'ALL') return _auditLogs;
    return _auditLogs.where((log) => log.action == _auditActionFilter).toList();
  }

  /// Conjunto ordenado de tipos de acciones únicas registradas en los logs.
  List<String> get availableAuditActions {
    final actions = _auditLogs.map((log) => log.action).toSet().toList();
    actions.sort();
    return actions;
  }

  /// Recupera los eventos de auditoría inmutables desde el repositorio.
  Future<void> loadAuditLogs() async {
    _isLoadingAudit = true;
    _auditError = null;
    notifyListeners();

    final result = await repository.getAuditLogs();
    result.when(
      ok: (data) {
        _auditLogs = data;
        _isLoadingAudit = false;
        _auditFailure = null;
        notifyListeners();
      },
      err: (failure) {
        _auditFailure = failure;
        _auditError = failure.code;
        _isLoadingAudit = false;
        notifyListeners();
      },
    );
  }

  /// Desencadena concurrentemente la carga de usuarios, parámetros y auditoría.
  Future<void> loadAll() async {
    await Future.wait([
      loadUsers(),
      loadOperatingParameters(),
      loadAuditLogs(),
    ]);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FEEDBACK Y ENLACE SEGURO EN PANTALLA
  // ────────────────────────────────────────────────────────────────────────────
  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _actionSuccessMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  String? _actionErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  String? _lastGeneratedLink;
  String? get lastGeneratedLink => _lastGeneratedLink;

  String? _linkDialogTitle;
  String? get linkDialogTitle => _linkDialogTitle;

  void clearActionFeedback() {
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    _actionFailure = null;
    notifyListeners();
  }

  void clearGeneratedLink() {
    _lastGeneratedLink = null;
    _linkDialogTitle = null;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // OPERACIONES DE GOBIERNO (CALLABLES)
  // ────────────────────────────────────────────────────────────────────────────

  /// Aprovisiona cuenta nueva y entrega el enlace en pantalla (CF-07, CA-AD-25).
  Future<bool> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.createUserAccount(
      email: email,
      fullName: fullName,
      role: role,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
      address: address,
    );

    _isActionLoading = false;

    return result.when(
      ok: (data) {
        final link = data['resetLink'] as String? ?? '';
        _lastGeneratedLink = link;
        _linkDialogTitle = 'CUENTA_CREADA';
        _actionFailure = null;
        notifyListeners();
        loadUsers();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Actualiza datos de identidad conservando email inmutable (CF-08).
  Future<bool> updateUserIdentity({
    required String targetUid,
    String? fullName,
    String? phone,
    String? documentType,
    String? documentNumber,
    String? address,
  }) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.updateUserIdentity(
      targetUid: targetUid,
      fullName: fullName,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
      address: address,
    );

    _isActionLoading = false;

    return result.when(
      ok: (_) {
        _actionSuccessMessage = 'Identidad actualizada correctamente.';
        _actionFailure = null;
        notifyListeners();
        loadUsers();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Genera enlace de restablecimiento de contraseña para entrega en pantalla (CF-06, CA-AD-25).
  Future<bool> resetUserPassword(String targetUid) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.resetUserPassword(targetUid: targetUid);

    _isActionLoading = false;

    return result.when(
      ok: (data) {
        final link = data['resetLink'] as String? ?? '';
        _lastGeneratedLink = link;
        _linkDialogTitle = 'RESTABLECIMIENTO';
        _actionFailure = null;
        notifyListeners();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Desactiva administrativamente una cuenta de usuario (CF-09, CA-AD-37).
  Future<bool> deactivateUserAccount(String targetUid) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.deactivateUserAccount(targetUid: targetUid);

    _isActionLoading = false;

    return result.when(
      ok: (_) {
        _actionSuccessMessage = 'Cuenta desactivada correctamente.';
        _actionFailure = null;
        notifyListeners();
        loadUsers();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Reactiva una cuenta de usuario previamente desactivada.
  Future<bool> reactivateUserAccount(String targetUid) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.reactivateUserAccount(targetUid: targetUid);

    _isActionLoading = false;

    return result.when(
      ok: (_) {
        _actionSuccessMessage = 'Cuenta reactivada correctamente.';
        _actionFailure = null;
        notifyListeners();
        loadUsers();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Da de baja lógica a una cuenta de personal administrativo (CF-09, CA-AD-37).
  Future<bool> deleteStaffAccount(String targetUid) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.deleteStaffAccount(targetUid: targetUid);

    _isActionLoading = false;

    return result.when(
      ok: (_) {
        _actionSuccessMessage = 'Personal dado de baja lógica correctamente.';
        _actionFailure = null;
        notifyListeners();
        loadUsers();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Actualiza la configuración operativa del negocio sin exponer zona horaria (CF-01, CF-02, IN-03).
  Future<bool> updateOperatingParameters({
    String? openingTime,
    String? closingTime,
    int? slotDurationMinutes,
    List<int>? workingWeekdays,
    int? lowStockThreshold,
  }) async {
    _isActionLoading = true;
    _actionSuccessMessage = null;
    _actionErrorMessage = null;
    notifyListeners();

    final result = await repository.updateOperatingParameters(
      openingTime: openingTime,
      closingTime: closingTime,
      slotDurationMinutes: slotDurationMinutes,
      workingWeekdays: workingWeekdays,
      lowStockThreshold: lowStockThreshold,
    );

    _isActionLoading = false;

    return result.when(
      ok: (_) {
        _actionSuccessMessage = 'Parámetros operativos actualizados correctamente.';
        _actionFailure = null;
        notifyListeners();
        loadOperatingParameters();
        loadAuditLogs();
        return true;
      },
      err: (failure) {
        _actionFailure = failure;
        _actionErrorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }
}
