import 'dart:convert';
import 'dart:io';

import '../data/illit_knowledge.dart';
import '../models.dart';

/// Fonte de dados real da conta @illitupdates.
///
/// Combina uma base offline conferida (IllitKnowledge) com feeds ao vivo:
/// Google News (PT/EN/KO), YouTube oficial (HYBE LABELS e ILLIT) e iTunes.
class IllitService {
  static const List<String> mokaAssets = [
    'asset:assets/images/HYGeCyRbgAAL7R_.jpg',
    'asset:assets/images/HYGeDTaaMAAQd74.jpg',
    'asset:assets/images/HYGeDzGbYAArkl0.jpg',
    'asset:assets/images/72451152-FA2A-4645-A1D0-5287E73383B5.jpg',
    'asset:assets/images/HTva9CwXEAAAf5-.jpg',
  ];

  static const _newsFeeds = <String>[
    'https://news.google.com/rss/search?q=ILLIT+kpop&hl=pt-BR&gl=BR&ceid=BR:pt-419',
    'https://news.google.com/rss/search?q=ILLIT+kpop&hl=en-US&gl=US&ceid=US:en',
    'https://news.google.com/rss/search?q=%EC%95%84%EC%9D%BC%EB%A6%BF&hl=ko&gl=KR&ceid=KR:ko',
  ];

  static const _youtubeFeeds = <String>[
    'https://www.youtube.com/feeds/videos.xml?channel_id=UC3IZKseVpdzPSBaWxBxundA', // HYBE LABELS
    'https://www.youtube.com/feeds/videos.xml?channel_id=UCEpFoWeCMCo5z3EvWaz6hQQ', // ILLIT
  ];

  static const _itunesUrl =
      'https://itunes.apple.com/search?term=ILLIT&entity=album&limit=25&country=US';

  static Future<String?> _get(String url, {int timeoutSeconds = 10}) async {
    final client = HttpClient()..connectionTimeout = Duration(seconds: timeoutSeconds);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Mobile Safari/537.36',
      );
      req.headers.set('Accept-Language', 'pt-BR,pt;q=0.9,en;q=0.8');
      final res = await req.close().timeout(Duration(seconds: timeoutSeconds + 6));
      if (res.statusCode != 200) return null;
      return await utf8.decodeStream(res);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static String _decodeHtml(String input) {
    var out = input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');
    out = out.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '');
    out = out.replaceAll(RegExp(r'<[^>]+>'), '');
    out = out.replaceAll(RegExp(r'&#\d+;'), '');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _tag(String block, String tag) {
    final m = RegExp('<$tag[^>]*>([\\s\\S]*?)</$tag>', caseSensitive: false).firstMatch(block);
    if (m == null) return null;
    final value = _decodeHtml(m.group(1) ?? '');
    return value.isEmpty ? null : value;
  }

