import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'screens/accounts_page.dart';
import 'screens/compose_page.dart';
import 'screens/dm_page.dart';
import 'screens/illit_wiki_page.dart';
import 'screens/post_detail_page.dart';
import 'screens/profile_page.dart';
import 'screens/settings_page.dart';
import 'services/bot_engine.dart';
import 'services/illit_service.dart';
import 'services/updater_service.dart';
import 'widgets/avatar_widget.dart';
import 'widgets/post_card.dart';
import 'widgets/x_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(TwitterApp(prefs: prefs));
}

class TwitterApp extends StatefulWidget {
  const TwitterApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<TwitterApp> createState() => _TwitterAppState();
}

class _TwitterAppState extends State<TwitterApp> {
  static const palette = [
    Color(0xFF1D9BF0),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFE879A8),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];

  late Color accent;
  late ThemeMode themeMode;
  late bool appleEmoji;

  @override
  void initState() {
    super.initState();
    accent = Color(widget.prefs.getInt('accent') ?? palette.first.toARGB32());
    final storedTheme = widget.prefs.getInt('themeMode') ?? ThemeMode.dark.index;
    themeMode = ThemeMode.values[
        storedTheme >= 0 && storedTheme < ThemeMode.values.length ? storedTheme : 2];
    appleEmoji = widget.prefs.getBool('appleEmoji') ?? true;
  }

  Future<void> setAccent(Color value) async {
    setState(() => accent = value);
    await widget.prefs.setInt('accent', value.toARGB32());
  }

  Future<void> setTheme(ThemeMode value) async {
    setState(() => themeMode = value);
    await widget.prefs.setInt('themeMode', value.index);
  }

  Future<void> setEmoji(bool value) async {
    setState(() => appleEmoji = value);
    await widget.prefs.setBool('appleEmoji', value);
  }

  ThemeData buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primaryText = isLight ? const Color(0xFF0F1419) : const Color(0xFFE7E9EA);
    final secondary = isLight ? const Color(0xFF536471) : const Color(0xFF71767B);
    final divider = isLight ? const Color(0xFFEFF3F4) : const Color(0xFF2F3336);
    final bg = isLight ? Colors.white : Colors.black;
    final surface = isLight ? const Color(0xFFF7F9F9) : const Color(0xFF16181C);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
        primary: accent,
        surface: bg,
      ),
      scaffoldBackgroundColor: bg,
      dividerColor: divider,
      canvasColor: bg,
      fontFamilyFallback: appleEmoji ? const ['Pooftie Apple Emoji'] : null,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: primaryText, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: primaryText),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: bg,
        showDragHandle: true,
        dragHandleColor: divider,
      ),
      dialogTheme: DialogThemeData(backgroundColor: bg),
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .white
          .apply(bodyColor: primaryText, displayColor: primaryText)
          .copyWith(
            bodyMedium: TextStyle(color: primaryText, fontSize: 14),
            bodySmall: TextStyle(color: secondary, fontSize: 12),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFEFF3F4) : const Color(0xFF202327),
        hintStyle: TextStyle(color: secondary, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: accent, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryText,
        unselectedLabelColor: secondary,
        indicatorColor: accent,
        dividerColor: divider,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.35);
          }
          return null;
        }),
      ),
    );
    return base;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Twitter',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        home: MainShell(
          prefs: widget.prefs,
          accent: accent,
          palette: palette,
          themeMode: themeMode,
          appleEmoji: appleEmoji,
          onAccentChanged: setAccent,
          onThemeChanged: setTheme,
          onEmojiChanged: setEmoji,
        ),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.prefs,
    required this.accent,
    required this.palette,
    required this.themeMode,
    required this.appleEmoji,
    required this.onAccentChanged,
    required this.onThemeChanged,
    required this.onEmojiChanged,
  });

  final SharedPreferences prefs;
  final Color accent;
  final List<Color> palette;
  final ThemeMode themeMode;
  final bool appleEmoji;
  final ValueChanged<Color> onAccentChanged;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<bool> onEmojiChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  static const _tabs = ['Início', 'Buscar', 'Notificações', 'Mensagens', 'Perfil'];

  int tab = 0;
  late final TabController _homeTabs = TabController(length: 2, vsync: this);
  final searchController = TextEditingController();
  final _rng = Random();
  final List<Timer> _timers = [];

  final List<Account> accounts = [];
  final List<Post> posts = [];
  final List<AppNotification> notifications = [];
  final Map<String, List<DmMessage>> dmThreads = {};

  bool refreshingIllit = false;
  bool _hideUpdateBanner = false;
  ReleaseInfo? updateAvailable;
  Timer? _illitTimer;

  Account get meAccount {
    if (accounts.isEmpty) return BotEngine.defaultAccounts().first;
    return accounts.firstWhere((a) => a.isMe, orElse: () => accounts.first);
  }

  Account get illitAccount {
    if (accounts.isEmpty) return BotEngine.defaultAccounts().first;
    return accounts.firstWhere((a) => a.isIllit, orElse: () => accounts.first);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkForUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshIllit(silent: true);
    });
    _illitTimer = Timer.periodic(const Duration(minutes: 25), (_) {
      if (!mounted) return;
      _refreshIllit(silent: true);
    });
  }

  @override
  void dispose() {
    _illitTimer?.cancel();
    for (final timer in _timers) {
      timer.cancel();
    }
    _homeTabs.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- dados

  void _loadData() {
    accounts.clear();
    posts.clear();
    notifications.clear();
    dmThreads.clear();

    final rawAccounts = widget.prefs.getString('accounts_v3');
    if (rawAccounts != null) {
      try {
        accounts.addAll((jsonDecode(rawAccounts) as List)
            .map((e) => Account.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    if (accounts.isEmpty) {
      accounts.addAll(BotEngine.defaultAccounts());
    }
    // garante que eu e o ILLIT sempre existam
    if (!accounts.any((a) => a.isMe)) {
      accounts.insert(0, BotEngine.defaultAccounts().first);
    }
    if (!accounts.any((a) => a.isIllit)) {
      accounts.add(BotEngine.defaultAccounts()[1]);
    }

    final rawPosts = widget.prefs.getString('posts_v3');
    if (rawPosts != null) {
      try {
        posts.addAll((jsonDecode(rawPosts) as List)
            .map((e) => Post.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    if (posts.isEmpty) {
      _seedTimeline();
    }

    final rawNotifications = widget.prefs.getString('notifications_v3');
    if (rawNotifications != null) {
      try {
        notifications.addAll((jsonDecode(rawNotifications) as List)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    if (notifications.isEmpty) {
      notifications.add(AppNotification(
        id: 'notif-welcome',
        type: 'follow',
        fromName: illitAccount.name,
        fromHandle: illitAccount.handle,
        fromAvatarEmoji: illitAccount.avatarEmoji,
        fromAvatarPath: illitAccount.avatarPath,
        postId: '',
        preview: 'A conta de atualizações reais do ILLIT te seguiu e já postou a ficha do grupo ♡',
        createdAtMs: DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 20,
      ));
    }

    final rawDms = widget.prefs.getString('dms_v3');
    if (rawDms != null) {
      try {
        final map = jsonDecode(rawDms) as Map<String, dynamic>;
        map.forEach((key, value) {
          dmThreads[key] = (value as List)
              .map((e) => DmMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } catch (_) {}
    }

    _sortTimeline();
  }

  void _seedTimeline() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final neville = accounts.firstWhere((a) => a.id == 'neville', orElse: () => accounts.first);
    final mimi = accounts.firstWhere((a) => a.id == 'friend-1', orElse: () => accounts.first);

    posts.addAll(IllitService.initialSeedPosts(illitAccount));
    posts.addAll([
      Post(
        id: 'neville-welcome',
        accountId: neville.id,
        name: neville.name,
        handle: neville.handle,
        avatarEmoji: neville.avatarEmoji,
        avatarPath: neville.avatarPath,
        verified: neville.verified,
        isBot: true,
        text: 'lembrete do dia: revise qualquer cena que não combine com a sua vida ideal. '
            'a imaginação é a única realidade ♡\n\n#VidaRevisada',
        createdAtMs: now - 1000 * 60 * 35,
        likes: 312,
        reposts: 88,
        views: 2400,
      ),
      Post(
        id: 'mimi-welcome',
        accountId: mimi.id,
        name: mimi.name,
        handle: mimi.handle,
        avatarEmoji: mimi.avatarEmoji,
        avatarPath: mimi.avatarPath,
        text: 'isso aqui vai virar meu cantinho favorito da internet 🥺♡',
        createdAtMs: now - 1000 * 60 * 48,
        likes: 23,
        views: 140,
      ),
    ]);
    _saveAll();
  }

  Future<void> _saveAll() async {
    await widget.prefs.setString(
        'accounts_v3', jsonEncode(accounts.map((a) => a.toJson()).toList()));
    await widget.prefs.setString(
        'posts_v3', jsonEncode(posts.map((p) => p.toJson()).toList()));
    await widget.prefs.setString('notifications_v3',
        jsonEncode(notifications.map((n) => n.toJson()).toList()));
    final dmJson = <String, dynamic>{};
    dmThreads.forEach((key, value) {
      dmJson[key] = value.map((m) => m.toJson()).toList();
    });
    await widget.prefs.setString('dms_v3', jsonEncode(dmJson));
  }

  void _changed() {
    if (mounted) setState(() {});
    _saveAll();
  }

  void _sortTimeline() {
    posts.sort(_timelineOrder);
  }

  // ------------------------------------------------------------- atualizar

  Future<void> _checkForUpdates() async {
    final release = await UpdaterService.checkSilently();
    if (!mounted || release == null) return;
    setState(() => updateAvailable = release);
  }

  Future<void> _refreshIllit({bool silent = false}) async {
    if (refreshingIllit) return;
    setState(() => refreshingIllit = true);
    try {
      final fetched = await IllitService.fetchLiveUpdates(illitAccount);
      if (!mounted) return;
      final existing = posts.map((p) => p.id).toSet();
      final fresh = fetched.where((p) => !existing.contains(p.id)).toList();
      if (fresh.isNotEmpty) {
        setState(() {
          posts.insertAll(0, fresh);
          _sortTimeline();
          notifications.insert(
            0,
            AppNotification(
              id: 'notif-illit-${DateTime.now().microsecondsSinceEpoch}',
              type: 'update',
              fromName: illitAccount.name,
              fromHandle: illitAccount.handle,
              fromAvatarEmoji: illitAccount.avatarEmoji,
              fromAvatarPath: illitAccount.avatarPath,
              postId: fresh.first.id,
              preview: fresh.first.text.split('\n').where((l) => l.trim().isNotEmpty).last,
              createdAtMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        });
        _saveAll();
      }
      if (!silent && mounted) {
        _toast(fresh.isNotEmpty
            ? 'ILLIT Updates: ${fresh.length} novidade(s) real(is) adicionada(s) ♡'
            : 'ILLIT Updates já está em dia ♡');
      }
    } catch (_) {
      if (!silent && mounted) _toast('Não consegui buscar as novidades do ILLIT agora.');
    } finally {
      if (mounted) setState(() => refreshingIllit = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // --------------------------------------------------------------- posts

  void _addPost(Account author, String text, {String? imagePath, Post? replyTo}) {
    if (text.trim().isEmpty && imagePath == null) return;
    final newPost = Post(
      id: 'post-${DateTime.now().microsecondsSinceEpoch}',
      accountId: author.id,
      name: author.name,
      handle: author.handle,
      avatarEmoji: author.avatarEmoji,
      avatarPath: author.avatarPath,
      verified: author.verified,
      isBot: author.isBot,
      text: text.trim(),
      image: imagePath,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      views: 1,
      replyToId: replyTo?.id,
    );
    setState(() {
      posts.insert(0, newPost);
      _sortTimeline();
      tab = 0;
    });
    _saveAll();

    if (author.isMe) {
      _scheduleBotReactions(newPost);
    }
  }

  void _scheduleBotReactions(Post post) {
    final responders = accounts
        .where((a) => !a.isMe && a.autoInteract)
        .toList()
      ..shuffle(_rng);
    final selected = responders.take(min(4, responders.length)).toList();

    for (var i = 0; i < selected.length; i++) {
      final account = selected[i];
      final timer = Timer(BotEngine.reactionDelay(i), () {
        if (!mounted || !posts.contains(post)) return;
        final willReply = i == 0 || _rng.nextDouble() < 0.45;
        final willRepost = i == 1 && _rng.nextBool();
        setState(() {
          post.likes += 1;
          post.views += 6 + _rng.nextInt(18);
          notifications.insert(
            0,
            AppNotification(
              id: 'notif-like-${DateTime.now().microsecondsSinceEpoch}-$i',
              type: 'like',
              fromName: account.name,
              fromHandle: account.handle,
              fromAvatarEmoji: account.avatarEmoji,
              fromAvatarPath: account.avatarPath,
              postId: post.id,
              preview: post.text,
              createdAtMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          if (willReply) {
            final replyText = BotEngine.generateReply(account, post);
            post.replies.add(Reply(
              id: 'rep-${DateTime.now().microsecondsSinceEpoch}',
              accountId: account.id,
              name: account.name,
              handle: account.handle,
              avatarEmoji: account.avatarEmoji,
              avatarPath: account.avatarPath,
              verified: account.verified,
              text: replyText,
              createdAtMs: DateTime.now().millisecondsSinceEpoch,
            ));
            notifications.insert(
              0,
              AppNotification(
                id: 'notif-reply-${DateTime.now().microsecondsSinceEpoch}',
                type: 'reply',
                fromName: account.name,
                fromHandle: account.handle,
                fromAvatarEmoji: account.avatarEmoji,
                fromAvatarPath: account.avatarPath,
                postId: post.id,
                preview: replyText,
                createdAtMs: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }
          if (willRepost) {
            post.reposts += 1;
            notifications.insert(
              0,
              AppNotification(
                id: 'notif-repost-${DateTime.now().microsecondsSinceEpoch}',
                type: 'repost',
                fromName: account.name,
                fromHandle: account.handle,
                fromAvatarEmoji: account.avatarEmoji,
                fromAvatarPath: account.avatarPath,
                postId: post.id,
                preview: post.text,
                createdAtMs: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }
        });
        _saveAll();
      });
      _timers.add(timer);
    }
  }

  Future<void> _postAction(Post post, String action) async {
    switch (action) {
      case 'Editar':
        final controller = TextEditingController(text: post.text);
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Editar post'),
            content: TextField(
              controller: controller,
              maxLines: 8,
              minLines: 4,
              decoration: const InputDecoration(hintText: 'O que você quer mudar?'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
        controller.dispose();
        if (result != null && mounted) {
          setState(() => post.text = result.trim());
          _saveAll();
        }
        break;
      case 'Excluir':
        final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir post?'),
            content: const Text('Essa ação não pode ser desfeita.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
            ],
          ),
        );
        if (yes == true && mounted) {
          setState(() => posts.removeWhere((p) => p.id == post.id));
          _saveAll();
        }
        break;
      case 'Fixar':
      case 'Desafixar':
        setState(() {
          post.pinned = !post.pinned;
          if (post.pinned) {
            for (final other in posts) {
              if (other.accountId == post.accountId && other.id != post.id) {
                other.pinned = false;
              }
            }
          }
          _sortTimeline();
        });
        _saveAll();
        break;
      case 'Copiar':
        _copyPost(post);
        break;
      case 'Compartilhar':
        _copyPost(post, share: true);
        break;
    }
  }

  Future<void> _copyPost(Post post, {bool share = false}) async {
    await Clipboard.setData(
      ClipboardData(
        text: '${post.name} ${post.handle}\n${post.text}'
            '${post.linkUrl != null ? '\n${post.linkUrl}' : ''}',
      ),
    );
    if (!mounted) return;
    _toast(share ? 'Texto copiado para compartilhar ♡' : 'Post copiado ♡');
  }

  // ---------------------------------------------------------- navegação

  void _openThread(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          post: post,
          accounts: accounts,
          meAccount: meAccount,
          onChanged: _changed,
          onOpenProfile: _openProfilePage,
        ),
      ),
    );
  }

  void _openProfilePage(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          account: account,
          allPosts: posts,
          accounts: accounts,
          isEmbeddedTab: false,
          onAccountUpdated: _changed,
          onPostsChanged: _changed,
          onPostAction: _postAction,
          onOpenThread: _openThread,
          onOpenProfile: _openProfilePage,
          onOpenDm: (acc) {
            Navigator.pop(context);
            _openDmChat(acc);
          },
          onOpenIllitWiki: () => _openIllitWiki(),
        ),
      ),
    );
  }

  void _openProfileForPost(Post post) {
    final target = accounts.firstWhere(
      (a) => a.id == post.accountId || a.handle == post.handle,
      orElse: () => meAccount,
    );
    _openProfilePage(target);
  }

  void _openDmChat(Account account) {
    dmThreads.putIfAbsent(account.id, () => []);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DmChatPage(
          account: account,
          messages: dmThreads[account.id]!,
          onChanged: _changed,
        ),
      ),
    );
  }

  void _openAccountsManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountsPage(
          accounts: accounts,
          onAccountsChanged: _changed,
          onPostAsAccount: (account) => _openComposer(initialAccount: account),
          onOpenProfile: _openProfilePage,
        ),
      ),
    );
  }

  void _openIllitWiki() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IllitWikiPage(
          account: illitAccount,
          posts: posts,
          onOpenPost: _openThread,
          onRefresh: () => _refreshIllit(silent: false),
          onChanged: _changed,
          onAction: _postAction,
          onOpenProfile: _openProfilePage,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          themeMode: widget.themeMode,
          accent: widget.accent,
          palette: widget.palette,
          appleEmoji: widget.appleEmoji,
          onThemeChanged: widget.onThemeChanged,
          onAccentChanged: widget.onAccentChanged,
          onEmojiChanged: widget.onEmojiChanged,
          onResetData: _resetData,
        ),
      ),
    );
  }

  void _openBookmarks() {
    final saved = posts.where((p) => p.bookmarked).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Itens salvos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ),
          body: saved.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('Nenhum post salvo ainda ♡\nToque no marcador de um post.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.builder(
                  itemCount: saved.length,
                  itemBuilder: (_, i) => PostCard(
                    post: saved[i],
                    onChanged: _changed,
                    onAction: (action) => _postAction(saved[i], action),
                    onOpenThread: () => _openThread(saved[i]),
                    onOpenProfile: () => _openProfileForPost(saved[i]),
                  ),
                ),
        ),
      ),
    );
  }

  void _openComposer({Account? initialAccount}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposePage(
          accounts: accounts,
          initialAccount: initialAccount ?? meAccount,
          onSubmit: (author, text, imagePath) =>
              _addPost(author, text, imagePath: imagePath),
        ),
      ),
    );
  }

  void _showMainMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.system_update_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    if (updateAvailable != null)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFFF91880), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                title: const Text('Atualizar aplicativo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  updateAvailable != null
                      ? 'Nova versão disponível (${updateAvailable!.tagName})'
                      : 'Procura o release mais recente no GitHub',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  UpdaterService.showUpdateDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('Atualizar ILLIT agora'),
                subtitle: const Text('Notícias, vídeos e lançamentos reais',
                    style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _refreshIllit(silent: false);
                },
              ),
              const Divider(height: 8),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Contas & bots'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAccountsManager();
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Enciclopédia ILLIT'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openIllitWiki();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded),
                title: const Text('Itens salvos'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBookmarks();
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Aparência'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSettings();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetData() async {
    for (final key in ['accounts_v3', 'posts_v3', 'notifications_v3', 'dms_v3']) {
      await widget.prefs.remove(key);
    }
    if (!mounted) return;
    setState(() {
      updateAvailable = null;
      _loadData();
      tab = 0;
    });
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final unread = notifications.where((n) => !n.read).length;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: AvatarWidget(
            emoji: meAccount.avatarEmoji,
            imagePath: meAccount.avatarPath,
            radius: 16,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        titleSpacing: 0,
        centerTitle: tab == 0,
        title: tab == 0
            ? const XLogo(size: 24)
            : Text(_tabs[tab]),
        actions: [
          if (refreshingIllit)
            const Padding(
              padding: EdgeInsets.only(right: 2),
              child: SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            tooltip: 'Menu',
            onPressed: _showMainMenu,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.more_vert_rounded),
                if (updateAvailable != null)
                  Positioned(
                    right: -1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF91880), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: tab == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(46),
                child: Column(
                  children: [
                    TabBar(
                      controller: _homeTabs,
                      tabs: const [
                        Tab(text: 'Para você'),
                        Tab(text: 'Seguindo'),
                      ],
                    ),
                    Divider(height: 0.6, thickness: 0.6, color: theme.dividerColor),
                  ],
                ),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(0.6),
                child: Divider(height: 0.6, thickness: 0.6, color: theme.dividerColor),
              ),
      ),
      drawer: _buildDrawer(theme, secondary, accent),
      body: IndexedStack(
        index: tab,
        children: [
          TabBarView(
            controller: _homeTabs,
            children: [
              _buildFeed(_forYouPosts(), 'home-for-you'),
              _buildFeed(_followingPosts(), 'home-following'),
            ],
          ),
          _SearchTab(
            posts: posts,
            accounts: accounts,
            controller: searchController,
            onChanged: _changed,
            onAction: _postAction,
            onOpenThread: _openThread,
            onOpenProfile: _openProfilePage,
            onOpenPostProfile: _openProfileForPost,
          ),
          _NotificationsTab(
            notifications: notifications,
            posts: posts,
            onOpenThread: _openThread,
            onMarkRead: () {
              setState(() {
                for (final n in notifications) {
                  n.read = true;
                }
              });
              _saveAll();
            },
          ),
          MessagesPage(
            accounts: accounts,
            threads: dmThreads,
            onOpenChat: _openDmChat,
          ),
          ProfilePage(
            account: meAccount,
            allPosts: posts,
            accounts: accounts,
            onAccountUpdated: _changed,
            onPostsChanged: _changed,
            onPostAction: _postAction,
            onOpenThread: _openThread,
            onOpenProfile: _openProfilePage,
            onOpenIllitWiki: _openIllitWiki,
          ),
        ],
      ),
      floatingActionButton: tab == 0 || tab == 4
          ? FloatingActionButton(
              onPressed: () => _openComposer(),
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              tooltip: 'Postar',
              child: const Icon(Icons.edit_rounded, size: 24),
            )
          : null,
      bottomNavigationBar: _buildNavBar(theme, secondary, unread),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Post> _forYouPosts() {
    final list = [...posts]..sort(_timelineOrder);
    return list;
  }

  List<Post> _followingPosts() {
    final ids = accounts
        .where((a) => a.isMe || a.isFriend || a.isIllit)
        .map((a) => a.id)
        .toSet();
    final handles = accounts
        .where((a) => a.isMe || a.isFriend || a.isIllit)
        .map((a) => a.handle)
        .toSet();
    final list = posts
        .where((p) => ids.contains(p.accountId) || handles.contains(p.handle))
        .toList()
      ..sort(_timelineOrder);
    return list;
  }

  int _timelineOrder(Post a, Post b) {
    final pinned = (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0);
    if (pinned != 0) return pinned;
    return b.createdAtMs.compareTo(a.createdAtMs);
  }

  Widget _buildFeed(List<Post> list, String storageKey) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => _refreshIllit(silent: false),
      child: ListView.builder(
        key: PageStorageKey(storageKey),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length + (updateAvailable != null && !_hideUpdateBanner ? 1 : 0),
        itemBuilder: (context, index) {
          var offset = 0;
          if (updateAvailable != null && !_hideUpdateBanner) {
            if (index == 0) return _updateBanner();
            offset = 1;
          }
          final post = list[index - offset];
          return PostCard(
            post: post,
            onChanged: _changed,
            onAction: (action) => _postAction(post, action),
            onOpenThread: () => _openThread(post),
            onOpenProfile: () => _openProfileForPost(post),
          );
        },
      ),
    );
  }

  Widget _updateBanner() {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update_rounded, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nova versão do app disponível',
                    style: TextStyle(fontWeight: FontWeight.w800, color: accent, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${updateAvailable!.name} · toque para baixar e instalar',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFFE7E9EA)
                        : const Color(0xFF0F1419),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => UpdaterService.showUpdateDialog(context),
            child: const Text('Atualizar'),
          ),
          IconButton(
            tooltip: 'Agora não',
            icon: const Icon(Icons.close, size: 17),
            onPressed: () => setState(() => _hideUpdateBanner = true),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(ThemeData theme, Color secondary, int unread) {
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, 'Início'),
      (Icons.search_rounded, Icons.search_rounded, 'Buscar'),
      (Icons.notifications_none_rounded, Icons.notifications_rounded, 'Notificações'),
      (Icons.mail_outline_rounded, Icons.mail_rounded, 'Mensagens'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.6)),
        color: theme.scaffoldBackgroundColor,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (i == 2 && unread > 0) {
                        setState(() {
                          tab = 2;
                          for (final n in notifications) {
                            n.read = true;
                          }
                        });
                        _saveAll();
                      } else {
                        setState(() => tab = i);
                      }
                    },
                    child: Tooltip(
                      message: items[i].$3,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            tab == i ? items[i].$2 : items[i].$1,
                            size: 26,
                            color: tab == i
                                ? (isDark ? Colors.white : Colors.black)
                                : secondary,
                          ),
                          if (i == 2 && unread > 0)
                            Positioned(
                              top: 8,
                              right: 22,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                constraints: const BoxConstraints(minWidth: 15),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: theme.scaffoldBackgroundColor, width: 1.4),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, Color secondary, Color accent) {
    final me = meAccount;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                setState(() => tab = 4);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarWidget(
                          emoji: me.avatarEmoji,
                          imagePath: me.avatarPath,
                          radius: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      me.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800, fontSize: 17),
                                    ),
                                  ),
                                  if (me.verified) ...[
                                    const SizedBox(width: 3),
                                    VerifiedBadge(size: 15),
                                  ],
                                ],
                              ),
                              Text(me.handle,
                                  style: TextStyle(color: secondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${formatCount(me.followingCount)} Seguindo   ${formatCount(me.followersCount)} Seguidores',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _drawerItem(Icons.person_outline_rounded, 'Perfil', () {
              Navigator.pop(context);
              setState(() => tab = 4);
            }),
            _drawerItem(Icons.group_outlined, 'Contas & bots', () {
              Navigator.pop(context);
              _openAccountsManager();
            }),
            _drawerItem(Icons.menu_book_outlined, 'Enciclopédia ILLIT', () {
              Navigator.pop(context);
              _openIllitWiki();
            }),
            _drawerItem(Icons.bookmark_border_rounded, 'Itens salvos', () {
              Navigator.pop(context);
              _openBookmarks();
            }),
            _drawerItem(Icons.system_update_rounded, 'Atualizar aplicativo', () {
              Navigator.pop(context);
              UpdaterService.showUpdateDialog(context);
            }, trailing: updateAvailable != null ? 'nova' : null),
            _drawerItem(Icons.settings_outlined, 'Configurações', () {
              Navigator.pop(context);
              _openSettings();
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('sua vida revisada ♡',
                      style: TextStyle(
                          color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    UpdaterService.currentBuildNumber > 0
                        ? 'build #${UpdaterService.currentBuildNumber}'
                        : 'build local',
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {String? trailing}) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      trailing: trailing == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trailing,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------- abas

class _SearchTab extends StatefulWidget {
  const _SearchTab({
    required this.posts,
    required this.accounts,
    required this.controller,
    required this.onChanged,
    required this.onAction,
    required this.onOpenThread,
    required this.onOpenProfile,
    required this.onOpenPostProfile,
  });

  final List<Post> posts;
  final List<Account> accounts;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final void Function(Post, String) onAction;
  final void Function(Post) onOpenThread;
  final void Function(Account) onOpenProfile;
  final void Function(Post) onOpenPostProfile;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? const Color(0xFF71767B)
        : const Color(0xFF536471);
    final q = query.trim().toLowerCase();

    final matchedPosts = q.isEmpty
        ? <Post>[]
        : widget.posts
            .where((p) => '${p.name} ${p.handle} ${p.text}'.toLowerCase().contains(q))
            .toList();
    final matchedAccounts = q.isEmpty
        ? <Account>[]
        : widget.accounts
            .where((a) =>
                '${a.name} ${a.handle} ${a.bio}'.toLowerCase().contains(q))
            .toList();

    final hashtags = <String, int>{};
    for (final p in widget.posts) {
      for (final m in RegExp(r'#([\w\u00C0-\u017F]{2,})').allMatches(p.text)) {
        final tag = m.group(1)!;
        hashtags[tag] = (hashtags[tag] ?? 0) + 1;
      }
    }
    final trends = hashtags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final trendList = trends.take(6).toList();
    const fallback = ['ILLIT', 'Moka', 'VidaRevisada', 'GLLIT', 'Neville', 'Magnetic'];

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: TextField(
            controller: widget.controller,
            onChanged: (value) => setState(() => query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Buscar no Twitter',
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() => query = '');
                      },
                    ),
            ),
          ),
        ),
        if (q.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: const Text('Assuntos do momento',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          for (var i = 0; i < (trendList.isEmpty ? fallback.length : trendList.length); i++)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                '#${trendList.isEmpty ? fallback[i] : trendList[i].key}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: Text(
                trendList.isEmpty
                    ? 'Explorar publicações'
                    : '${trendList[i].value} ${trendList[i].value == 1 ? 'post' : 'posts'} na sua timeline',
                style: TextStyle(fontSize: 12.5, color: secondary),
              ),
              trailing: Icon(Icons.more_horiz_rounded, size: 18, color: secondary),
              onTap: () {
                final term = trendList.isEmpty ? fallback[i] : trendList[i].key;
                widget.controller.text = term;
                setState(() => query = term);
              },
            ),
          const Divider(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: const Text('Quem seguir',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          for (final account in widget.accounts.where((a) => !a.isMe))
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: AvatarWidget(
                emoji: account.avatarEmoji,
                imagePath: account.avatarPath,
                radius: 21,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(account.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  if (account.verified) ...[
                    const SizedBox(width: 3),
                    VerifiedBadge(size: 14),
                  ],
                ],
              ),
              subtitle: Text(account.handle,
                  style: TextStyle(fontSize: 12.5, color: secondary)),
              trailing: FilledButton(
                onPressed: () => widget.onOpenProfile(account),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  foregroundColor:
                      theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ver', style: TextStyle(fontSize: 13)),
              ),
              onTap: () => widget.onOpenProfile(account),
            ),
        ] else ...[
          if (matchedAccounts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Text('Pessoas',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: secondary)),
            ),
            for (final account in matchedAccounts.take(4))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: AvatarWidget(
                  emoji: account.avatarEmoji,
                  imagePath: account.avatarPath,
                  radius: 19,
                ),
                title: Text(account.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(account.handle),
                onTap: () => widget.onOpenProfile(account),
              ),
            Divider(height: 18, color: theme.dividerColor),
          ],
          if (matchedPosts.isEmpty && matchedAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('Nenhum resultado encontrado.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          for (final post in matchedPosts)
            PostCard(
              post: post,
              onChanged: widget.onChanged,
              onAction: (action) => widget.onAction(post, action),
              onOpenThread: () => widget.onOpenThread(post),
              onOpenProfile: () => widget.onOpenPostProfile(post),
            ),
        ],
        const SizedBox(height: 12),
        Center(
          child: Text('Busca local, só no seu Twitter ♡',
              style: TextStyle(fontSize: 11.5, color: secondary)),
        ),
      ],
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab({
    required this.notifications,
    required this.posts,
    required this.onOpenThread,
    required this.onMarkRead,
  });

  final List<AppNotification> notifications;
  final List<Post> posts;
  final void Function(Post) onOpenThread;
  final VoidCallback onMarkRead;

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool onlyMentions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final secondary = theme.brightness == Brightness.dark
        ? const Color(0xFF71767B)
        : const Color(0xFF536471);

    final list = widget.notifications
        .where((n) => !onlyMentions || n.type == 'reply')
        .toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Tudo'),
                selected: !onlyMentions,
                onSelected: (_) => setState(() => onlyMentions = false),
                showCheckmark: false,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Menções'),
                selected: onlyMentions,
                onSelected: (_) => setState(() => onlyMentions = true),
                showCheckmark: false,
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 40, color: secondary),
                        const SizedBox(height: 12),
                        Text(
                          'Quando suas amigas, os bots ou o ILLIT curtirem, repostarem e '
                          'responderem seus tweets, tudo aparece aqui ♡',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 0.6, thickness: 0.6, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final n = list[index];
                    final post = widget.posts.where((p) => p.id == n.postId).firstOrNull;
                    return InkWell(
                      onTap: () {
                        widget.onMarkRead();
                        if (post != null) widget.onOpenThread(post);
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_iconFor(n.type), color: _colorFor(n.type, accent), size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AvatarWidget(
                                        emoji: n.fromAvatarEmoji,
                                        imagePath: n.fromAvatarPath,
                                        radius: 13,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _titleFor(n),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                      ),
                                      if (!n.read)
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        formatRelativeTime(n.createdAtMs),
                                        style: TextStyle(color: secondary, fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (n.preview.trim().isNotEmpty)
                                    Text(
                                      n.preview,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'reply':
        return Icons.chat_bubble_rounded;
      case 'repost':
        return Icons.repeat_rounded;
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'update':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  Color _colorFor(String type, Color accent) {
    switch (type) {
      case 'reply':
        return accent;
      case 'repost':
        return const Color(0xFF00BA7C);
      case 'follow':
        return accent;
      case 'update':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFF91880);
    }
  }

  String _titleFor(AppNotification n) {
    switch (n.type) {
      case 'reply':
        return '${n.fromName} respondeu você';
      case 'repost':
        return '${n.fromName} repostou seu post';
      case 'follow':
        return '${n.fromName} te seguiu';
      case 'update':
        return '${n.fromName} postou';
      default:
        return '${n.fromName} curtiu seu post';
    }
  }
}

