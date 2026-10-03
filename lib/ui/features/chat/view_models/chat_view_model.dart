// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/chat/view_models/chat_view_model.dart
// Propósito: ViewModel para la sala de chat bidireccional en tiempo real del cliente,
//            soporte de adjuntos multimedia seguros, moderación y purga de historial.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/models/chat.dart';
import 'package:mipetshop/data/models/chat_message.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';
import 'package:mipetshop/data/services/storage_service.dart';

/// Gestor de estado para la sala de chat del cliente en tiempo real.
///
/// Administra la sincronización reactiva de mensajes, la escucha del estado de moderación
/// de la sala (bloqueo por moderación administrativa), la subida segura de adjuntos mediante
/// intenciones de carga ([upload_intents]), la eliminación de mensajes propios y el vaciado
/// integral de la conversación mediante Cloud Functions.
class ChatViewModel extends ChangeNotifier {
  /// Repositorio de chat para el envío, consulta y purga de mensajes.
  final ChatRepository chatRepository;

  /// Identificador único de la sala de conversación (corresponde usualmente al UID del cliente).
  final String chatId;

  /// Identificador del usuario autenticado que interactúa con la sala.
  final String currentUid;

  /// Nombre del usuario remitente para registro de auditoría en los mensajes.
  final String currentUserName;

  /// Rol del usuario remitente ('CLIENT', 'ADMIN', 'VET', etc.).
  final String currentUserRole;

  /// Instancia de Firestore para la gestión directa de intenciones de carga seguras.
  final FirebaseFirestore firestore;

  /// Servicio de almacenamiento para la subida y descarga de binarios de imágenes.
  final StorageService storageService;

  StreamSubscription<List<ChatMessageDto>>? _messagesSub;
  StreamSubscription<ChatDto?>? _salaSub;

  /// Bytes ya descargados de cada adjunto, indexados por su ruta de Storage.
  ///
  /// La descarga se pide una sola vez por ruta: la lista de mensajes se
  /// reconstruye en cada emisión del flujo y sin memoria cada reconstrucción
  /// volvería a bajar la misma imagen.
  final Map<String, Future<Uint8List?>> _imageBytesCache = {};

  /// Descarga el adjunto evaluando storage.rules mediante Reference.getData().
  Future<Uint8List?> imageBytes(String imagePath) {
    return _imageBytesCache.putIfAbsent(
      imagePath,
      () => storageService.getChatImageBytes(imagePath),
    );
  }

  List<ChatMessageDto> _messages = [];

  /// Lista ordenada cronológicamente de mensajes intercambiados en la sala.
  List<ChatMessageDto> get messages => _messages;

  bool _isLoading = true;

  /// Indica si los mensajes iniciales de la sala están en proceso de carga.
  bool get isLoading => _isLoading;

  bool _isSending = false;

  /// Indica si se está transmitiendo un mensaje de texto al backend.
  bool get isSending => _isSending;

  bool _isPurging = false;

  /// Indica si se está ejecutando la acción de purga/vaciado de la sala.
  bool get isPurging => _isPurging;

  bool _isUploadingImage = false;

  /// Indica si se está ejecutando la subida y procesamiento de una imagen adjunta.
  bool get isUploadingImage => _isUploadingImage;

  /// La sala está bloqueada por moderación (`MC-10` condición 3, `CA-70`).
  ///
  /// Se proyecta desde `/chats/{uid}`, que es la propia sala del cliente y que
  /// la regla ya le deja leer. Mientras valga `true`, el cliente no puede enviar mensajes.
  bool _isBlocked = false;

  /// El bloqueo de moderación es de una sola dirección: al cliente le impide escribir, pero el personal
  /// —administrador y Super Usuario— sigue pudiendo escribirle para explicarle qué ocurre, igual que se
  /// lo permite la regla de seguridad de los mensajes (AUD-420).
  bool get _esPersonal => currentUserRole == 'ADMIN' || currentUserRole == 'SUPERADMIN';

  /// Indica si la sala está bloqueada PARA QUIEN LA USA: sólo el cliente se queda sin poder escribir;
  /// para el personal nunca vale `true`, aunque la sala esté bloqueada (AUD-420).
  bool get isBlocked => _isBlocked && !_esPersonal;

  /// Detalle tipado del último fallo ocurrido en las operaciones de la sala.
  Failure? _failure;

  /// Falla tipada para presentación localizada en la interfaz de usuario.
  Failure? get failure => _failure;

  /// Construye e inicializa el ViewModel del chat con sus dependencias requeridas.
  ChatViewModel({
    required this.chatRepository,
    required this.chatId,
    required this.currentUid,
    required this.currentUserName,
    required this.currentUserRole,
    required this.firestore,
    required this.storageService,
  }) {
    init();
  }

  /// Inicia la sincronización reactiva de los mensajes de la sala y su estado de bloqueo.
  void init() {
    _isLoading = true;
    notifyListeners();

    _messagesSub?.cancel();
    _messagesSub = chatRepository.streamMessages(chatId).listen(
      (items) {
        _messages = items;
        _isLoading = false;
        _failure = null;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _failure = Failure.fromException(e);
        notifyListeners();
      },
    );

    // La sala. El cliente sigue viendo su conversación entera y sigue
    // recibiendo lo que el personal le envíe: lo único que cambia es que
    // puede escribir o no.
    _salaSub?.cancel();
    _salaSub = chatRepository.streamChat(chatId).listen(
      (sala) {
        _isBlocked = sala?.isBlocked ?? false;
        notifyListeners();
      },
      onError: (Object e) {
        // Si la sala no se puede leer, no se inventa un bloqueo: se deja
        // escribir y el servidor decide. Inventarlo sería peor que no saberlo.
        _isBlocked = false;
        notifyListeners();
      },
    );
  }

