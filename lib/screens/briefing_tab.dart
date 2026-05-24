import 'package:flutter/material.dart';

import '../data/briefing_mock.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Briefing — market data + curated headlines + watchlist. Mocked data for
/// the demo; a real build would plug in Finnhub / NewsAPI / CoinGecko.
class BriefingTab extends StatelessWidget {
  const BriefingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final indices = BriefingMock.indices();
    final headlines = BriefingMock.headlines();
    final watch = BriefingMock.watchlist();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Briefing'),
        actions: const [
          IconButton(
            icon: Icon(Icons.tune_rounded),
            onPressed: null,
            tooltip: 'Briefing settings',
          ),
          SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            'Markets',
            style: serifHeadline(
              size: 22,
              color: dark ? AppPalette.inkOnDark : AppPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: indices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _MarketCard(idx: indices[i]),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Headlines',
            style: serifHeadline(
              size: 22,
              color: dark ? AppPalette.inkOnDark : AppPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          ...headlines.map((h) => _HeadlineCard(h: h)),
          const SizedBox(height: 22),
          Text(
            'Watchlist',
            style: serifHeadline(
              size: 22,
              color: dark ? AppPalette.inkOnDark : AppPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          ...watch.map((w) => _WatchRow(item: w)),
        ],
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final MarketIndex idx;
  const _MarketCard({required this.idx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final up = idx.changePct >= 0;
    final trend = up ? AppPalette.presence : AppPalette.downTrend;
    return Container(
      width: 156,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            idx.name,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: AppPalette.inkLight),
          ),
          const SizedBox(height: 4),
          Text(
            _formatValue(idx.value),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                up ? Icons.north_east_rounded : Icons.south_east_rounded,
                size: 13,
                color: trend,
              ),
              const SizedBox(width: 2),
              Text(
                '${up ? '+' : ''}${idx.changePct.toStringAsFixed(2)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: trend,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _SparklinePainter(points: idx.sparkline, color: trend),
              size: const Size.fromHeight(28),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 1000) {
      final whole = v.toInt();
      final s = whole.toString();
      final parts = <String>[];
      for (var i = s.length; i > 0; i -= 3) {
        parts.insert(0, s.substring(i - 3 < 0 ? 0 : i - 3, i));
      }
      return parts.join(',');
    }
    return v.toStringAsFixed(2);
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, stroke);

    // Soft fill below the line for ambient depth.
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fill = Paint()
      ..color = color.withValues(alpha: 0.10);
    canvas.drawPath(fillPath, fill);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.color != color;
}

class _HeadlineCard extends StatelessWidget {
  final NewsHeadline h;
  const _HeadlineCard({required this.h});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final age = _ago(h.publishedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (h.hot) ...[
                const Icon(Icons.local_fire_department_rounded,
                    size: 14, color: AppPalette.terracotta),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  h.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${h.source} · $age · #${h.tag}',
            style: theme.textTheme.bodySmall,
          ),
          if (h.teamMentions > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 12, color: AppPalette.ai),
                const SizedBox(width: 4),
                Text(
                  '${h.teamMentions} teams discussing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.ai,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _ShareChip(
                  label: 'Share',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Would open a "share to chat" picker'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _ShareChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShareChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: dark ? AppPalette.paperDark : AppPalette.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ios_share_rounded,
                size: 12, color: AppPalette.inkMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  final WatchlistItem item;
  const _WatchRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final up = item.changePct >= 0;
    final trend = up ? AppPalette.presence : AppPalette.downTrend;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? AppPalette.surfaceDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? AppPalette.hairlineDark : AppPalette.hairline,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              item.symbol,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Text(
              item.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            height: 24,
            child: CustomPaint(
              painter: _SparklinePainter(points: item.sparkline, color: trend),
              size: const Size(60, 24),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${up ? '+' : ''}${item.changePct.toStringAsFixed(2)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trend,
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
