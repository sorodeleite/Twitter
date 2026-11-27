import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseInfo {
  ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.apkUrl,
    required this.apkSize,
    required this.buildNumber,
    required this.publishedAt,
  });

  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final String? apkUrl;
  final int apkSize;
  final int buildNumber;
  final DateTime? publishedAt;
}

/// Verifica o release mais recente do GitHub e instala o APK por dentro do
/// app, do mesmo jeito que o Little Pause e o Sleep My Angel fazem.
class UpdaterService {
  static const String repo = 'sorodeleite/Twitter';
  static const int currentBuildNumber =
      int.fromEnvironment('BUILD_NUMBER', defaultValue: 0);
  static const String releasesPage = 'https://github.com/$repo/releases';
  static const String _apiLatest = 'https://api.github.com/repos/$repo/releases/latest';
  static const String _apiList = 'https://api.github.com/repos/$repo/releases?per_page=5';

  static Future<ReleaseInfo> fetchLatestRelease() async {
    Map<String, dynamic>? release;
    final latest = await _getJson(_apiLatest);
    if (latest is Map<String, dynamic>) {
      release = latest;
    } else {
      final list = await _getJson(_apiList);
      if (list is List && list.isNotEmpty) {
        release = list.first as Map<String, dynamic>;
      }
    }
    if (release == null) {
      throw const HttpException(
        'Nenhum release encontrado. O build do GitHub Actions ainda não publicou nada.',
      );
    }

    final tag = release['tag_name'] as String? ?? '';
    final match = RegExp(r'(\d+)\s*$').firstMatch(tag);
    final buildNum = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;

    String? apkUrl;
    var apkSize = 0;
    final assets = release['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      final a = asset as Map<String, dynamic>;
      final url = a['browser_download_url'] as String?;
      final name = (a['name'] as String? ?? '').toLowerCase();
      if (url != null && name.endsWith('.apk')) {
        apkUrl = url;
        apkSize = a['size'] as int? ?? 0;
        break;
      }
    }

    return ReleaseInfo(
      tagName: tag,
      name: release['name'] as String? ?? tag,
      body: release['body'] as String? ?? '',
      htmlUrl: release['html_url'] as String? ?? releasesPage,
      apkUrl: apkUrl,
      apkSize: apkSize,
      buildNumber: buildNum,
      publishedAt: DateTime.tryParse(release['published_at'] as String? ?? ''),
    );
  }

  static Future<dynamic> _getJson(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'sorodeleite-twitter-app');
      final res = await req.close().timeout(const Duration(seconds: 20));
      final text = await utf8.decodeStream(res);
      if (res.statusCode != 200) {
        throw HttpException('GitHub respondeu HTTP ${res.statusCode}');
      }
      return jsonDecode(text);
    } finally {
      client.close();
    }
  }

  static bool isNewer(ReleaseInfo release) =>
      currentBuildNumber == 0 || release.buildNumber > currentBuildNumber;

  /// Verificação silenciosa usada na abertura do app (deixa o pontinho no ⋮).
  static Future<ReleaseInfo?> checkSilently() async {
    try {
      final release = await fetchLatestRelease();
      return isNewer(release) ? release : null;
    } catch (_) {
      return null;
    }
  }

  static Future<File> downloadApk(
    ReleaseInfo release, {
    required void Function(int received, int total) onProgress,
  }) async {
    final url = release.apkUrl;
    if (url == null) {
      throw const HttpException('Esse release não tem APK anexado.');
    }
    final dir = await _updateDir();
    final file = File('${dir.path}/twitter-build-${release.buildNumber}.apk');
    if (await file.exists() && await file.length() > 1024 * 1024) {
      onProgress(await file.length(), await file.length());
      return file;
    }
    if (await file.exists()) {
      await file.delete();
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    IOSink? sink;
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'sorodeleite-twitter-app');
      req.followRedirects = true;
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('Download falhou (HTTP ${res.statusCode}).');
      }
      final total = res.contentLength > 0 ? res.contentLength : release.apkSize;
      var received = 0;
      var lastReport = 0;
      sink = file.openWrite();
      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastReport > 180) {
          lastReport = now;
          onProgress(received, total);
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      onProgress(received, total > 0 ? total : received);
      if (received < 1024 * 1024) {
        throw const HttpException('O APK baixado parece incompleto.');
      }
      return file;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  static Future<Directory> _updateDir() async {
    Directory base;
    try {
      base = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    } catch (_) {
      base = await getTemporaryDirectory();
    }
    final dir = Directory('${base.path}/updates');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String?> installApk(File file) async {
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type == ResultType.done) return null;
    return result.message.isEmpty ? 'Não consegui abrir o instalador.' : result.message;
  }

  static Future<void> openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir $url');
    }
  }

  static String formatSize(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  static Future<void> showUpdateDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _UpdateSheet(),
    );
  }
}

