import 'dart:math';

class MarketIndex {
  final String symbol;
  final String name;
  final double value;
  final double changePct;
  final List<double> sparkline;
  const MarketIndex({
    required this.symbol,
    required this.name,
    required this.value,
    required this.changePct,
    required this.sparkline,
  });
}

class NewsHeadline {
  final String id;
  final String title;
  final String source;
  final DateTime publishedAt;
  final String tag;
  final int teamMentions;
  final bool hot;
  const NewsHeadline({
    required this.id,
    required this.title,
    required this.source,
    required this.publishedAt,
    required this.tag,
    required this.teamMentions,
    this.hot = false,
  });
}

class WatchlistItem {
  final String symbol;
  final String name;
  final double price;
  final double changePct;
  final List<double> sparkline;
  const WatchlistItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
    required this.sparkline,
  });
}

class BriefingMock {
  BriefingMock._();

  static List<double> _sparkline(double seed, double drift, {int n = 24}) {
    final rnd = Random(seed.hashCode);
    final out = <double>[];
    var v = seed;
    for (var i = 0; i < n; i++) {
      v += (rnd.nextDouble() - 0.5) * (seed * 0.012) + drift;
      out.add(v);
    }
    return out;
  }

  static List<MarketIndex> indices() => [
        MarketIndex(
          symbol: 'SPX',
          name: 'S&P 500',
          value: 5234.18,
          changePct: 1.24,
          sparkline: _sparkline(5170, 2.4),
        ),
        MarketIndex(
          symbol: 'IXIC',
          name: 'NASDAQ',
          value: 16402.50,
          changePct: 0.82,
          sparkline: _sparkline(16280, 5),
        ),
        MarketIndex(
          symbol: 'DJI',
          name: 'DOW',
          value: 38940.12,
          changePct: 0.51,
          sparkline: _sparkline(38800, 6),
        ),
        MarketIndex(
          symbol: 'BTC',
          name: 'BTC',
          value: 67200,
          changePct: -2.14,
          sparkline: _sparkline(68800, -70),
        ),
      ];

  static List<NewsHeadline> headlines() {
    final now = DateTime.now();
    return [
      NewsHeadline(
        id: 'h1',
        title: 'Fed signals rate cut in June meeting minutes',
        source: 'Reuters',
        publishedAt: now.subtract(const Duration(minutes: 12)),
        tag: 'macro',
        teamMentions: 3,
        hot: true,
      ),
      NewsHeadline(
        id: 'h2',
        title: 'OpenAI announces GPT-5 developer preview',
        source: 'TechCrunch',
        publishedAt: now.subtract(const Duration(minutes: 34)),
        tag: 'tech',
        teamMentions: 2,
      ),
      NewsHeadline(
        id: 'h3',
        title: 'EU passes new AI regulation framework',
        source: 'Bloomberg',
        publishedAt: now.subtract(const Duration(hours: 1)),
        tag: 'policy',
        teamMentions: 1,
      ),
      NewsHeadline(
        id: 'h4',
        title: 'Apple reports record services revenue',
        source: 'WSJ',
        publishedAt: now.subtract(const Duration(hours: 2)),
        tag: 'earnings',
        teamMentions: 0,
      ),
      NewsHeadline(
        id: 'h5',
        title: 'NVDA breaks past \$1,000 ahead of earnings',
        source: 'CNBC',
        publishedAt: now.subtract(const Duration(hours: 3)),
        tag: 'markets',
        teamMentions: 0,
      ),
    ];
  }

  static List<WatchlistItem> watchlist() => [
        WatchlistItem(
          symbol: 'AAPL',
          name: 'Apple Inc.',
          price: 187.45,
          changePct: 2.12,
          sparkline: _sparkline(183, 0.18),
        ),
        WatchlistItem(
          symbol: 'TSLA',
          name: 'Tesla Inc.',
          price: 172.30,
          changePct: -3.42,
          sparkline: _sparkline(178, -0.24),
        ),
        WatchlistItem(
          symbol: 'NVDA',
          name: 'NVIDIA',
          price: 1024.18,
          changePct: 4.71,
          sparkline: _sparkline(978, 1.95),
        ),
        WatchlistItem(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 67200,
          changePct: -2.14,
          sparkline: _sparkline(68800, -70),
        ),
      ];
}
