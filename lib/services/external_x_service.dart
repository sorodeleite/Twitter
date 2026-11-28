import 'dart:convert';
import 'dart:io';

import '../models.dart';

class ExternalXSource {
  const ExternalXSource({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarEmoji,
  });

  final String id;
  final String name;
  final String handle;
  final String avatarEmoji;

  Account toAccount() => Account(
        id: id,
        name: name,
        handle: '@$handle',
        bio: 'Atualizações públicas importadas do X.',
        website: 'https://x.com/$handle',
        avatarEmoji: avatarEmoji,
        autoInteract: false,
        isBot: false,
        isFriend: false,
      );
}

class ExternalXService {
  static const sources = <ExternalXSource>[
    ExternalXSource(
      id: 'external-acervyillit',
      name: 'Acervo ILLIT',
      handle: 'acervyillit',
      avatarEmoji: '📸',
    ),
    ExternalXSource(
      id: 'external-ILLITHQBR',
      name: 'ILLIT HQ BR',
      handle: 'ILLITHQBR',
      avatarEmoji: '📰',
    ),
  ];

  static Future<String?> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/rss+xml, application/xml, text/xml, */*');
      final response = await request.close().timeout(const Duration(seconds: 18));
      if (response.statusCode != HttpStatus.ok) return null;
      return await utf8.decodeStream(response);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static String _decode(String value) {
    var text = value.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      return code == null ? '' : String.fromCharCode(code);
    });
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-f]+);', caseSensitive: false), (m) {
      final code = int.tryParse(m.group(1) ?? '', radix: 16);
      return code == null ? '' : String.fromCharCode(code);
    });
    return text;
  }

  static String _plainText(String value) {
    final decoded = _decode(value)
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ');
    return decoded
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .trim();
  }

  static String? _tag(String block, String tag) {
    final match = RegExp(
      '<$tag(?:\\s[^>]*)?>([\\s\\S]*?)</$tag>',
      caseSensitive: false,
    ).firstMatch(block);
    return match?.group(1);
  }

  static String? _attribute(String block, String tag, String attribute) {
    final element = RegExp('<$tag\\b[^>]*>', caseSensitive: false).firstMatch(block)?.group(0);
    if (element == null) return null;
    return RegExp("$attribute=[\"']([^\"']+)[\"']", caseSensitive: false)
        .firstMatch(element)
        ?.group(1);
  }

  static int _date(String? value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    final parsed = DateTime.tryParse(value) ?? (() {
      try {
        return HttpDate.parse(value);
      } catch (_) {
        return null;
      }
    })();
    return parsed?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
  }

  static String _id(String sourceId, String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return '$sourceId-$hash';
  }

  static Future<List<Post>> fetch(ExternalXSource source) async {
    final url = 'https://fxtwitter.com/${source.handle}/feed.xml?count=25&safe=1';
    final xml = await _get(url);
    if (xml == null || xml.isEmpty) return [];
    final items = RegExp(r'<item\b[^>]*>([\s\S]*?)</item>', caseSensitive: false)
        .allMatches(xml);
    final posts = <Post>[];
    for (final match in items) {
      final item = match.group(1) ?? '';
      final link = _decode(_tag(item, 'link') ?? '').trim();
      final guid = _decode(_tag(item, 'guid') ?? '').trim();
      final description = _plainText(
        _tag(item, 'description') ?? _tag(item, 'content:encoded') ?? '',
      );
      final title = _plainText(_tag(item, 'title') ?? '');
      final text = description.isNotEmpty ? description : title;
      if (text.isEmpty) continue;

      final enclosure = _attribute(item, 'enclosure', 'url');
      final mediaContent = _attribute(item, 'media:content', 'url');
      final mediaThumbnail = _attribute(item, 'media:thumbnail', 'url');
      final mediaCandidates = [enclosure, mediaContent, mediaThumbnail].whereType<String>();
      final imageCandidate = mediaCandidates.firstWhere(
        (candidate) =>
            !candidate.toLowerCase().contains('.mp4') &&
            !candidate.toLowerCase().contains('video'),
        orElse: () => '',
      );
      final imageUrl = imageCandidate.isEmpty ? null : imageCandidate;
      final permalink = link.startsWith('http')
          ? link
          : (guid.startsWith('http') ? guid : 'https://x.com/${source.handle}');
      final seed = guid.isNotEmpty ? guid : (link.isNotEmpty ? link : '$text-${_tag(item, 'pubDate')}');
      posts.add(Post(
        id: _id(source.id, seed),
        accountId: source.id,
        name: source.name,
        handle: '@${source.handle}',
        avatarEmoji: source.avatarEmoji,
        text: text,
        createdAtMs: _date(_tag(item, 'pubDate')),
        imageUrl: imageUrl,
        linkUrl: permalink,
        linkTitle: 'Ver publicação no X',
        isBot: false,
      ));
    }
    return posts;
  }

  static Future<List<Post>> fetchAll() async {
    final results = await Future.wait(sources.map(fetch));
    return results.expand((items) => items).toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
  }
}