enum _Phase { checking, upToDate, available, downloading, ready, installing, error }

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet();

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  _Phase phase = _Phase.checking;
  ReleaseInfo? release;
  File? apk;
  String? error;
  int received = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      phase = _Phase.checking;
      error = null;
    });
    try {
      final info = await UpdaterService.fetchLatestRelease();
      if (!mounted) return;
      setState(() {
        release = info;
        phase = UpdaterService.isNewer(info) ? _Phase.available : _Phase.upToDate;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = _friendlyError(e);
        phase = _Phase.error;
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is SocketException) {
      return 'Sem conexão com o GitHub agora. Confira a internet e tente de novo.';
    }
    if (e is TimeoutException) {
      return 'O GitHub demorou demais para responder. Tente de novo.';
    }
    if (e is HttpException) return e.message;
    return 'Não foi possível verificar agora.\n$e';
  }

  Future<void> _download() async {
    final info = release;
    if (info == null) return;
    setState(() {
      phase = _Phase.downloading;
      received = 0;
      total = info.apkSize;
      error = null;
    });
    try {
      final file = await UpdaterService.downloadApk(
        info,
        onProgress: (r, t) {
          if (!mounted) return;
          setState(() {
            received = r;
            total = t;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        apk = file;
        phase = _Phase.ready;
      });
      await _install();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = _friendlyError(e);
        phase = _Phase.error;
      });
    }
  }

  Future<void> _install() async {
    final file = apk;
    if (file == null) return;
    setState(() => phase = _Phase.installing);
    final failure = await UpdaterService.installApk(file);
    if (!mounted) return;
    setState(() {
      if (failure == null) {
        phase = _Phase.ready;
      } else {
        error = 'O Android não abriu o instalador.\n$failure\n\n'
            'Se aparecer, permita "instalar apps desconhecidos" para o Twitter.';
        phase = _Phase.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = release;
    final current = UpdaterService.currentBuildNumber;

    final children = <Widget>[
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.system_update_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atualizar aplicativo',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text('Procura o release mais recente no GitHub',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
    ];

    if (phase == _Phase.checking) {
      children.addAll(const [
        LinearProgressIndicator(),
        SizedBox(height: 14),
        Text('Procurando a versão mais recente…', style: TextStyle(color: Colors.grey)),
      ]);
    } else if (phase == _Phase.upToDate && info != null) {
      children.addAll([
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00BA7C), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Você já está na versão mais recente ♡',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoBox(
          theme,
          'Versão instalada: ${current > 0 ? 'build #$current' : 'build local'}\n'
          'Última no GitHub: ${info.name} (${info.tagName})',
        ),
      ]);
    } else if (phase == _Phase.error) {
      children.addAll([
        _infoBox(theme, error ?? 'Erro desconhecido.', danger: true),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _check,
                child: const Text('Tentar de novo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => UpdaterService.openInBrowser(
                  info?.htmlUrl ?? UpdaterService.releasesPage,
                ),
                child: const Text('Abrir no GitHub'),
              ),
            ),
          ],
        ),
      ]);
    } else if (info != null) {
      children.addAll([
        Row(
          children: [
            const Icon(Icons.new_releases_rounded, color: Color(0xFF1D9BF0), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                UpdaterService.isNewer(info)
                    ? 'Nova versão disponível: ${info.name}'
                    : 'Release disponível: ${info.name}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _infoBox(
          theme,
          'Instalada: ${current > 0 ? 'build #$current' : 'build local'}\n'
          'No GitHub: ${info.tagName}'
          '${info.publishedAt != null ? ' · ${_dateLabel(info.publishedAt!)}' : ''}'
          '${info.apkSize > 0 ? '\nAPK: ${UpdaterService.formatSize(info.apkSize)}' : ''}',
        ),
        if (info.body.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(info.body.trim(), style: const TextStyle(fontSize: 12.5, height: 1.35)),
            ),
          ),
        ],
        if (phase == _Phase.available || phase == _Phase.ready || phase == _Phase.installing)
          const SizedBox(height: 16),
        if (phase == _Phase.available)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: info.apkUrl == null
                  ? () => UpdaterService.openInBrowser(info.htmlUrl)
                  : _download,
              icon: const Icon(Icons.download_rounded, size: 19),
              label: Text(info.apkUrl == null ? 'Abrir release no GitHub' : 'Baixar e instalar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        if (phase == _Phase.downloading) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total > 0 ? (received / total).clamp(0.0, 1.0) : null,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Text(
            total > 0
                ? 'Baixando… ${UpdaterService.formatSize(received)} de ${UpdaterService.formatSize(total)}'
                : 'Baixando… ${UpdaterService.formatSize(received)}',
            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
        ],
        if (phase == _Phase.ready || phase == _Phase.installing) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: phase == _Phase.installing ? null : _install,
              icon: phase == _Phase.installing
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.install_mobile_rounded, size: 19),
              label: Text(phase == _Phase.installing ? 'Abrindo instalador…' : 'Abrir instalador'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Se o Android avisar, permita "instalar apps desconhecidos" para o Twitter. '
            'O app é atualizado por cima, sem perder nada.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.35),
          ),
        ],
        if (phase == _Phase.available)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => UpdaterService.openInBrowser(info.htmlUrl),
              child: const Text('Ver no GitHub'),
            ),
          ),
      ]);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _infoBox(ThemeData theme, String text, {bool danger = false}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFFFFE4E6).withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 1)
              : theme.dividerColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4)),
      );

  String _dateLabel(DateTime date) {
    const months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    final local = date.toLocal();
    return '${local.day} de ${months[local.month - 1]}';
  }
}
