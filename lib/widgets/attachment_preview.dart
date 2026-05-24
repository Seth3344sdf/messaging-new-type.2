import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Renders an attachment URL pulled out of a message body. Inline thumbnail
/// for image extensions, file-card with name+download icon for everything
/// else.
class AttachmentPreview extends StatelessWidget {
  final String url;
  final bool fromMe;
  const AttachmentPreview({super.key, required this.url, required this.fromMe});

  static final _imgExt = RegExp(r'\.(png|jpe?g|webp|gif|heic|heif)(\?|$)',
      caseSensitive: false);

  bool get _isImage => _imgExt.hasMatch(url);

  String get _filename {
    final segs = Uri.tryParse(url)?.pathSegments;
    if (segs == null || segs.isEmpty) return 'file';
    return segs.last;
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260, maxWidth: 300),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : _imagePlaceholder(context),
            errorBuilder: (context, error, stack) => _fileCard(context),
          ),
        ),
      );
    }
    return _fileCard(context);
  }

  Widget _imagePlaceholder(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 200,
      height: 160,
      color: dark ? AppPalette.surfaceDark : AppPalette.surface,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _fileCard(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = fromMe
        ? Colors.white
        : (dark ? AppPalette.inkOnDark : AppPalette.ink);
    final bg = fromMe
        ? Colors.white.withValues(alpha: 0.18)
        : (dark ? AppPalette.surfaceDark : AppPalette.surface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: fromMe
            ? null
            : Border.all(
                color: dark
                    ? AppPalette.hairlineDark
                    : AppPalette.hairline,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 18, color: fg),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              _filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.open_in_new_rounded, size: 14, color: fg),
        ],
      ),
    );
  }
}
