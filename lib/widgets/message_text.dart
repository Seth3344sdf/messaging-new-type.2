import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Lightweight inline markdown renderer. Supports **bold**, _italic_,
/// `inline code`, ```fenced blocks```, and bare URLs. Intentionally small —
/// no full markdown spec, just the bits that come up in chat.
class MessageText extends StatelessWidget {
  final String text;
  final Color color;
  final bool fromMe;

  const MessageText({
    super.key,
    required this.text,
    required this.color,
    required this.fromMe,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _segmentByCodeFence(text);
    if (segments.length == 1 && segments.first.isCodeBlock == false) {
      return _inlineRichText(context, segments.first.text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments
          .map((seg) => seg.isCodeBlock
              ? _codeBlock(context, seg.text)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _inlineRichText(context, seg.text),
                ))
          .toList(),
    );
  }

  Widget _inlineRichText(BuildContext context, String body) {
    final theme = Theme.of(context);
    final baseStyle =
        theme.textTheme.bodyLarge?.copyWith(color: color) ?? TextStyle(color: color);
    final spans = _parseInline(body, baseStyle, context, fromMe);
    return Text.rich(TextSpan(children: spans));
  }

  Widget _codeBlock(BuildContext context, String code) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = fromMe
        ? Colors.white.withValues(alpha: 0.12)
        : (dark ? AppPalette.paperDark : AppPalette.hairline);
    final fg = fromMe
        ? Colors.white
        : (dark ? AppPalette.inkOnDark : AppPalette.ink);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        code.trim(),
        style: TextStyle(
          color: fg,
          fontFamily: 'monospace',
          fontFamilyFallback: const [
            'JetBrains Mono',
            'SF Mono',
            'Menlo',
            'Consolas',
          ],
          fontSize: 13.5,
          height: 1.4,
        ),
      ),
    );
  }

  static List<_Segment> _segmentByCodeFence(String text) {
    final out = <_Segment>[];
    final regex = RegExp(r'```([\s\S]*?)```');
    var cursor = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > cursor) {
        out.add(_Segment(text.substring(cursor, m.start), false));
      }
      out.add(_Segment(m.group(1) ?? '', true));
      cursor = m.end;
    }
    if (cursor < text.length) {
      out.add(_Segment(text.substring(cursor), false));
    }
    return out.isEmpty ? [_Segment(text, false)] : out;
  }

  static final _urlPattern = RegExp(
    r'(https?:\/\/[^\s]+|www\.[^\s]+)',
    caseSensitive: false,
  );

  static List<InlineSpan> _parseInline(
    String input,
    TextStyle base,
    BuildContext context,
    bool fromMe,
  ) {
    final spans = <InlineSpan>[];

    // Tokenize: walk character by character, peek for markers.
    var i = 0;
    String buf = '';

    void flush() {
      if (buf.isEmpty) return;
      // Inside the buffered run, linkify URLs.
      var lastEnd = 0;
      for (final m in _urlPattern.allMatches(buf)) {
        if (m.start > lastEnd) {
          spans.add(TextSpan(text: buf.substring(lastEnd, m.start), style: base));
        }
        spans.add(TextSpan(
          text: m.group(0),
          style: base.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: base.color?.withValues(alpha: 0.5),
          ),
        ));
        lastEnd = m.end;
      }
      if (lastEnd < buf.length) {
        spans.add(TextSpan(text: buf.substring(lastEnd), style: base));
      }
      buf = '';
    }

    while (i < input.length) {
      // Mention like @pulse
      if (input[i] == '@') {
        final m = RegExp(r'@\w+').matchAsPrefix(input, i);
        if (m != null) {
          flush();
          spans.add(TextSpan(
            text: m.group(0),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ));
          i = m.end;
          continue;
        }
      }
      // Bold **...**
      if (i + 1 < input.length && input[i] == '*' && input[i + 1] == '*') {
        final close = input.indexOf('**', i + 2);
        if (close != -1) {
          flush();
          spans.add(TextSpan(
            text: input.substring(i + 2, close),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ));
          i = close + 2;
          continue;
        }
      }
      // Italic _..._ — require word boundary on both sides to avoid eating
      // underscores in identifiers like snake_case.
      if (input[i] == '_') {
        final prev = i == 0 ? ' ' : input[i - 1];
        if (RegExp(r'\s|^').hasMatch(prev)) {
          final close = input.indexOf('_', i + 1);
          if (close != -1 && close - i > 1) {
            final after = close + 1 < input.length ? input[close + 1] : ' ';
            if (RegExp(r'\s|[.,!?;:)]|$').hasMatch(after)) {
              flush();
              spans.add(TextSpan(
                text: input.substring(i + 1, close),
                style: base.copyWith(fontStyle: FontStyle.italic),
              ));
              i = close + 1;
              continue;
            }
          }
        }
      }
      // Inline code `...`
      if (input[i] == '`') {
        final close = input.indexOf('`', i + 1);
        if (close != -1 && close - i > 1) {
          flush();
          final dark = Theme.of(context).brightness == Brightness.dark;
          final codeBg = fromMe
              ? Colors.white.withValues(alpha: 0.16)
              : (dark ? AppPalette.paperDark : AppPalette.hairline);
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: codeBg,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                input.substring(i + 1, close),
                style: base.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const [
                    'JetBrains Mono',
                    'SF Mono',
                    'Menlo',
                    'Consolas',
                  ],
                  fontSize: (base.fontSize ?? 15) - 1,
                ),
              ),
            ),
          ));
          i = close + 1;
          continue;
        }
      }

      buf += input[i];
      i++;
    }
    flush();
    return spans;
  }
}

class _Segment {
  final String text;
  final bool isCodeBlock;
  _Segment(this.text, this.isCodeBlock);
}
