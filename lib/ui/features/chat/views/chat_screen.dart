// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/chat/views/chat_screen.dart
// Propósito: Pantalla interactiva de mensajería bidireccional en tiempo real con soporte multimedia para clientes y personal del petshop.
// =========================================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mipetshop/core/services/web_file_picker.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/models/chat_message.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/chat/view_models/chat_view_model.dart';

/// Interfaz interactiva de conversación en tiempo real mediante Firestore y Cloud Storage.
///
/// Implementa los flujos de comunicación cliente-personal y canal interno de colaboradores:
/// - Despliegue cronológico de mensajes en burbujas diferenciadas por remitente (propio vs. interlocutor).
/// - Transmisión de mensajes de texto y adjuntos de imagen previsualizables con visor interactivo a escala completa.
/// - Control automático de desplazamiento vertical con fijación en el último mensaje emitido o recibido.
/// - Soporte de estados de conversación bloqueada por moderación, deshabilitando la barra de entrada.
/// - Formato tipográfico temporal localizado con fecha y hora de emisión.
class ChatScreen extends StatefulWidget {
  /// Modelo de vista reactivo gestor de la persistencia y flujo de mensajería.
  final ChatViewModel viewModel;

  /// Constructor de la pantalla de chat.
  const ChatScreen({super.key, required this.viewModel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    final success = await widget.viewModel.sendTextMessage(text);
    if (success) {
      _textController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _handleAttachImage() async {
    final l10n = AppLocalizations.of(context);
    final pickResult = await pickPlatformFile();

    if (!mounted) return;

    switch (pickResult.status) {
      case FilePickStatus.cancelled:
        return;
      case FilePickStatus.unsupportedFormat:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.imageFormatUnsupported ?? '',
            ),
          ),
        );
        return;
      case FilePickStatus.rejectedHeic:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.imageFormatHeicRejected ?? '',
            ),
          ),
        );
        return;
      case FilePickStatus.sizeExceeded:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.imageSizeExceeded ?? '',
            ),
          ),
        );
        return;
      case FilePickStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pickResult.errorMessage ?? (l10n?.errorGeneric ?? ''),
            ),
          ),
        );
        return;
      case FilePickStatus.success:
        final file = pickResult.file!;
        final success = await widget.viewModel.sendImage(
          bytes: file.bytes,
          fileName: file.name,
          mimeType: file.mimeType,
        );
        if (success) {
          _scrollToBottom();
        }
        return;
    }
  }

  void _confirmDeleteMessage(ChatMessageDto message) {
    if (message.id == null) return;

    final l10n = AppLocalizations.of(context);
    final delTitle = l10n?.chatDeleteMessageTitle ?? '';
    final delCancel = l10n?.cancel ?? '';
    final delConfirm = l10n?.chatDeleteMessageConfirm ?? '';
    final delBody = l10n?.chatDeleteMessageBody ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delTitle),
        content: Text(delBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(delCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.viewModel.deleteMessage(message.id!);
            },
            child: Text(delConfirm),
          ),
        ],
      ),
    );
  }

  void _confirmPurgeConversation() {
    final l10n = AppLocalizations.of(context);
    final purgeTitle = l10n?.chatPurgeTitle ?? '';
    final purgeCancel = l10n?.cancel ?? '';
    final purgeConfirm = l10n?.chatPurgeConfirm ?? '';
    final purgeBody = l10n?.chatPurgeBody ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(purgeTitle),
        content: Text(purgeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(purgeCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.viewModel.purgeConversation();
            },
            child: Text(purgeConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatTitle = l10n?.chatScreenTitle ?? '';
    final purgeTooltip = l10n?.chatPurgeAction ?? '';

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(chatTitle),
            actions: [
              TappableArea(
                key: const Key('purge_chat_button'),
                tooltip: purgeTooltip,
                semanticLabel: purgeTooltip,
                minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                onTap: _confirmPurgeConversation,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.delete_sweep, color: Colors.redAccent),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800.0),
                    child: Column(
                      children: [
                        if (widget.viewModel.failure != null && l10n != null)
                          Container(
                            width: double.infinity,
                            color: Colors.red.shade100,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    widget.viewModel.failure!.toLocalizedMessage(l10n),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: widget.viewModel.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : widget.viewModel.messages.isEmpty
                                  ? Center(
                                      child: Text(
                                        l10n?.chatEmptyConversation ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                                      itemCount: widget.viewModel.messages.length,
                                      itemBuilder: (context, index) {
                                        final msg = widget.viewModel.messages[index];
                                        final isMe = msg.senderUid == widget.viewModel.currentUid;
                                        return _buildMessageBubble(msg, isMe);
                                      },
                                    ),
                        ),
                        if (widget.viewModel.isBlocked && l10n != null)
                          Container(
                            key: const Key('chat_blocked_notice'),
                            width: double.infinity,
                            color: Colors.orange.shade100,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.block, color: Colors.orange.shade900),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    l10n.chatBlockedNotice,
                                    style: TextStyle(color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildInputBar(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageDto msg, bool isMe) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final timeStr = msg.createdAt != null ? DateFormat('HH:mm').format(msg.createdAt!) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe && msg.id != null)
            Builder(builder: (context) {
              final delMsgTooltip = l10n?.chatDeleteMessageTitle ?? '';
              final delMsgSemantics = l10n?.chatDeleteOwnMessageSemantics ?? '';
              return TappableArea(
                key: Key('delete_msg_${msg.id}'),
                tooltip: delMsgTooltip,
                semanticLabel: delMsgSemantics,
                minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                onTap: () => _confirmDeleteMessage(msg),
                child: const Icon(Icons.delete_outline, size: 20.0, color: Colors.grey),
              );
            }),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMe ? theme.colorScheme.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isMe ? 16.0 : 2.0),
                  bottomRight: Radius.circular(isMe ? 2.0 : 16.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        msg.senderName,
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    ),
                  if (msg.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: _ChatImageAttachment(
                        key: ValueKey('chat_image_${msg.imagePath}'),
                        imagePath: msg.imagePath!,
                        viewModel: widget.viewModel,
                        isMe: isMe,
                      ),
                    ),
                  if (msg.text != null && msg.text!.isNotEmpty)
                    Text(
                      msg.text!,
                      style: TextStyle(
                        fontSize: 15.0,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 4.0),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11.0,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context);
    final bloqueada = widget.viewModel.isBlocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -1),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            final attachTip = l10n?.chatAttachImageAction ?? '';
            return TappableArea(
              key: const Key('chat_attach_button'),
              tooltip: attachTip,
              semanticLabel: attachTip,
              enabled: !bloqueada,
              minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              onTap: (widget.viewModel.isUploadingImage || bloqueada) ? null : _handleAttachImage,
              child: widget.viewModel.isUploadingImage
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Icon(Icons.attach_file, color: Colors.blueGrey),
            );
          }),
          const SizedBox(width: 6.0),
          Expanded(
            child: Builder(builder: (context) {
              final msgPlaceholder = bloqueada
                  ? (l10n?.chatBlockedHint ?? '')
                  : (l10n?.chatMessagePlaceholder ?? '');
              return TextField(
                key: const Key('chat_text_field'),
                controller: _textController,
                // Deshabilitado, no sólo rechazado: CA-70 exige que el cliente
                // no llegue a pulsar enviar.
                enabled: !bloqueada,
                maxLength: 4000,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: msgPlaceholder,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24.0)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  counterText: '',
                ),
                onSubmitted: (_) => _handleSendMessage(),
              );
            }),
          ),
          const SizedBox(width: 6.0),
          Builder(builder: (context) {
            final sendTip = l10n?.chatSendMessageAction ?? '';
            return TappableArea(
              key: const Key('chat_send_button'),
              tooltip: sendTip,
              semanticLabel: sendTip,
              enabled: !bloqueada,
              minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              onTap: (widget.viewModel.isSending || bloqueada) ? null : _handleSendMessage,
              child: widget.viewModel.isSending
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : Icon(Icons.send, color: bloqueada ? Colors.grey : Colors.blue),
            );
          }),
        ],
      ),
    );
  }
}

