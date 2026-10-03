// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/chat/view_models/staff_inbox_view_model.dart
// Propósito: ViewModel para la bandeja de entrada compartida del personal administrativo/veterinario,
//            gestión de lectura, archivado y acciones privilegiadas de moderación (SUPERADMIN).
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/models/chat.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';

/// Gestor de estado para la bandeja de entrada unificada de conversaciones del personal.
///
/// Proporciona la lista en tiempo real de todas las salas de chat activas o archivadas,
/// cálculo reactivo de mensajes pendientes por leer, selección de sala activa,
/// archivado/desarchivado y operaciones de moderación administrativa (bloqueo de sala y
/// eliminación forzada de mensajes ofensivos) reservadas para el rol SUPERADMIN.
class StaffInboxViewModel extends ChangeNotifier {
  /// Repositorio de chat para la sincronización de bandejas y ejecución de moderación.
  final ChatRepository chatRepository;

  /// Identificador único del miembro del personal autenticado.
  final String currentStaffUid;

  /// Nombre del miembro del personal autenticado.
  final String currentStaffName;

  /// Rol operativo del miembro del personal ('ADMIN', 'VET', 'SUPERADMIN', etc.).
  final String currentStaffRole;

  StreamSubscription<List<ChatDto>>? _chatsSub;

  List<ChatDto> _allChats = [];
  bool _showArchived = false;

  /// Indica si la bandeja está configurada para listar salas archivadas en vez de activas.
  bool get showArchived => _showArchived;

  ChatDto? _selectedChat;

  /// Conversación seleccionada actualmente para visualización o moderación.
  ChatDto? get selectedChat => _selectedChat;

  bool _isLoading = true;

  /// Indica si se encuentra cargando el listado inicial de conversaciones.
  bool get isLoading => _isLoading;

  String? _errorMessage;

  /// Mensaje o código de error en caso de anomalías operativas.
  String? get errorMessage => _errorMessage;

  Failure? _failure;

  /// Falla tipada devuelta por las operaciones del repositorio.
  Failure? get failure => _failure;

  String? _successMessage;

  /// Mensaje de confirmación tras aplicar con éxito una acción administrativa.
  String? get successMessage => _successMessage;

  /// Determina si el usuario autenticado posee permisos de SUPERADMIN para moderación.
  bool get isSuperAdmin => currentStaffRole == 'SUPERADMIN';

