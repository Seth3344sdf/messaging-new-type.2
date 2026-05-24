import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/avatar.dart';
import '../widgets/composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/presence_dot.dart';
import 'memory_sheet.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scroll = ScrollController();
  Message? _replyTo;
  Set<String> _typingUserIds = const {};
  StreamSubscription<Set<String>>? _typingSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      final convo = app.conversations.firstWhere(
        (c) => c.id == widget.conversationId,
        orElse: () => app.conversations.first,
      );
      if (convo.unread >= 3) {
        _autoSummary(app, convo);
      }
      app.markRead(widget.conversationId);
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());

      final backend = context.read<Backend?>();
      if (backend != null) {
        _typingSub = backend
            .subscribeTyping(widget.conversationId)
            .listen((ids) => setState(() => _typingUserIds = ids));
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _typingSub?.cancel();
    super.dispose();
  }

  void _autoSummary(AppState app, Conversation convo) {
    // Pull the most recent unread messages (from other people, non-AI) and
    // hand them to Pulse. In production this would be a model call.
    final recent = <Message>[];
    for (final m in convo.messages.reversed) {
      if (m.authorId == app.me.id || m.isAi) continue;
      recent.add(m);
      if (recent.length >= 6) break;
    }
    if (recent.isEmpty) return;
    final summary = StringBuffer('You missed ${convo.unread} messages. ');
    final bullets = recent.reversed.take(3).map((m) {
      final name =
          app.userById(m.authorId).name.split(' ').first;
      final body =
          m.text.length > 80 ? '${m.text.substring(0, 80)}…' : m.text;
      return '• $name: $body';
    }).join('\n');
    summary.write('Here is the gist:\n$bullets');
    convo.messages.add(Message(
      id: 'm_pulse_${DateTime.now().microsecondsSinceEpoch}',
      authorId: app.pulse.id,
      text: summary.toString(),
      sentAt: DateTime.now(),
      isAi: true,
    ));
    app.notifyListenersPublic();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _animateToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _catchUp(Conversation convo) {
    final app = context.read<AppState>();
    // Take the last few messages, draft a fake Pulse summary, and append it
    // as a Pulse message. A real implementation would call the AI here.
    final recent = convo.messages.reversed.take(8).toList().reversed.toList();
    final highlights = recent
        .where((m) => !m.isAi && m.text.length < 90)
        .map((m) {
      final who = m.authorId == app.me.id ? 'you' : app.userById(m.authorId).name;
      return '$who: ${m.text}';
    }).take(4).join('\n');
    final body = highlights.isEmpty
        ? 'nothing important — just hellos and emoji.'
        : 'quick catch up:\n$highlights';
    convo.messages.add(Message(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      authorId: app.pulse.id,
      text: body,
      sentAt: DateTime.now(),
      isAi: true,
    ));
    app.notifyListenersPublic();
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateToBottom());
  }

  void _openMemory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemorySheet(conversationId: widget.conversationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final convo = app.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => app.conversations.first,
    );

    final otherId = convo.participantIds.firstWhere(
      (id) => id != app.me.id && id != app.pulse.id,
      orElse: () => app.pulse.id,
    );
    final other = app.userById(otherId);
    final title = convo.isGroup ? (convo.groupName ?? 'group') : other.name;
    final avatarId = convo.isGroup
        ? (convo.groupAvatarId ?? other.avatarId)
        : other.avatarId;

    String subtitle;
    if (_typingUserIds.isNotEmpty) {
      final names = _typingUserIds
          .take(2)
          .map((id) => app.userById(id).name.split(' ').first)
          .join(', ');
      subtitle = _typingUserIds.length == 1
          ? '$names is typing…'
          : '$names are typing…';
    } else if (convo.isGroup) {
      subtitle =
          '${convo.participantIds.where((id) => id != app.pulse.id).length} people · pulse is here';
    } else {
      subtitle = other.presence == Presence.online
          ? 'online'
          : (other.status ?? '');
    }

    final pinnedCount = convo.messages.where((m) => m.pinned).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarView(avatarId: avatarId, size: 34),
                if (!convo.isGroup && other.presence != Presence.offline)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: PresenceDot(presence: other.presence, size: 11),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Memory',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  pinnedCount > 0
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: pinnedCount > 0 ? AppPalette.decision : null,
                ),
                if (pinnedCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppPalette.decision,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$pinnedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openMemory,
          ),
          IconButton(
            tooltip: 'info',
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              itemCount: convo.messages.length,
              itemBuilder: (context, i) {
                final m = convo.messages[i];
                final prev = i > 0 ? convo.messages[i - 1] : null;
                final showTimeGap = prev == null ||
                    m.sentAt.difference(prev.sentAt).inMinutes >= 10;

                final fromMe = m.authorId == app.me.id;
                final author = app.userById(m.authorId);
                final isLastOutgoing = fromMe &&
                    convo.messages.lastIndexWhere(
                            (x) => x.authorId == app.me.id) ==
                        i;

                return Column(
                  crossAxisAlignment: fromMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (showTimeGap)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            _stamp(m.sentAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppPalette.inkLight,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: MessageBubble(
                        message: m,
                        fromMe: fromMe,
                        authorName:
                            convo.isGroup && !fromMe ? author.name : null,
                        authorAvatarId:
                            convo.isGroup ? author.avatarId : null,
                        showAvatar: convo.isGroup,
                        showRead: app.readReceipts &&
                            isLastOutgoing &&
                            !convo.isGroup,
                        onReact: (r) =>
                            context.read<AppState>().toggleReaction(m, r),
                        onTogglePin: () =>
                            context.read<AppState>().togglePin(m),
                        onReply: () => setState(() => _replyTo = m),
                        replyPreview: m.replyToId == null
                            ? null
                            : _replyQuote(context, convo, m, fromMe),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_replyTo != null) _replyComposerHeader(context, convo),
          Composer(
            onSend: (text) {
              _handleSend(context, convo, text);
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _animateToBottom());
            },
            onSlashCommand: (cmd) => _handleSlash(context, convo, cmd),
            onAttach: (kind) => _handleAttach(context, convo, kind),
            onTyping: () {
              final backend = context.read<Backend?>();
              if (backend != null) {
                unawaited(backend.broadcastTyping(convo.id));
              }
            },
            hint: convo.isGroup
                ? 'message ${convo.groupName ?? "group"}'
                : 'message $title',
          ),
        ],
      ),
    );
  }

  Future<void> _handleAttach(
      BuildContext context, Conversation convo, AttachmentKind kind) async {
    final app = context.read<AppState>();
    final backend = context.read<Backend?>();
    String preview;
    switch (kind) {
      case AttachmentKind.photo:
      case AttachmentKind.camera:
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
          source: kind == AttachmentKind.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        if (backend != null) {
          try {
            final url = await backend.uploadAttachment(
              bytes,
              conversationId: convo.id,
              filename: picked.name,
              mimeType: picked.mimeType ?? 'image/jpeg',
            );
            preview = '📷 Sent a photo\n$url';
          } catch (e) {
            preview = '📷 (failed to upload) ${picked.name}';
          }
        } else {
          preview = '📷 Sent a photo · ${picked.name}';
        }
        break;
      case AttachmentKind.file:
        final result = await FilePicker.pickFiles(withData: true);
        if (result == null || result.files.isEmpty) return;
        final f = result.files.single;
        if (backend != null && f.bytes != null) {
          try {
            final url = await backend.uploadAttachment(
              f.bytes!,
              conversationId: convo.id,
              filename: f.name,
              mimeType: 'application/octet-stream',
            );
            preview = '📄 ${f.name} · ${_formatBytes(f.size)}\n$url';
          } catch (e) {
            preview = '📄 (failed to upload) ${f.name}';
          }
        } else {
          preview = '📄 ${f.name} · ${_formatBytes(f.size)}';
        }
        break;
      case AttachmentKind.location:
        preview = '📍 Shared a location · current spot';
        break;
      case AttachmentKind.poll:
        preview = '🗳 Started a poll · "thai or pizza?"';
        break;
      case AttachmentKind.voice:
        preview = '🎙 Sent a voice note';
        break;
    }
    await app.sendMessage(convo.id, preview);
    if (!mounted) return;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _animateToBottom());
  }

  String _formatBytes(int n) {
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _handleSend(BuildContext context, Conversation convo, String text) {
    final app = context.read<AppState>();
    if (text.trim().startsWith('/')) {
      _handleSlash(context, convo, text.trim());
      return;
    }
    final replyId = _replyTo?.id;
    app.sendMessage(convo.id, text, replyToId: replyId);
    if (_replyTo != null) setState(() => _replyTo = null);
  }

  Widget _replyComposerHeader(BuildContext context, Conversation convo) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final m = _replyTo!;
    final author = app.userById(m.authorId);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: m.authorId == app.me.id
                  ? AppPalette.ink
                  : AppPalette.hueForMember(m.authorId),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${m.authorId == app.me.id ? "yourself" : author.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  m.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            iconSize: 16,
            color: AppPalette.inkLight,
            tooltip: 'cancel reply',
            onPressed: () => setState(() => _replyTo = null),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _replyQuote(
    BuildContext context,
    Conversation convo,
    Message m,
    bool fromMe,
  ) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    final original = app.messageById(convo.id, m.replyToId!);
    if (original == null) return const SizedBox.shrink();
    final author = app.userById(original.authorId);
    final selfText = Colors.white;
    final inkColor =
        Theme.of(context).brightness == Brightness.dark
            ? AppPalette.inkOnDark
            : AppPalette.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: fromMe
            ? Colors.white.withValues(alpha: 0.12)
            : (theme.brightness == Brightness.dark
                ? AppPalette.hairlineDark
                : AppPalette.hairline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: fromMe
                ? Colors.white.withValues(alpha: 0.55)
                : AppPalette.hueForMember(original.authorId),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            author.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fromMe
                  ? selfText.withValues(alpha: 0.85)
                  : AppPalette.hueForMember(original.authorId),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            original.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fromMe
                  ? selfText.withValues(alpha: 0.85)
                  : inkColor.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSlash(BuildContext context, Conversation convo, String cmd) {
    final app = context.read<AppState>();
    final lower = cmd.trim().toLowerCase();
    String reply;
    if (lower.startsWith('/summarize') || lower.startsWith('/catchup')) {
      _catchUp(convo);
      return;
    } else if (lower.startsWith('/find')) {
      final q = cmd.trim().substring('/find'.length).trim();
      reply = q.isEmpty
          ? 'tell me what to look for, e.g. "/find rollback plan".'
          : 'searching for "$q"… (real search would surface matching messages and pages here).';
    } else if (lower.startsWith('/remind')) {
      final body = cmd.trim().substring('/remind'.length).trim();
      reply = body.isEmpty
          ? 'tell me what to remind you about, e.g. "/remind me to deploy at 5pm".'
          : 'reminder set: $body';
    } else if (lower.startsWith('/decide')) {
      final body = cmd.trim().substring('/decide'.length).trim();
      if (body.isEmpty) {
        reply = 'tell me the decision, e.g. "/decide we ship on friday".';
      } else {
        final m = Message(
          id: 'm_${DateTime.now().microsecondsSinceEpoch}',
          authorId: app.me.id,
          text: body,
          sentAt: DateTime.now(),
          pinned: true,
        );
        convo.messages.add(m);
        app.notifyListenersPublic();
        WidgetsBinding.instance.addPostFrameCallback((_) => _animateToBottom());
        return;
      }
    } else {
      reply = 'try /summarize, /find …, /remind …, or /decide …';
    }
    convo.messages.add(Message(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      authorId: app.pulse.id,
      text: reply,
      sentAt: DateTime.now(),
      isAi: true,
    ));
    app.notifyListenersPublic();
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateToBottom());
  }

  String _stamp(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (diff == 0) return 'today · $hh:$mm';
    if (diff == 1) return 'yesterday · $hh:$mm';
    return '${t.month}/${t.day} · $hh:$mm';
  }
}
