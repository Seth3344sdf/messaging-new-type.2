import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/avatar.dart';

/// Trust through transparency. Shows the encryption protocol, key
/// verification status, last audit date, and data residency. All copy is
/// plain language — technical details on the side.
class EncryptionSheet extends StatelessWidget {
  final String? conversationId;
  const EncryptionSheet({super.key, this.conversationId});

  static Future<void> open(BuildContext context, {String? conversationId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EncryptionSheet(conversationId: conversationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final app = context.read<AppState>();

    // Build the "other person's devices" list. For 1:1 chats, show the
    // other user's devices; for groups, show the participant count.
    final convo = conversationId == null
        ? null
        : app.conversations
            .where((c) => c.id == conversationId)
            .toList()
            .firstOrNull;
    final isGroup = convo?.isGroup ?? false;
    final otherUser = convo == null
        ? null
        : app.userById(convo.participantIds.firstWhere(
            (id) => id != app.me.id && id != app.pulse.id,
            orElse: () => app.pulse.id,
          ));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? AppPalette.paperDark : AppPalette.paper,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        dark ? AppPalette.hairlineDark : AppPalette.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppPalette.presence.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock_rounded,
                      color: AppPalette.presence, size: 26),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'End-to-end encrypted',
                  style: theme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  isGroup
                      ? 'Your messages can only be read by you and the people in this group.'
                      : 'Your messages can only be read by you and ${otherUser?.name ?? 'the recipient'}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _row(context,
                  icon: Icons.security_rounded,
                  label: 'Protocol',
                  value: 'Messaging Layer Security (MLS)'),
              _row(context,
                  icon: Icons.verified_user_outlined,
                  label: 'Key verification',
                  value: 'All devices verified',
                  valueTint: AppPalette.presence),
              _row(context,
                  icon: Icons.update_rounded,
                  label: 'Last audit',
                  value: 'May 2026 · public report available'),
              _row(context,
                  icon: Icons.public_off_rounded,
                  label: 'Data residency',
                  value: 'US-East · keys never leave your device'),
              const SizedBox(height: 18),
              if (otherUser != null && !isGroup) ...[
                Text(
                  '${otherUser.name}\'s devices',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppPalette.inkLight),
                ),
                const SizedBox(height: 8),
                _deviceRow(context, otherUser.avatarId,
                    label: 'iPhone 15 Pro', verified: true),
                _deviceRow(context, otherUser.avatarId,
                    label: 'MacBook Pro', verified: true),
                _deviceRow(context, otherUser.avatarId,
                    label: 'iPad Air', verified: false),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              Text(
                'Pulse processes your messages only after they are encrypted to a per-conversation key — your messages are never used to train a model.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.inkMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueTint,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppPalette.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueTint,
                    fontWeight: valueTint != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceRow(BuildContext context, String avatarId,
      {required String label, required bool verified}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AvatarView(avatarId: avatarId, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (verified ? AppPalette.presence : AppPalette.decision)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verified
                      ? Icons.check_rounded
                      : Icons.error_outline_rounded,
                  size: 11,
                  color:
                      verified ? AppPalette.presence : AppPalette.decision,
                ),
                const SizedBox(width: 4),
                Text(
                  verified ? 'verified' : 'unverified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: verified
                        ? AppPalette.presence
                        : AppPalette.decision,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