  static int _parseDateMs(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now().millisecondsSinceEpoch;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.millisecondsSinceEpoch;
    try {
      return HttpDate.parse(raw).millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  static String _stableId(String prefix, String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return '$prefix-$hash';
  }

  static bool _isIllit(String text) {
    final lower = text.toLowerCase();
    return lower.contains('illit') ||
        lower.contains('아일릿') ||
        lower.contains('moka') ||
        lower.contains('wonhee') ||
        lower.contains('minju') ||
        lower.contains('yunah') ||
        lower.contains('iroha');
  }

  static int _seedNumber(String seed, int min, int max) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 37 + code) & 0x7fffffff;
    }
    return min + (hash % (max - min + 1));
  }

  static Post _postFor(
    Account account, {
    required String id,
    required String text,
    required int createdAtMs,
    String? image,
    String? imageUrl,
    String? linkUrl,
    String? linkTitle,
  }) {
    return Post(
      id: id,
      accountId: account.id,
      name: account.name,
      handle: account.handle,
      avatarEmoji: account.avatarEmoji,
      avatarPath: account.avatarPath,
      verified: account.verified,
      isBot: true,
      text: text,
      image: image,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      linkTitle: linkTitle,
      createdAtMs: createdAtMs,
      likes: _seedNumber(id, 240, 2400),
      reposts: _seedNumber('$id-r', 40, 640),
      views: _seedNumber('$id-v', 1800, 48000),
    );
  }

  /// Notícias, vídeos e lançamentos reais, buscados na hora.
  static Future<List<Post>> fetchLiveUpdates(Account account) async {
    final results = <Post>[];
    final seenIds = <String>{};
    final responses = await Future.wait<dynamic>([
      for (final feed in _newsFeeds) _get(feed),
      for (final feed in _youtubeFeeds) _get(feed),
      _get(_itunesUrl),
    ]);

    final newsResponses = responses.take(_newsFeeds.length).cast<String?>();
    final youtubeResponses =
        responses.skip(_newsFeeds.length).take(_youtubeFeeds.length).cast<String?>();
    final itunesRaw = responses.last as String?;

    // 1. Notícias (Google News PT, EN e KO)
    var newsCount = 0;
    for (final xml in newsResponses) {
      if (xml == null) continue;
      final items = RegExp(r'<item>([\s\S]*?)</item>').allMatches(xml);
      for (final m in items) {
        if (newsCount >= 10) break;
        final block = m.group(1) ?? '';
        final title = _tag(block, 'title') ?? '';
        final link = _tag(block, 'link') ?? '';
        if (title.isEmpty || !_isIllit(title)) continue;
        final source = _tag(block, 'source') ?? 'Notícias';
        final dateMs = _parseDateMs(_tag(block, 'pubDate'));
        final cleanTitle = title.replaceAll(RegExp(r'\s+-\s+[^-]{2,40}$'), '').trim();
        final id = _stableId('illit-news', cleanTitle.toLowerCase());
        if (!seenIds.add(id)) continue;
        results.add(_postFor(
          account,
          id: id,
          text: '✧ NOTÍCIA ILLIT\n\n$cleanTitle\n\nFonte: $source · #ILLIT #GLLIT',
          linkUrl: link.isEmpty ? null : link,
          linkTitle: source,
          createdAtMs: dateMs,
        ));
        newsCount++;
      }
    }

    // 2. YouTube (MV, teasers, behind the scenes)
    var videoCount = 0;
    for (final xml in youtubeResponses) {
      if (xml == null) continue;
      final entries = RegExp(r'<entry>([\s\S]*?)</entry>').allMatches(xml);
      for (final m in entries) {
        if (videoCount >= 8) break;
        final block = m.group(1) ?? '';
        final title = _tag(block, 'title') ?? '';
        if (title.isEmpty || !_isIllit(title)) continue;
        final linkMatch = RegExp(r'<link[^>]+href="([^"]+)"').firstMatch(block);
        final thumbMatch = RegExp(r'<media:thumbnail[^>]+url="([^"]+)"').firstMatch(block);
        final published = _tag(block, 'published');
        final videoId = _tag(block, 'yt:videoId') ?? title;
        final id = _stableId('illit-video', videoId);
        if (!seenIds.add(id)) continue;
        results.add(_postFor(
          account,
          id: id,
          text: '📺 NOVO VÍDEO\n\n$title\n\nCanal oficial do ILLIT · #ILLIT #GLLIT',
          imageUrl: thumbMatch?.group(1),
          linkUrl: linkMatch?.group(1),
          linkTitle: 'YouTube',
          createdAtMs: _parseDateMs(published),
        ));
        videoCount++;
      }
    }

    // 3. Discografia (iTunes)
    if (itunesRaw != null) {
      try {
        final decoded = jsonDecode(itunesRaw) as Map<String, dynamic>;
        final albums = decoded['results'] as List<dynamic>? ?? [];
        var albumCount = 0;
        for (final item in albums) {
          if (albumCount >= 8) break;
          final a = item as Map<String, dynamic>;
          final artist = (a['artistName'] as String? ?? '').toUpperCase();
          if (!artist.contains('ILLIT')) continue;
          final album = (a['collectionName'] as String? ?? '').trim();
          if (album.isEmpty) continue;
          final releaseRaw = a['releaseDate'] as String? ?? '';
          final tracks = a['trackCount'] as int? ?? 0;
          final art = (a['artworkUrl100'] as String? ?? '')
              .replaceAll('100x100bb', '600x600bb');
          final url = a['collectionViewUrl'] as String?;
          final dateLabel = releaseRaw.length >= 10 ? releaseRaw.substring(0, 10) : releaseRaw;
          final id = _stableId('illit-album', album.toLowerCase());
          if (!seenIds.add(id)) continue;
          results.add(_postFor(
            account,
            id: id,
            text: '💿 DISCOGRAFIA\n\n"$album" — ILLIT\n'
                'Lançamento: ${_prettyDate(dateLabel)} · $tracks faixas\n\n'
                'Ouça nos streams · #ILLIT #GLLIT',
            imageUrl: art.isEmpty ? null : art,
            linkUrl: url,
            linkTitle: 'Apple Music',
            createdAtMs: _parseDateMs(releaseRaw),
          ));
          albumCount++;
        }
      } catch (_) {}
    }

    results.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return results;
  }

  static String _prettyDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  /// Posts definitivos sobre a carreira e a ficha do grupo.
  /// São reais, conferidos e continuam no perfil mesmo offline.
  static List<Post> wikiPosts(Account account) {
    final now = DateTime.now().millisecondsSinceEpoch;
    const hour = 3600 * 1000;
    return [
      _postFor(
        account,
        id: 'illit-ficha-grupo',
        text: '✧ FICHA DO GRUPO · ILLIT (아일릿)\n\n'
            '• Estreia: ${IllitKnowledge.debut}\n'
            '• Gravadora: ${IllitKnowledge.label}\n'
            '• Fandom: ${IllitKnowledge.fandom}\n'
            '• Formação: reality "R U Next?" (JTBC, 2023)\n'
            '• Integrantes: Yunah, Minju, Moka, Wonhee e Iroha\n\n'
            '${IllitKnowledge.about}\n\n#ILLIT #GLLIT',
        createdAtMs: now - 46 * hour,
        image: mokaAssets[0],
      ),
      _postFor(
        account,
        id: 'illit-members-2026',
        text: '✦ GUIA DAS INTEGRANTES (atualizado em ${IllitKnowledge.updatedAt})\n\n'
            '${IllitKnowledge.members.map((m) => '• ${m.name} (${m.korean.split(' · ').last}) — ${m.fullName}, ${m.birthday}, ${m.nationality} ${m.emoji}').join('\n')}\n\n'
            '#ILLIT #GLLIT',
        createdAtMs: now - 40 * hour,
      ),
      _postFor(
        account,
        id: 'illit-discografia-2026',
        text: '💿 DISCOGRAFIA COMPLETA\n\n'
            '${IllitKnowledge.releases.map((r) => '• ${r.title} (${r.date}) — "${r.titleTrack}"').join('\n')}\n\n'
            'Singles: "Almond Chocolate", "Toki Yo Tomare", "Not Cute Anymore", "Sunday Morning", '
            '"Iconic by Mistake" (com LE SSERAFIM e KATSEYE), "I Got Your Back", "Swingin\' Magic" e '
            '"You\'re Under Arrest".\n\n#ILLIT #GLLIT',
        createdAtMs: now - 33 * hour,
      ),
      _postFor(
        account,
        id: 'illit-records-2026',
        text: '🏆 RECORDES QUE O ILLIT JÁ FEZ\n\n'
            '• "Magnetic" foi o 1º single de estreia de um ato de K-pop no Billboard Hot 100 (#91)\n'
            '• 1º grupo de K-pop no UK Official Singles com o single de estreia (#80)\n'
            '• "Super Real Me": #93 na Billboard 200 e 2× Platina na Coreia\n'
            '• "Bomb": Platina na Coreia (250 mil cópias)\n'
            '• Primeira "K-Pop Rookie of the Month" da Billboard\n\n#ILLIT #GLLIT',
        createdAtMs: now - 27 * hour,
      ),
      _postFor(
        account,
        id: 'illit-mma-2026',
        text: '🏆 MMA 2026 — QUATRO PRÊMIOS EM UMA NOITE\n\n'
            'No dia 15 de novembro, no Gocheok Sky Dome, o ILLIT levou Top 10, Global Top 10, '
            'Best Performance Female e Global Impact Artist. Que ano, GLLITs! ♡\n\n#ILLIT #MMA2026',
        createdAtMs: now - 21 * hour,
        image: mokaAssets[2],
      ),
      _postFor(
        account,
        id: 'illit-break-even-2026',
        text: '💿 "BREAK EVEN" JÁ ESTÁ ENTRE NÓS\n\n'
            'O 5º mini álbum saiu em 26 de outubro com a faixa-título "You\'re Under Arrest" '
            '(체포하겠어). Tracklist: Super in Love · More · You\'re Under Arrest · Pop.\n\n'
            '#ILLIT #BreakEven',
        createdAtMs: now - 15 * hour,
        image: mokaAssets[3],
      ),
      _postFor(
        account,
        id: 'illit-status-moka-2026',
        text: '♡ ATUALIZAÇÃO IMPORTANTE\n\n'
            'A Moka está em hiato desde 19 de junho de 2026 para tratar ansiedade e tensão excessiva '
            '(houve uma primeira pausa em abril, com retorno em maio). Em 18 de novembro a BELIFT '
            'reduziu a divulgação de "Break Even" porque Yunah, Minju e Wonhee tiveram febre e sintomas '
            'gripais, e Wonhee e Iroha estão tratando lesões no tornozelo.\n\n'
            'Manda energias boas para as meninas ♡ #ILLIT #GLLIT',
        createdAtMs: now - 9 * hour,
        image: mokaAssets[1],
      ),
      _postFor(
        account,
        id: 'illit-tours-2026',
        text: '🎤 TURNÊS\n\n'
            '${IllitKnowledge.tours.join('\n\n')}\n\n#ILLIT #PressStart',
        createdAtMs: now - 4 * hour,
      ),
    ];
  }

  static List<Post> initialSeedPosts(Account account) => wikiPosts(account);
}