/// Adjunto de imagen de una conversación.
///
/// El mensaje mostraba un rótulo fijo «Imagen adjunta» y no bajaba nada, de modo
/// que ni el cliente ni el personal podían ver lo que se había enviado. La
/// descarga se hace con Reference.getData() a través del ViewModel, que evalúa
/// storage.rules y memoriza los bytes; getDownloadURL() está prohibido.
class _ChatImageAttachment extends StatefulWidget {
  final String imagePath;
  final ChatViewModel viewModel;
  final bool isMe;

  const _ChatImageAttachment({
    super.key,
    required this.imagePath,
    required this.viewModel,
    required this.isMe,
  });

  @override
  State<_ChatImageAttachment> createState() => _ChatImageAttachmentState();
}

class _ChatImageAttachmentState extends State<_ChatImageAttachment> {
  late Future<Uint8List?> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.viewModel.imageBytes(widget.imagePath);
  }

  void _openFullScreen(Uint8List bytes, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          key: const Key('chat_image_viewer_dialog'),
          insetPadding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    key: const Key('chat_image_viewer_close'),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(l10n?.close ?? ''),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _frame({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240.0, maxHeight: 240.0),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white24 : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _frame(
            child: const SizedBox(
              width: 120.0,
              height: 120.0,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null || bytes.isEmpty) {
          return _frame(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined, color: Colors.black54),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      l10n?.chatImageLoadError ?? '',
                      style: const TextStyle(fontSize: 12.0, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return TappableArea(
          key: Key('chat_image_open_${widget.imagePath}'),
          tooltip: l10n?.chatImageOpenAction ?? '',
          semanticLabel: l10n?.chatImageAttachmentLabel ?? '',
          onTap: () => _openFullScreen(bytes, l10n),
          child: _frame(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  l10n?.chatImageLoadError ?? '',
                  style: const TextStyle(fontSize: 12.0, color: Colors.black54),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
