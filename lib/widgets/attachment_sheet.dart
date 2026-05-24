import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// What the user picked in the attachment sheet. The composer translates the
/// pick into a message: a placeholder file/photo/poll/location chip in this
/// demo, real native pickers in a production build.
enum AttachmentKind { photo, camera, file, voice, location, poll }

class AttachmentSheet extends StatelessWidget {
  const AttachmentSheet({super.key});

  static Future<AttachmentKind?> open(BuildContext context) {
    return showModalBottomSheet<AttachmentKind>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AttachmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppPalette.paperDark : AppPalette.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Attach',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _row(context,
                icon: Icons.photo_library_outlined,
                label: 'Photo',
                detail: 'Pick from your library',
                kind: AttachmentKind.photo),
            _row(context,
                icon: Icons.photo_camera_outlined,
                label: 'Camera',
                detail: 'Take a new one',
                kind: AttachmentKind.camera),
            _row(context,
                icon: Icons.mic_none_rounded,
                label: 'Voice note',
                detail: 'Record and send',
                kind: AttachmentKind.voice),
            _row(context,
                icon: Icons.insert_drive_file_outlined,
                label: 'File',
                detail: 'PDF, doc, anything',
                kind: AttachmentKind.file),
            _row(context,
                icon: Icons.location_on_outlined,
                label: 'Location',
                detail: 'Share where you are',
                kind: AttachmentKind.location),
            _row(context,
                icon: Icons.poll_outlined,
                label: 'Poll',
                detail: 'Quick yes/no/multi',
                kind: AttachmentKind.poll),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String detail,
    required AttachmentKind kind,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppPalette.bubbleOther,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppPalette.ink, size: 18),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppPalette.inkLight),
      onTap: () => Navigator.of(context).pop(kind),
    );
  }
}
