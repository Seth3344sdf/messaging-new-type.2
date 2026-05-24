import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import '../widgets/message_text.dart';
import 'chat_detail_screen.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  static Future<void> open(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'command palette',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const CommandPalette(),
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final q = _ctrl.text.trim().toLowerCase();

    final results = _runQuery(app, q);

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? AppPalette.surfaceDark : AppPalette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dark
                          ? AppPalette.hairlineDark
                          : AppPalette.hairline,
                    ),
                    boxShadow: AppPalette.softShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _searchField(context),
                      Divider(
                        height: 1,
                        color: dark
                            ? AppPalette.hairlineDark
                            : AppPalette.hairline,
                      ),
                      Flexible(
                        child: results.isEmpty
                            ? _emptyState(context)
                            : ListView.builder(
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: results.length,
                                itemBuilder: (context, i) {
                                  return _buildResult(context, results[i]);
                                },
                              ),
                      ),
                      _footer(context),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 160.ms)
              .slideY(begin: -0.02, end: 0, duration: 200.ms),
        ),
      ],
    );
  }

  Widget _searchField(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppPalette.inkLight),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'search people, chats, messages',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.inkLight,
                ),
              ),
              style: theme.textTheme.bodyLarge,
              onSubmitted: (_) {
                // Submitting picks the first result if any.
                final results = _runQuery(
                    context.read<AppState>(), _ctrl.text.trim().toLowerCase());
                if (results.isNotEmpty) _activate(context, results.first);
              },
            ),
          ),
          IconButton(
            iconSize: 18,
            color: AppPalette.inkLight,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'close',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
      ),
      child: Row(
        children: [
          _kbd('↩'),
          const SizedBox(width: 6),
          Text(' open', style: TextStyle(color: AppPalette.inkLight, fontSize: 12)),
          const SizedBox(width: 14),
          _kbd('esc'),
          const SizedBox(width: 6),
          Text(' close',
              style: TextStyle(color: AppPalette.inkLight, fontSize: 12)),
          const Spacer(),
          Text('press / for AI commands',
              style: TextStyle(color: AppPalette.inkLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _kbd(String key) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: dark ? AppPalette.paperDark : AppPalette.paper,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Text(
        key,
        style: const TextStyle(
          color: AppPalette.inkLight,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          fontFamily: 'monospace',
          fontFamilyFallback: ['JetBrains Mono', 'SF Mono', 'Menlo'],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('try',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.inkLight,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              )),
          const SizedBox(height: 6),
          ..._suggestions().map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  s,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppPalette.inkMuted),
                ),
              )),
        ],
      ),
    );
  }

  List<String> _suggestions() => const [
        'search a teammate by name — "jamie"',
        'find a message — "rollback"',
        'jump to a group — "launch room"',
        'press / inside a chat for AI commands',
      ];

  List<_Result> _runQuery(AppState app, String q) {
    final out = <_Result>[];

    if (q.isEmpty) {
      // Default: most recent conversations.
      final recent = [...app.conversations]
        ..sort((a, b) {
          final at = a.lastMessage?.sentAt ?? DateTime(2000);
          final bt = b.lastMessage?.sentAt ?? DateTime(2000);
          return bt.compareTo(at);
        });
      for (final c in recent.take(6)) {
        out.add(_Result.chat(c));
      }
      return out;
    }

    // People matches
    for (final u in app.users) {
      if (u.name.toLowerCase().contains(q)) {
        out.add(_Result.person(u.id));
      }
    }
    if (app.pulse.name.toLowerCase().contains(q)) {
      out.add(_Result.person(app.pulse.id));
    }

    // Chat title matches
    for (final c in app.conversations) {
      final title = c.isGroup
          ? (c.groupName ?? '').toLowerCase()
          : app
              .userById(c.participantIds.firstWhere(
                (id) => id != app.me.id && id != app.pulse.id,
                orElse: () => app.pulse.id,
              ))
              .name
              .toLowerCase();
      if (title.contains(q)) {
        out.add(_Result.chat(c));
      }
    }

    // Message body matches — cap at 8 to stay tidy
    var messageHits = 0;
    outer:
    for (final c in app.conversations) {
      for (final m in c.messages.reversed) {
        if (m.text.toLowerCase().contains(q)) {
          out.add(_Result.message(c, m));
          messageHits++;
          if (messageHits >= 8) break outer;
        }
      }
    }

    return out;
  }

  void _activate(BuildContext context, _Result r) {
    final app = context.read<AppState>();
    Navigator.of(context).pop();
    switch (r.type) {
      case _ResultType.chat:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatDetailScreen(conversationId: r.conversation!.id),
        ));
        break;
      case _ResultType.person:
        final id = r.userId!;
        if (id == app.pulse.id) {
          // No 1:1 with Pulse — open the most recent chat instead.
          if (app.conversations.isNotEmpty) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChatDetailScreen(conversationId: app.conversations.first.id),
            ));
          }
          return;
        }
        () async {
          final c = await app.createOneOnOne(id);
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatDetailScreen(conversationId: c.id),
          ));
        }();
        break;
      case _ResultType.message:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatDetailScreen(conversationId: r.conversation!.id),
        ));
        break;
      case _ResultType.action:
        r.onTap?.call();
        break;
    }
  }

  Widget _buildResult(BuildContext context, _Result r) {
    final app = context.read<AppState>();
    final theme = Theme.of(context);
    Widget leading;
    String title;
    String? subtitle;

    switch (r.type) {
      case _ResultType.chat:
        final c = r.conversation!;
        final otherId = c.isGroup
            ? null
            : c.participantIds.firstWhere(
                (id) => id != app.me.id && id != app.pulse.id,
                orElse: () => app.pulse.id);
        final avatarId = c.isGroup
            ? (c.groupAvatarId ?? 'ai:pulse')
            : app.userById(otherId!).avatarId;
        leading = AvatarView(avatarId: avatarId, size: 32);
        title = c.isGroup ? (c.groupName ?? 'group') : app.userById(otherId!).name;
        subtitle = c.isGroup ? 'group · ${c.messages.length} messages' : 'chat';
        break;
      case _ResultType.person:
        final u = app.userById(r.userId!);
        leading = AvatarView(avatarId: u.avatarId, size: 32);
        title = u.name;
        subtitle = u.status ?? 'open chat';
        break;
      case _ResultType.message:
        final c = r.conversation!;
        final m = r.message!;
        final author = app.userById(m.authorId);
        leading = AvatarView(avatarId: author.avatarId, size: 32);
        final chatTitle = c.isGroup
            ? (c.groupName ?? 'group')
            : app
                .userById(c.participantIds.firstWhere(
                  (id) => id != app.me.id && id != app.pulse.id,
                  orElse: () => app.pulse.id,
                ))
                .name;
        title = '${author.name} · $chatTitle';
        subtitle = m.text;
        break;
      case _ResultType.action:
        leading = Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppPalette.bubbleOther,
            shape: BoxShape.circle,
          ),
          child: Icon(r.icon ?? Icons.bolt_rounded, size: 16, color: AppPalette.ink),
        );
        title = r.actionLabel ?? '';
        subtitle = null;
        break;
    }

    return InkWell(
      onTap: () => _activate(context, r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (subtitle != null)
                    r.type == _ResultType.message
                        ? Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: SizedBox(
                              height: 18,
                              child: ClipRect(
                                child: MessageText(
                                  text: subtitle,
                                  color: AppPalette.inkMuted,
                                  fromMe: false,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkMuted,
                            ),
                          ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: AppPalette.inkLight, size: 16),
          ],
        ),
      ),
    );
  }
}

enum _ResultType { chat, person, message, action }

class _Result {
  final _ResultType type;
  final Conversation? conversation;
  final Message? message;
  final String? userId;
  final String? actionLabel;
  final IconData? icon;
  final VoidCallback? onTap;

  _Result.chat(Conversation c)
      : type = _ResultType.chat,
        conversation = c,
        message = null,
        userId = null,
        actionLabel = null,
        icon = null,
        onTap = null;

  _Result.person(String id)
      : type = _ResultType.person,
        conversation = null,
        message = null,
        userId = id,
        actionLabel = null,
        icon = null,
        onTap = null;

  _Result.message(Conversation c, Message m)
      : type = _ResultType.message,
        conversation = c,
        message = m,
        userId = null,
        actionLabel = null,
        icon = null,
        onTap = null;
}

/// Wraps the app with global ⌘K / ctrl-K → command palette. Uses
/// `CallbackShortcuts` so it doesn't fight focus traversal at the root.
class GlobalShortcuts extends StatelessWidget {
  final Widget child;
  const GlobalShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            CommandPalette.open(context),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            CommandPalette.open(context),
      },
      child: child,
    );
  }
}

