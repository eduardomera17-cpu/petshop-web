// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: chat_repository.dart
// Propósito: Repositorio para la mensajería en tiempo real, control de lectura y moderación de chats.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/chat.dart';
import 'package:mipetshop/data/models/chat_message.dart';
import 'package:mipetshop/data/models/read_state.dart';
import 'package:mipetshop/data/services/functions_service.dart';

/// Repositorio de mensajería en tiempo real y moderación de conversaciones.
///
/// Gestiona la interacción con las colecciones `/chats`, la subcolección de mensajes `/messages`
/// y la subcolección de marcas de lectura `/read_states` en Cloud Firestore.
class ChatRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Servicio cliente de Cloud Functions para acciones moderadas o atómicas.
  final FunctionsService _functionsService;

  /// Constructor del repositorio de chat.
  ChatRepository({
    required this.firestore,
    FunctionsService? functionsService,
  })  : _functionsService = functionsService ?? FunctionsService();

  FirebaseFirestore get _firestore => firestore;

  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _firestore.collection('chats');

  /// Escucha en tiempo real la bandeja de chats para el personal de la tienda.
  ///
  /// @param includeArchived Define si incluye salas archivadas.
  /// @return Stream con la lista de conversaciones [ChatDto].
  Stream<List<ChatDto>> streamStaffChats({bool includeArchived = false}) {
    return _chatsCol
        .where('isArchived', isEqualTo: includeArchived)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatDto.fromFirestore(doc))
          .toList();
    });
  }

  /// Escucha en tiempo real una sala de chat específica por su identificador.
  ///
  /// @param chatId ID del documento de chat.
  Stream<ChatDto?> streamChat(String chatId) {
    return _chatsCol.doc(chatId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return ChatDto.fromFirestore(snapshot);
    });
  }

  /// Escucha en tiempo real los mensajes de una sala en orden cronológico ascendente.
  ///
  /// @param chatId ID de la sala de conversación.
  /// @param limit Límite de mensajes a cargar (por defecto 100).
  Stream<List<ChatMessageDto>> streamMessages(String chatId, {int limit = 100}) {
    return _chatsCol
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageDto.fromFirestore(doc))
          .toList();
    });
  }

  /// Escucha las marcas de lectura de un miembro del personal en el canal interno.
  ///
  /// @param uid Identificador del usuario del personal.
  Stream<ReadStateDto?> streamStaffReadState(String uid) {
    return _chatsCol
        .doc('STAFF_INTERNAL')
        .collection('read_states')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return ReadStateDto.fromFirestore(snapshot);
    });
  }

  /// Envía un nuevo mensaje escribiendo directamente en la subcolección `/chats/{chatId}/messages`.
  ///
  /// @param chatId ID de la sala.
  /// @param senderUid UID de Firebase Authentication del remitente.
  /// @param senderName Nombre visible del emisor.
  /// @param senderRole Rol del remitente ('CLIENT', 'ADMIN', 'SUPERADMIN').
  /// @param text Contenido textual del mensaje.
  /// @param imagePath Ruta de la imagen adjunta en Cloud Storage (opcional).
  /// @return [Result] con el identificador del mensaje generado.
  Future<Result<String>> sendMessage({
    required String chatId,
    required String senderUid,
    required String senderName,
    required String senderRole,
    String? text,
    String? imagePath,
  }) async {
    try {
      final messageRef = _chatsCol.doc(chatId).collection('messages').doc();
      final payload = <String, dynamic>{
        'id': messageRef.id,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'imagePath': imagePath,
        'readByStaff': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await messageRef.set(payload);
      return Ok(messageRef.id);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Elimina un mensaje propio dentro de la conversación.
  ///
  /// @param chatId ID de la sala.
  /// @param messageId ID del mensaje a suprimir.
  Future<Result<void>> deleteOwnMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _chatsCol.doc(chatId).collection('messages').doc(messageId).delete();
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Cambia el estado de archivado de una sala de chat por parte del personal.
  ///
  /// @param chatId ID de la sala.
  /// @param isArchived Estado deseado.
  Future<Result<void>> setArchived({
    required String chatId,
    required bool isArchived,
  }) async {
    try {
      await _chatsCol.doc(chatId).update({
        'isArchived': isArchived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la Cloud Function [markChatAsRead] para reiniciar el contador de mensajes no leídos.
  ///
  /// @param chatId ID de la sala leída.
  Future<Result<void>> markChatAsRead(String chatId) async {
    final res = await _functionsService.markChatAsRead(chatId: chatId);
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }

  /// Invoca la Cloud Function [purgeChatByClient] para vaciar de forma atómica el historial de chat propio.
  ///
  /// @param chatId ID de la conversación a purgar.
  Future<Result<void>> purgeChatByClient(String chatId) async {
    final res = await _functionsService.purgeChatByClient(chatId: chatId);
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }

  /// Invoca la Cloud Function [moderateChat] para acciones disciplinarias de moderación (exclusivo SUPERADMIN).
  ///
  /// @param operation Operación ('BLOCK_CHAT', 'UNBLOCK_CHAT', 'DELETE_MESSAGE').
  /// @param chatId ID de la sala.
  /// @param messageId ID del mensaje a moderar si aplica.
  Future<Result<void>> moderateChat({
    required String operation,
    required String chatId,
    String? messageId,
  }) async {
    final res = await _functionsService.moderateChat(
      operation: operation,
      chatId: chatId,
      messageId: messageId,
    );
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }
}
