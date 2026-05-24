import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/pill_button.dart';

/// Drag-drop / pick a Slack export ZIP. We parse channels/messages from the
/// standard export format (per-day JSON arrays under each channel folder),
/// create a group per channel, and send each historic message as the
/// current user. Authors/timestamps get lost in this simple flow — good
/// enough for "show me my old stuff."
class SlackImportScreen extends StatefulWidget {
  const SlackImportScreen({super.key});

  @override
  State<SlackImportScreen> createState() => _SlackImportScreenState();
}

class _SlackImportScreenState extends State<SlackImportScreen> {
  bool _busy = false;
  String? _status;
  int _channels = 0;
  int _messages = 0;

  Future<void> _pickAndImport() async {
    final res = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;

    setState(() {
      _busy = true;
      _status = 'Reading the export…';
      _channels = 0;
      _messages = 0;
    });

    try {
      final bytes = res.files.first.bytes!;
      final archive = ZipDecoder().decodeBytes(bytes);

      // Slack export layout:
      //   channels.json
      //   users.json
      //   <channel>/<YYYY-MM-DD>.json
      final channelsJson = archive.findFile('channels.json');
      if (channelsJson == null) {
        setState(() => _status = "This doesn't look like a Slack export.");
        return;
      }

      final channels = (jsonDecode(
        utf8.decode(channelsJson.content as List<int>),
      ) as List)
          .cast<Map<String, dynamic>>();

      // Group messages by channel.
      final byChannel = <String, List<String>>{};
      for (final f in archive) {
        if (!f.isFile) continue;
        final parts = f.name.split('/');
        if (parts.length != 2) continue;
        if (!parts.last.endsWith('.json')) continue;
        final channelName = parts.first;
        final raw = utf8.decode(f.content as List<int>);
        try {
          final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
          final bucket = byChannel.putIfAbsent(channelName, () => []);
          for (final m in list) {
            final body = m['text'] as String?;
            if (body == null || body.isEmpty) continue;
            bucket.add(body);
          }
        } catch (_) {
          // Skip files that don't parse as a message array.
        }
      }

      if (!mounted) return;
      final app = context.read<AppState>();
      var importedChannels = 0;
      var importedMessages = 0;
      for (final ch in channels) {
        final name = ch['name'] as String?;
        if (name == null) continue;
        final body = byChannel[name];
        if (body == null || body.isEmpty) continue;

        setState(() => _status = 'Importing #$name (${body.length} messages)…');
        // Group with no other members yet — user can add teammates later.
        final convo = await app.createGroup(
          name: 'slack · $name',
          memberIds: const [],
        );
        // Cap to last 300 messages per channel so we don't drown anyone.
        final tail = body.length > 300 ? body.sublist(body.length - 300) : body;
        for (final m in tail) {
          await app.sendMessage(convo.id, m);
          importedMessages++;
        }
        importedChannels++;
        setState(() {
          _channels = importedChannels;
          _messages = importedMessages;
        });
      }

      setState(() => _status =
          'Done. Imported $_channels channels, $_messages messages.');
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Import from Slack')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Bring your Slack history with you.',
                style: serifHeadline(
                  size: 28,
                  color: dark ? AppPalette.inkOnDark : AppPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Export your Slack workspace (Workspace settings → Import / Export → Export), '
                'then drop the ZIP here. Each public channel becomes a group; the last 300 '
                'messages from each get imported.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.inkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              if (_busy) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_status ?? '…',
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ] else if (_status != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppPalette.brand.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(_status!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppPalette.brand,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              const SizedBox(height: 24),
              PillButton(
                label: _busy ? 'Working…' : 'Pick Slack export ZIP',
                icon: Icons.upload_file_rounded,
                onPressed: _busy ? null : _pickAndImport,
              ),
              const Spacer(),
              Text(
                'Authors and exact timestamps from Slack are not preserved — '
                'every imported message arrives as you. Better fidelity coming '
                'in a future version.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.inkLight,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
