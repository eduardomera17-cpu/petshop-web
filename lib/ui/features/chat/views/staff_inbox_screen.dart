// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/chat/views/staff_inbox_screen.dart
// Propósito: Interfaz unificada de bandeja de mensajería para el personal administrativo con vista maestro-detalle, canal interno y controles de moderación.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/models/chat.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/chat/view_models/chat_view_model.dart';
import 'package:mipetshop/ui/features/chat/view_models/staff_inbox_view_model.dart';
import 'package:mipetshop/ui/features/chat/views/chat_screen.dart';
import 'package:provider/provider.dart';

/// Pantalla principal de gestión de mensajería para el equipo de trabajo (Staff, Vet y Admin).
///
/// Implementa un patrón responsivo Maestro-Detalle ([ResponsiveLayout]):
/// - En pantallas anchas (Desktop / Web extendido), divide el espacio en una lista lateral
///   de salas activas/archivadas y un panel derecho con el hilo de conversación activo.
/// - En pantallas compactas (Mobile / Tablet), transiciona limpiamente entre la lista de canales
///   y la vista individual de mensajes con botón de retroceso.
/// - Segmenta inequívocamente el canal interno confidencial del personal (`STAFF_INTERNAL`)
///   de las conversaciones individuales con los clientes.
/// - Facilita herramientas de moderación (bloqueo/desbloqueo) reservadas a administradores con privilegios de `SUPERADMIN`.
class StaffInboxScreen extends StatefulWidget {
  /// Modelo de vista reactivo gestor de la sincronización de salas y estados de moderación.
  final StaffInboxViewModel viewModel;

  /// Constructor de la pantalla de bandeja de entrada para el personal.
  const StaffInboxScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<StaffInboxScreen> createState() => _StaffInboxScreenState();
}

/// Estado interactivo de [StaffInboxScreen] que administra la selección de sala y el ciclo de vida del [ChatViewModel] activo.
class _StaffInboxScreenState extends State<StaffInboxScreen> {
  /// Modelo de vista reactivo correspondiente a la conversación individual actualmente seleccionada.
  ChatViewModel? _activeChatVm;


  void _onChatSelected(ChatDto chat) {
    widget.viewModel.selectChat(chat);
    _activeChatVm?.dispose();
    final firestore = Provider.of<FirebaseFirestore?>(context, listen: false) ??
        widget.viewModel.chatRepository.firestore;
    final storageService = Provider.of<StorageService?>(context, listen: false) ??
        StorageService();
    _activeChatVm = ChatViewModel(
      chatRepository: widget.viewModel.chatRepository,
      chatId: chat.id ?? '',
      currentUid: widget.viewModel.currentStaffUid,
      currentUserName: widget.viewModel.currentStaffName,
      currentUserRole: widget.viewModel.currentStaffRole,
      firestore: firestore,
      storageService: storageService,
    );
  }

  @override
  void dispose() {
    _activeChatVm?.dispose();
    super.dispose();
  }

