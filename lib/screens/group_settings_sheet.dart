import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';
import '../widgets/pill_button.dart';

class GroupSettingsSheet extends StatefulWidget {
  final String conversationId;
  const GroupSettingsSheet({super.key, required this.conversationId});

  static Future<void> open(BuildContext context, String conversationId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupSettingsSheet(conversationId: conversationId),
    );
  }

  @override
  State<GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends State<GroupSettingsSheet> {
  late final TextEditingController _name;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final c = app.conversations.firstWhere((c) => c.id == widget.conversationId);
    _name = TextEditingController(text: c.groupName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final app = context.watch<AppState>();
    final c = app.conversations.firstWhere((c) => c.id == widget.conversationId);

    final memberIds = c.participantIds
        .where((id) => id != app.pulse.id)
        .toList();
    final nonMembers = app.users
        .where((u) => !c.participantIds.contains(u.id))
        .toList();

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppPalette.paperDark : AppPalette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark
                        ? AppPalette.hairlineDark
                        : AppPalette.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AvatarView(
                    avatarId: c.groupAvatarId ?? 'ai:pulse',
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingName
                        ? TextField(
                            controller: _name,
                            autofocus: true,
                            style: theme.textTheme.titleLarge,
                            decoration:
                                const InputDecoration(border: InputBorder.none),
                            onSubmitted: (v) {
                              if (v.trim().isNotEmpty) {
                                app.renameGroup(c.id, v.trim());
                              }
                              setState(() => _editingName = false);
                            },
                          )
                        : Text(
                            c.groupName ?? 'Group',
                            style: theme.textTheme.titleLarge,
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      _editingName ? Icons.check_rounded : Icons.edit_outlined,
                      size: 18,
                    ),
                    onPressed: () {
                      if (_editingName && _name.text.trim().isNotEmpty) {
                        app.renameGroup(c.id, _name.text.trim());
                      }
                      setState(() => _editingName = !_editingName);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Members · ${memberIds.length}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppPalette.inkLight),
              ),
              const SizedBox(height: 8),
              ...memberIds.map((id) {
                final u = app.userById(id);
                final isMe = id == app.me.id;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                  leading: AvatarView(avatarId: u.avatarId, size: 36),
                  title: Text('${u.name}${isMe ? ' (you)' : ''}'),
                  subtitle: u.status != null && u.status!.isNotEmpty
                      ? Text(u.status!)
                      : null,
                  trailing: isMe
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppPalette.inkLight, size: 20),
                          tooltip: 'Remove',
                          onPressed: () => app.removeGroupMember(c.id, id),
                        ),
                );
              }),
              if (nonMembers.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Add people',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppPalette.inkLight),
                ),
                const SizedBox(height: 8),
                ...nonMembers.map((u) => ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                      leading: AvatarView(avatarId: u.avatarId, size: 36),
                      title: Text(u.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppPalette.brand, size: 20),
                        tooltip: 'Add',
                        onPressed: () =>
                            app.addGroupMembers(c.id, [u.id]),
                      ),
                    )),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PillButton(
                    label: 'Leave group',
                    variant: PillVariant.ghost,
                    icon: Icons.logout_rounded,
                    onPressed: () => _confirmLeave(c),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this group?'),
        content: Text('You will no longer see new messages in ${c.groupName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppPalette.downTrend),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppState>().leaveGroup(c.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // close sheet
      Navigator.of(context).pop(); // close chat detail
    }
  }
}