  /// Inicializa la bandeja compartida comenzando la escucha reactiva del flujo de salas.
  StaffInboxViewModel({
    required this.chatRepository,
    required this.currentStaffUid,
    required this.currentStaffName,
    required this.currentStaffRole,
  }) {
    _initStream();
  }

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _chatsSub?.cancel();
    _chatsSub = chatRepository.streamStaffChats(includeArchived: _showArchived).listen(
      (items) {
        // Ordenar cronológicamente por lastMessageTimestamp descendente
        items.sort((a, b) {
          final tA = a.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = b.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });

        _allChats = items;
        _isLoading = false;
        _errorMessage = null;
        _failure = null;

        if (_selectedChat != null) {
          _selectedChat = _allChats.cast<ChatDto?>().firstWhere(
                (c) => c?.id == _selectedChat!.id,
                orElse: () => null,
              );
        }

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

  /// Alterna el filtro de salas archivadas
  void toggleShowArchived() {
    _showArchived = !_showArchived;
    _selectedChat = null;
    _initStream();
  }

  /// Selecciona una sala y marca los mensajes pendientes como leídos
  Future<void> selectChat(ChatDto chat) async {
    _selectedChat = chat;
    notifyListeners();

    if (chat.id != null && chat.staffUnreadCount > 0) {
      await markAsRead(chat.id!);
    }
  }

  /// Deselecciona la sala activa
  void clearSelectedChat() {
    _selectedChat = null;
    notifyListeners();
  }

  /// Marca la sala como leída mediante la callable oficial markChatAsRead (MC-09, TRD §3.4.F)
  Future<void> markAsRead(String chatId) async {
    final result = await chatRepository.markChatAsRead(chatId);
    result.when(
      ok: (_) {
        // Actualizar localmente si está seleccionada
        if (_selectedChat != null && _selectedChat!.id == chatId) {
          _selectedChat = ChatDto(
            id: _selectedChat!.id,
            type: _selectedChat!.type,
            clientId: _selectedChat!.clientId,
            clientName: _selectedChat!.clientName,
            clientSearchName: _selectedChat!.clientSearchName,
            isArchived: _selectedChat!.isArchived,
            isBlocked: _selectedChat!.isBlocked,
            staffUnreadCount: 0,
            lastMessageText: _selectedChat!.lastMessageText,
            lastMessageTimestamp: _selectedChat!.lastMessageTimestamp,
            lastMessageSenderName: _selectedChat!.lastMessageSenderName,
            lastMessageSenderUid: _selectedChat!.lastMessageSenderUid,
            messageCount: _selectedChat!.messageCount,
            createdAt: _selectedChat!.createdAt,
            updatedAt: _selectedChat!.updatedAt,
          );
        }
        notifyListeners();
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
      },
    );
  }

  /// Archiva o desarchiva una sala de chat (MC-04, TRD §4.4 bloque 14)
  Future<void> setArchived(String chatId, bool isArchived) async {
    final result = await chatRepository.setArchived(
      chatId: chatId,
      isArchived: isArchived,
    );

    result.when(
      ok: (_) {
        _successMessage = isArchived
            ? 'Conversación archivada correctamente.'
            : 'Conversación desarchivada.';
        notifyListeners();
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
      },
    );
  }

  /// Modera la eliminación de un mensaje ajeno (Exclusivo SUPERADMIN, MC-08, TRD §3.4.E)
  Future<bool> moderateDeleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    if (!isSuperAdmin) {
      _errorMessage = 'Operación de moderación restringida exclusivamente a Super Usuarios.';
      notifyListeners();
      return false;
    }

    final result = await chatRepository.moderateChat(
      operation: 'DELETE_MESSAGE',
      chatId: chatId,
      messageId: messageId,
    );

    return result.when(
      ok: (_) {
        _successMessage = 'Mensaje moderado y eliminado con éxito.';
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

  /// Modera el bloqueo de una sala de chat (Exclusivo SUPERADMIN, MC-08, TRD §3.4.E)
  Future<bool> moderateBlockChat(String chatId) async {
    if (!isSuperAdmin) {
      _errorMessage = 'Operación de moderación restringida exclusivamente a Super Usuarios.';
      notifyListeners();
      return false;
    }

    final result = await chatRepository.moderateChat(
      operation: 'BLOCK_ROOM',
      chatId: chatId,
    );

    return result.when(
      ok: (_) {
        _successMessage = 'Conversación bloqueada administrativamente.';
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

  /// Modera el desbloqueo de una sala de chat (Exclusivo SUPERADMIN, MC-08, TRD §3.4.E)
  Future<bool> moderateUnblockChat(String chatId) async {
    if (!isSuperAdmin) {
      _errorMessage = 'Operación de moderación restringida exclusivamente a Super Usuarios.';
      notifyListeners();
      return false;
    }

    final result = await chatRepository.moderateChat(
      operation: 'UNBLOCK_ROOM',
      chatId: chatId,
    );

    return result.when(
      ok: (_) {
        _successMessage = 'Conversación desbloqueada administrativamente.';
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

  bool _isDisposed = false;

  /// Notifica a los observadores sólo si el ViewModel no ha sido destruido.
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Cancela suscripciones activas y marca el estado como descartado.
  @override
  void dispose() {
    _isDisposed = true;
    _chatsSub?.cancel();
    super.dispose();
  }
}