  /// Envía un mensaje de texto respetando el límite estricto de 4000 caracteres
  /// (CH-02, firestore.rules bloque 8).
  Future<bool> sendTextMessage(String rawText) async {
    // La sala bloqueada no se envía y no se intenta: la regla lo rechazaría, y
    // rechazar en silencio es justo lo que CA-70 prohíbe.
    if (isBlocked) {
      _failure = const DomainFailure(code: 'CHAT_BLOCKED');
      notifyListeners();
      return false;
    }

    final text = rawText.trim();
    if (text.isEmpty) {
      _failure = const DomainFailure(code: 'CHAT_MESSAGE_EMPTY');
      notifyListeners();
      return false;
    }

    if (text.length > 4000) {
      _failure = const DomainFailure(code: 'CHAT_MESSAGE_TOO_LONG');
      notifyListeners();
      return false;
    }

    _isSending = true;
    _failure = null;
    notifyListeners();

    final result = await chatRepository.sendMessage(
      chatId: chatId,
      senderUid: currentUid,
      senderName: currentUserName,
      senderRole: currentUserRole,
      text: text,
    );

    _isSending = false;
    return result.when(
      ok: (_) {
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Adjunta una imagen mediante la tubería segura de upload_intents (CH-03, TRD §3.5.A, §3.5.B).
  ///
  /// Crea la intención con `purpose: CHAT_IMAGE` y `targetId: chatId`,
  /// sube el binario a Storage y escribe el mensaje en Firestore con el `resultPath`.
  Future<bool> sendImage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (isBlocked) {
      _failure = const DomainFailure(code: 'CHAT_BLOCKED');
      notifyListeners();
      return false;
    }

    _isUploadingImage = true;
    _failure = null;
    notifyListeners();

    try {
      final intentId = firestore.collection('upload_intents').doc().id;
      final intentRef = firestore.collection('upload_intents').doc(intentId);

      final now = BusinessClock.now();
      final expiresAt = Timestamp.fromDate(now.add(const Duration(hours: 1)));

      await intentRef.set({
        'id': intentId,
        'ownerUid': currentUid,
        'purpose': 'CHAT_IMAGE',
        'targetId': chatId,
        'status': 'PENDING',
        'rejectionCode': null,
        'resultPath': null,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });

      // Subir archivo al bucket oficial
      final uploadTask = storageService.uploadToUploads(
        userId: currentUid,
        intentId: intentId,
        fileName: fileName,
        data: bytes,
        metadata: SettableMetadata(contentType: mimeType),
      );

      await uploadTask;

      // Ruta canónica según regla de seguridad de chat: media/chat/{chatId}/{fileNameOrIntent}
      final canonicalPath = 'media/chat/$chatId/$intentId.webp';
      String? resultPath;

      // Esperar reactivamente a que el backend procese la imagen (TRD §3.5.A, CA-12)
      for (var i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        try {
          final doc = await intentRef.get();
          final status = doc.data()?['status'] as String?;
          if (status == 'PROCESSED') {
            resultPath = doc.data()?['resultPath'] as String? ?? canonicalPath;
            break;
          } else if (status == 'REJECTED') {
            _isUploadingImage = false;
            _failure = const DomainFailure(code: 'PIPELINE_FAILURE');
            notifyListeners();
            return false;
          }
        } catch (_) {}
      }
      resultPath ??= canonicalPath;

      final sendResult = await chatRepository.sendMessage(
        chatId: chatId,
        senderUid: currentUid,
        senderName: currentUserName,
        senderRole: currentUserRole,
        text: null,
        imagePath: resultPath,
      );

      _isUploadingImage = false;
      return sendResult.when(
        ok: (_) {
          notifyListeners();
          return true;
        },
        err: (failure) {
          _failure = failure;
          notifyListeners();
          return false;
        },
      );
    } catch (e) {
      _isUploadingImage = false;
      _failure = Failure.fromException(e);
      notifyListeners();
      return false;
    }
  }

  /// Borra un mensaje propio de la sala sin dejar texto sustitutorio (CH-06, TRD §4.4 bloque 8).
  Future<bool> deleteMessage(String messageId) async {
    final result = await chatRepository.deleteOwnMessage(
      chatId: chatId,
      messageId: messageId,
    );

    return result.when(
      ok: (_) {
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Vacía la conversación propia mediante la callable purgeChatByClient (CH-05, TRD §3.4.D).
  Future<bool> purgeConversation() async {
    _isPurging = true;
    _failure = null;
    notifyListeners();

    final result = await chatRepository.purgeChatByClient(chatId);

    _isPurging = false;
    return result.when(
      ok: (_) {
        _messages = [];
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Libera suscripciones reactivas a los mensajes y al estado de la sala.
  @override
  void dispose() {
    _messagesSub?.cancel();
    _salaSub?.cancel();
    super.dispose();
  }
}