  void _showModerationOptions(BuildContext context, ChatDto chat) {
    final l10n = AppLocalizations.of(context);
    const unblockTitle = 'Desbloquear conversación';
    const unblockSubtitle = 'Permite que el usuario vuelva a enviar mensajes.';
    const blockTitle = 'Bloquear conversación';
    const blockSubtitle = 'Impide que el usuario siga enviando mensajes.';
    final roomSubtitle = 'Sala: ${chat.id}';

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.security, color: Colors.indigo),
              title: Text(
                l10n?.staffInboxModerationControlsTitle ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(roomSubtitle),
            ),
            const Divider(),
            if (chat.isBlocked)
              ListTile(
                key: const Key('moderate_unblock_chat_btn'),
                leading: const Icon(Icons.lock_open, color: Colors.green),
                title: const Text(unblockTitle),
                subtitle: const Text(unblockSubtitle),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await widget.viewModel.moderateUnblockChat(chat.id ?? '');
                },
              )
            else
              ListTile(
                key: const Key('moderate_block_chat_btn'),
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text(blockTitle),
                subtitle: const Text(blockSubtitle),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await widget.viewModel.moderateBlockChat(chat.id ?? '');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ResponsiveLayout(
      builder: (context, breakpoint) {
        final isMasterDetail = breakpoint.isExpanded;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              vm.selectedChat != null && !isMasterDetail
                  ? (vm.selectedChat!.id == 'STAFF_INTERNAL'
                      ? 'CANAL INTERNO'
                      : 'Chat: ${vm.selectedChat!.clientName ?? vm.selectedChat!.id}')
                  : 'Bandeja de Mensajería',
            ),
            leading: vm.selectedChat != null && !isMasterDetail
                ? IconButton(
                    key: const Key('inbox_back_btn'),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: vm.clearSelectedChat,
                  )
                : null,
            actions: [
              // Filtro de archivadas
              Builder(builder: (context) {
                final filterTooltip = vm.showArchived ? 'Ver activas' : 'Ver archivadas';
                const filterSemantics = 'Alternar filtro de archivadas';
                return TappableArea(
                  key: const Key('toggle_archived_filter_btn'),
                  tooltip: filterTooltip,
                  semanticLabel: filterSemantics,
                  minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onTap: vm.toggleShowArchived,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vm.showArchived ? Icons.unarchive : Icons.archive,
                          color: vm.showArchived ? Colors.amber : Colors.white,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          vm.showArchived ? 'Archivadas' : 'Activas',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          body: AnimatedBuilder(
            animation: vm,
            builder: (context, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (isMasterDetail) {
                return Row(
                  children: [
                    SizedBox(
                      width: 380,
                      child: _buildRoomsList(context, vm),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: vm.selectedChat != null && _activeChatVm != null
                          ? _buildDetailPane(context, vm, vm.selectedChat!)
                          : Center(
                              child: Text(
                                AppLocalizations.of(context)?.staffInboxSelectConversationPrompt ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ],
                );
              }

              // Vista móvil / tablet (768 px)
              if (vm.selectedChat != null && _activeChatVm != null) {
                return _buildDetailPane(context, vm, vm.selectedChat!);
              }

              return _buildRoomsList(context, vm);
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomsList(BuildContext context, StaffInboxViewModel vm) {
    return StreamBuilder<List<ChatDto>>(
      stream: vm.chatRepository.streamStaffChats(includeArchived: vm.showArchived),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('>>> [StaffInboxScreen stream error]: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Text(
              vm.showArchived
                  ? 'No hay conversaciones archivadas.'
                  : 'No hay conversaciones activas.',
            ),
          );
        }

        // Separación explícita del canal interno (STAFF_INTERNAL)
        final internalChat =
            chats.cast<ChatDto?>().firstWhere((c) => c?.id == 'STAFF_INTERNAL', orElse: () => null);
        final clientChats = chats.where((c) => c.id != 'STAFF_INTERNAL').toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            // SEPARACIÓN INEQUÍVOCA DEL CANAL INTERNO (STAFF_INTERNAL)
            if (internalChat != null) ...[
              Card(
                key: const Key('staff_internal_section'),
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                color: Colors.purple.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(color: Colors.purple.shade300, width: 1.5),
                ),
                child: _buildChatTile(
                  context: context,
                  chat: internalChat,
                  isInternal: true,
                  isSelected: vm.selectedChat?.id == 'STAFF_INTERNAL',
                  vm: vm,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  AppLocalizations.of(context)?.staffInboxClientConversationsHeader ?? '',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            // SALAS DE CLIENTES
            ...clientChats.map((chat) {
              return _buildChatTile(
                context: context,
                chat: chat,
                isInternal: false,
                isSelected: vm.selectedChat?.id == chat.id,
                vm: vm,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required ChatDto chat,
    required bool isInternal,
    required bool isSelected,
    required StaffInboxViewModel vm,
  }) {
    final title = isInternal
        ? 'CANAL INTERNO DEL PERSONAL'
        : (chat.clientName ?? 'Cliente (${chat.id})');
    final subtitle = chat.lastMessageText ?? 'Sin mensajes recientes';
    final hasUnread = chat.staffUnreadCount > 0;

    return ListTile(
      key: Key('chat_tile_${chat.id}'),
      selected: isSelected,
      leading: CircleAvatar(
        backgroundColor: isInternal ? Colors.purple.shade800 : Colors.blue.shade700,
        child: Icon(
          isInternal ? Icons.lock_person : Icons.person,
          color: Colors.white,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                color: isInternal ? Colors.purple.shade900 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              key: Key('unread_badge_${chat.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${chat.staffUnreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Acción de archivar / desarchivar
          IconButton(
            key: Key('archive_btn_${chat.id}'),
            icon: Icon(
              chat.isArchived ? Icons.unarchive : Icons.archive,
              size: 20.0,
            ),
            tooltip: chat.isArchived ? 'Desarchivar sala' : 'Archivar sala',
            onPressed: () => vm.setArchived(chat.id ?? '', !chat.isArchived),
          ),
          // Acción de marcar leída
          if (hasUnread)
            Builder(builder: (context) {
              const markReadTip = 'Marcar como leída';
              return IconButton(
                key: Key('mark_read_btn_${chat.id}'),
                icon: const Icon(Icons.done_all, size: 20.0, color: Colors.green),
                tooltip: markReadTip,
                onPressed: () => vm.markAsRead(chat.id ?? ''),
              );
            }),
        ],
      ),
      onTap: () => _onChatSelected(chat),
    );
  }

  Widget _buildDetailPane(
    BuildContext context,
    StaffInboxViewModel vm,
    ChatDto chat,
  ) {
    return Column(
      children: [
        // Barra de encabezado del chat seleccionado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.id == 'STAFF_INTERNAL'
                          ? (AppLocalizations.of(context)?.staffInboxInternalChannelTitle ?? '')
                          : (AppLocalizations.of(context)?.staffInboxClientLabel(chat.clientName ?? chat.id ?? '') ?? ''),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                    ),
                    if (chat.isBlocked)
                      Text(
                        AppLocalizations.of(context)?.staffInboxConversationBlockedNotice ?? '',
                        style: const TextStyle(fontSize: 12.0, color: Colors.red),
                      ),
                    if (chat.isArchived)
                      Text(
                        AppLocalizations.of(context)?.staffInboxConversationArchivedNotice ?? '',
                        style: const TextStyle(fontSize: 12.0, color: Colors.orange),
                      ),
                  ],
                ),
              ),
              // CONTROLES DE MODERACIÓN: VISIBLES EXCLUSIVAMENTE PARA SUPERADMIN
              if (vm.isSuperAdmin) ...[
                Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  const modTip = 'Opciones de Moderación (Super Usuario)';
                  const modSemantics = 'Opciones de moderación';
                  return TappableArea(
                    key: const Key('superadmin_moderation_btn'),
                    tooltip: modTip,
                    semanticLabel: modSemantics,
                    minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                    onTap: () => _showModerationOptions(context, chat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield, color: Colors.red, size: 20.0),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n?.staffInboxModerateButtonLabel ?? '',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        // Cuerpo con los mensajes
        Expanded(
          child: _activeChatVm != null
              ? ChatScreen(viewModel: _activeChatVm!)
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
