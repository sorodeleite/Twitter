import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TwitterApp(prefs: await SharedPreferences.getInstance()));
}

class TwitterApp extends StatefulWidget {
  const TwitterApp({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  State<TwitterApp> createState() => _TwitterAppState();
}

class _TwitterAppState extends State<TwitterApp> {
  static const palette = [Color(0xFF1D9BF0), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFE879A8), Color(0xFF14B8A6), Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFF64748B), Color(0xFF111827)];
  late Color accent;
  late ThemeMode themeMode;
  late bool appleEmoji;
  @override
  void initState() {
    super.initState();
    accent = Color(widget.prefs.getInt('accent') ?? palette.first.toARGB32());
    themeMode = ThemeMode.values[widget.prefs.getInt('themeMode') ?? 0];
    appleEmoji = widget.prefs.getBool('appleEmoji') ?? true;
  }
  Future<void> setAccent(Color value) async { setState(() => accent = value); await widget.prefs.setInt('accent', value.toARGB32()); }
  Future<void> setTheme(ThemeMode value) async { setState(() => themeMode = value); await widget.prefs.setInt('themeMode', value.index); }
  Future<void> setEmoji(bool value) async { setState(() => appleEmoji = value); await widget.prefs.setBool('appleEmoji', value); }
  ThemeData buildTheme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness),
    scaffoldBackgroundColor: brightness == Brightness.light ? Colors.white : Colors.black,
    dividerColor: brightness == Brightness.light ? const Color(0xFFE7E7E7) : const Color(0xFF2F3336),
    fontFamilyFallback: appleEmoji ? const ['Pooftie Apple Emoji'] : null,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light ? const Color(0xFFF1F3F5) : const Color(0xFF202327),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
    ),
  );
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Twitter',
    theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark), themeMode: themeMode,
    home: MainShell(prefs: widget.prefs, accent: accent, palette: palette, themeMode: themeMode,
      appleEmoji: appleEmoji, onAccentChanged: setAccent, onThemeChanged: setTheme, onEmojiChanged: setEmoji),
  );
}

class Post {
  Post({required this.id, required this.name, required this.handle, required this.avatar, required this.text, required this.time, this.verified = false, this.image, this.likes = 0, this.reposts = 0, this.replies = 0, this.isBot = false, this.pinned = false});
  final String id;
  String name, handle, avatar, text, time;
  bool verified, isBot, pinned;
  String? image;
  int likes, reposts, replies;
  bool liked = false, reposted = false;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'handle': handle, 'avatar': avatar, 'text': text, 'time': time, 'verified': verified, 'image': image, 'likes': likes, 'reposts': reposts, 'replies': replies, 'isBot': isBot, 'pinned': pinned, 'liked': liked, 'reposted': reposted};
  factory Post.fromJson(Map<String, dynamic> j) {
    final p = Post(id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: j['name'] as String? ?? 'Conta', handle: j['handle'] as String? ?? '@conta',
      avatar: j['avatar'] as String? ?? '♡', text: j['text'] as String? ?? '',
      time: j['time'] as String? ?? 'agora', verified: j['verified'] as bool? ?? false,
      image: j['image'] as String?, likes: j['likes'] as int? ?? 0, reposts: j['reposts'] as int? ?? 0,
      replies: j['replies'] as int? ?? 0, isBot: j['isBot'] as bool? ?? false, pinned: j['pinned'] as bool? ?? false);
    p.liked = j['liked'] as bool? ?? false;
    p.reposted = j['reposted'] as bool? ?? false;
    return p;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.prefs, required this.accent, required this.palette, required this.themeMode, required this.appleEmoji, required this.onAccentChanged, required this.onThemeChanged, required this.onEmojiChanged});
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

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final posts = <Post>[
    Post(id: 'illit-welcome', name: 'ILLIT Updates', handle: '@illitupdates', avatar: '✧', text: 'Seu cantinho de atualizações do ILLIT ♡ Notícias, agendas e momentos das meninas.', time: '2 min', verified: true, isBot: true, likes: 128),
    Post(id: 'njz-welcome', name: 'NJZ Daily', handle: '@njzdaily', avatar: '🐰', text: 'Um lugar para acompanhar as novidades e guardar os momentos das meninas. ♡', time: '18 min', verified: true, isBot: true, likes: 94),
    Post(id: 'mimi-welcome', name: 'mimi', handle: '@mimisworld', avatar: '୨ৎ', text: 'isso aqui vai virar meu cantinho favorito da internet', time: '32 min', likes: 23, replies: 4),
    Post(id: 'pop-welcome', name: 'pop updates', handle: '@popdiary', avatar: '♡', text: 'Música, novidades e tudo o que acontece pelo caminho.', time: '1 h', isBot: true, likes: 61),
  ];
  final searchController = TextEditingController();
  final picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    final raw = widget.prefs.getString('timeline_posts');
    if (raw != null) {
      try { posts..clear()..addAll((jsonDecode(raw) as List).map((e) => Post.fromJson(e as Map<String, dynamic>))); } catch (_) {}
    }
  }
  @override
  void dispose() { searchController.dispose(); super.dispose(); }
  Future<void> savePosts() async { await widget.prefs.setString('timeline_posts', jsonEncode(posts.map((p) => p.toJson()).toList())); }
  void changed() { if (mounted) setState(() {}); savePosts(); }
  void addPost(String text, {String? imagePath}) {
    if (text.trim().isEmpty && imagePath == null) return;
    setState(() {
      posts.insert(0, Post(id: DateTime.now().microsecondsSinceEpoch.toString(), name: 'Angel', handle: '@angel', avatar: '♡', text: text.trim(), time: 'agora', image: imagePath));
      tab = 0;
    });
    savePosts();
  }
  @override
  Widget build(BuildContext context) {
    final titles = ['Início', 'Buscar', 'Notificações', 'Mensagens', 'Perfil'];
    final pages = [
      HomePage(posts: posts, onChanged: changed, onAction: postAction),
      SearchPage(posts: posts, controller: searchController),
      const EmptyPage(icon: Icons.notifications_none_rounded, title: 'Notificações', message: 'Você está em dia! As novas atividades vão aparecer aqui.'),
      const EmptyPage(icon: Icons.mail_outline_rounded, title: 'Mensagens', message: 'Suas conversas vão aparecer aqui.'),
      ProfilePage(posts: posts, onChanged: changed, onAction: postAction),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded), tooltip: 'Abrir menu', onPressed: () => Scaffold.of(context).openDrawer())),
        title: Text(tab == 0 ? '𝕏' : titles[tab], style: TextStyle(fontWeight: FontWeight.w900, fontSize: tab == 0 ? 27 : 20, color: tab == 0 ? widget.accent : null)),
        actions: [
          if (tab == 0) IconButton(tooltip: 'Buscar', icon: const Icon(Icons.search_rounded), onPressed: () => setState(() => tab = 1)),
          if (tab == 0) IconButton(tooltip: 'Aparência', icon: const Icon(Icons.tune_rounded), onPressed: appearance),
        ],
      ),
      drawer: Drawer(child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 27, backgroundColor: widget.accent.withValues(alpha: .14), child: Text('♡', style: TextStyle(color: widget.accent, fontSize: 26))),
          const SizedBox(height: 12), const Text('Angel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Text('@angel', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12), const Text('0 seguindo     0 seguidores', style: TextStyle(fontSize: 12)),
        ])),
        const Divider(),
        _DrawerItem(icon: Icons.person_outline, label: 'Perfil', onTap: () => selectTab(4)),
        _DrawerItem(icon: Icons.bookmark_border, label: 'Itens salvos', onTap: () => selectTab(0)),
        _DrawerItem(icon: Icons.list_alt_rounded, label: 'Listas', onTap: () => selectTab(0)),
        _DrawerItem(icon: Icons.palette_outlined, label: 'Aparência', onTap: appearance),
        _DrawerItem(icon: Icons.settings_outlined, label: 'Configurações', onTap: appearance),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(18), child: Text('Um cantinho seu na internet ♡', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600))),
      ]))),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 0 ? FloatingActionButton(onPressed: compose, backgroundColor: widget.accent, foregroundColor: Colors.white, child: const Icon(Icons.add_rounded, size: 29)) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Buscar'),
        NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: 'Alertas'),
        NavigationDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mail_rounded), label: 'Mensagens'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
      ]),
    );
  }
  void selectTab(int value) { Navigator.pop(context); setState(() => tab = value); }
  Future<void> postAction(Post post, String action) async {
    if (action == 'Editar') {
      final controller = TextEditingController(text: post.text);
      final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
        title: const Text('Editar publicação'), content: TextField(controller: controller, maxLines: 5, maxLength: 280),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Salvar'))]));
      if (result != null) { post.text = result.trim(); changed(); }
      controller.dispose();
    } else if (action == 'Excluir') {
      final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Excluir publicação?'), content: const Text('Essa ação não pode ser desfeita.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
      if (yes == true) { posts.remove(post); changed(); }
    } else if (action == 'Fixar' || action == 'Desafixar') {
      post.pinned = !post.pinned;
      posts.sort((a, b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
      changed();
    } else if (action == 'Copiar' || action == 'Compartilhar') {
      await Clipboard.setData(ClipboardData(text: post.name + ' ' + post.handle + '\n' + post.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'Copiar' ? 'Texto copiado' : 'Texto copiado para compartilhar')));
    } else if (action == 'Widget' && mounted) {
      showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Widget da publicação'), content: const Text('Os widgets para a tela inicial do Android ficam para uma próxima etapa.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))]));
    }
  }
  void compose() {
    final controller = TextEditingController();
    XFile? image;
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (sheetContext) => StatefulBuilder(builder: (context, update) => Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Cancelar')), const Spacer(), const Text('Nova publicação', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const Spacer(), FilledButton(onPressed: () { addPost(controller.text, imagePath: image?.path); Navigator.pop(sheetContext); }, child: const Text('Publicar'))]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: widget.accent.withValues(alpha: .14), child: Text('♡', style: TextStyle(color: widget.accent))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: controller, autofocus: true, minLines: 3, maxLines: 7, maxLength: 280, decoration: const InputDecoration(hintText: 'O que está acontecendo?', filled: false, border: InputBorder.none, counterText: ''))),
        ]),
        if (image != null) Padding(padding: const EdgeInsets.only(left: 48, bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(image!.path), height: 160, width: double.infinity, fit: BoxFit.cover))),
        const Divider(),
        Row(children: [
          IconButton(tooltip: 'Adicionar foto', onPressed: () async { final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88); if (f != null) update(() => image = f); }, icon: const Icon(Icons.image_outlined)),
          IconButton(tooltip: 'Tirar foto', onPressed: () async { final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 88); if (f != null) update(() => image = f); }, icon: const Icon(Icons.camera_alt_outlined)),
          const Spacer(), const Text('Todos podem responder', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ]),
    ))).whenComplete(controller.dispose);
  }
  void appearance() {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (context) => StatefulBuilder(builder: (context, update) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Aparência', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5), const Text('Deixe seu cantinho com a sua cara.'),
        const SizedBox(height: 20), const Text('TEMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('Sistema'), selected: widget.themeMode == ThemeMode.system, onSelected: (_) { widget.onThemeChanged(ThemeMode.system); update(() {}); }),
          ChoiceChip(label: const Text('Claro'), selected: widget.themeMode == ThemeMode.light, onSelected: (_) { widget.onThemeChanged(ThemeMode.light); update(() {}); }),
          ChoiceChip(label: const Text('Escuro'), selected: widget.themeMode == ThemeMode.dark, onSelected: (_) { widget.onThemeChanged(ThemeMode.dark); update(() {}); }),
        ]),
        const SizedBox(height: 20), const Text('COR DE DESTAQUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 13, runSpacing: 13, children: widget.palette.map((c) => GestureDetector(onTap: () { widget.onAccentChanged(c); update(() {}); }, child: CircleAvatar(radius: 18, backgroundColor: c, child: widget.accent.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 18) : null))).toList()),
        const SizedBox(height: 20), const Text('EMOJIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Emojis no estilo iPhone'), subtitle: const Text('Usar a fonte colorida Apple em vez dos emojis do aparelho.'), value: widget.appleEmoji, onChanged: (v) { widget.onEmojiChanged(v); update(() {}); }),
      ]),
    )));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.posts, required this.onChanged, required this.onAction});
  final List<Post> posts;
  final VoidCallback onChanged;
  final void Function(Post, String) onAction;
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 2, vsync: this);
  @override
  void dispose() { tabs.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    TabBar(controller: tabs, tabs: const [Tab(text: 'Para você'), Tab(text: 'Seguindo')], labelStyle: const TextStyle(fontWeight: FontWeight.w800), indicatorSize: TabBarIndicatorSize.label),
    Expanded(child: TabBarView(controller: tabs, children: [
      _PostList(posts: widget.posts, onChanged: widget.onChanged, onAction: widget.onAction),
      _PostList(posts: widget.posts.where((p) => !p.isBot || p.handle == '@illitupdates' || p.handle == '@njzdaily').toList(), onChanged: widget.onChanged, onAction: widget.onAction),
    ])),
  ]);
}

class _PostList extends StatelessWidget {
  const _PostList({required this.posts, required this.onChanged, required this.onAction});
  final List<Post> posts;
  final VoidCallback onChanged;
  final void Function(Post, String) onAction;
  @override
  Widget build(BuildContext context) => ListView.builder(itemCount: posts.length, itemBuilder: (context, i) => PostCard(post: posts[i], onChanged: onChanged, onAction: (a) => onAction(posts[i], a)));
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onChanged, required this.onAction});
  final Post post;
  final VoidCallback onChanged;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => ReplySheet(post: post, onChanged: onChanged)),
      child: Padding(padding: const EdgeInsets.fromLTRB(14, 13, 12, 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 22, backgroundColor: accent.withValues(alpha: .13), child: Text(post.avatar, style: TextStyle(color: accent, fontSize: 19))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(post.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
            if (post.verified) ...[const SizedBox(width: 3), Icon(Icons.verified, color: accent, size: 15)],
            if (post.isBot) ...[const SizedBox(width: 4), const Icon(Icons.smart_toy_outlined, color: Colors.grey, size: 13)],
            const SizedBox(width: 5),
            Expanded(child: Text(post.handle + ' · ' + post.time, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12))),
            PopupMenuButton<String>(padding: EdgeInsets.zero, iconSize: 19, onSelected: onAction, itemBuilder: (context) => [
              const PopupMenuItem(value: 'Editar', child: ListTile(dense: true, leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
              const PopupMenuItem(value: 'Excluir', child: ListTile(dense: true, leading: Icon(Icons.delete_outline), title: Text('Excluir'))),
              PopupMenuItem(value: post.pinned ? 'Desafixar' : 'Fixar', child: ListTile(dense: true, leading: const Icon(Icons.push_pin_outlined), title: Text(post.pinned ? 'Desafixar do perfil' : 'Fixar no perfil'))),
              const PopupMenuItem(value: 'Copiar', child: ListTile(dense: true, leading: Icon(Icons.copy_outlined), title: Text('Copiar'))),
              const PopupMenuItem(value: 'Compartilhar', child: ListTile(dense: true, leading: Icon(Icons.share_outlined), title: Text('Compartilhar'))),
              const PopupMenuItem(value: 'Widget', child: ListTile(dense: true, leading: Icon(Icons.widgets_outlined), title: Text('Widget'))),
            ]),
          ]),
          if (post.pinned) const Padding(padding: EdgeInsets.only(bottom: 4), child: Row(children: [Icon(Icons.push_pin, size: 12, color: Colors.grey), SizedBox(width: 4), Text('Fixado', style: TextStyle(fontSize: 11, color: Colors.grey))])),
          const SizedBox(height: 4), Text(post.text, style: const TextStyle(fontSize: 14.5, height: 1.38)),
          if (post.image != null && File(post.image!).existsSync()) ...[const SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(post.image!), fit: BoxFit.cover, width: double.infinity))],
          const SizedBox(height: 11),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Action(icon: Icons.chat_bubble_outline_rounded, count: post.replies, onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => ReplySheet(post: post, onChanged: onChanged))),
            _Action(icon: Icons.repeat_rounded, count: post.reposts, active: post.reposted, color: Colors.green, onTap: () { post.reposted = !post.reposted; post.reposts += post.reposted ? 1 : -1; onChanged(); }),
            _Action(icon: post.liked ? Icons.favorite : Icons.favorite_border_rounded, count: post.likes, active: post.liked, color: Colors.pink, onTap: () { post.liked = !post.liked; post.likes += post.liked ? 1 : -1; onChanged(); }),
            _Action(icon: Icons.bar_chart_rounded, count: 0, onTap: () {}),
            _Action(icon: Icons.share_outlined, count: 0, onTap: () => onAction('Compartilhar')),
          ]),
        ])),
      ])),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.count, required this.onTap, this.active = false, this.color});
  final IconData icon; final int count; final VoidCallback onTap; final bool active; final Color? color;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
    child: Row(children: [Icon(icon, size: 17, color: active ? color : Colors.grey), if (count > 0) ...[const SizedBox(width: 4), Text('$count', style: const TextStyle(fontSize: 11, color: Colors.grey))]]),
  ));
}

class ReplySheet extends StatefulWidget {
  const ReplySheet({super.key, required this.post, required this.onChanged});
  final Post post; final VoidCallback onChanged;
  @override
  State<ReplySheet> createState() => _ReplySheetState();
}
class _ReplySheetState extends State<ReplySheet> {
  final controller = TextEditingController();
  final replies = <String>[];
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Center(child: Text('Publicação', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
      const SizedBox(height: 16), Text(widget.post.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 5), Text(widget.post.text), const Divider(height: 24),
      if (replies.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('Seja a primeira pessoa a responder ♡', style: TextStyle(color: Colors.grey)))),
      for (final reply in replies) ListTile(dense: true, leading: const CircleAvatar(child: Text('♡')), title: const Text('Angel'), subtitle: Text(reply)),
      Row(children: [
        const CircleAvatar(radius: 17, child: Text('♡')), const SizedBox(width: 9),
        Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Escreva uma resposta...', filled: false, border: InputBorder.none))),
        IconButton(onPressed: () { if (controller.text.trim().isEmpty) return; setState(() { replies.add(controller.text.trim()); controller.clear(); widget.post.replies++; }); widget.onChanged(); }, icon: const Icon(Icons.send_rounded)),
      ]),
    ]));
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.posts, required this.controller});
  final List<Post> posts; final TextEditingController controller;
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final found = widget.posts.where((p) => (p.name + ' ' + p.handle + ' ' + p.text).toLowerCase().contains(query.toLowerCase())).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: widget.controller, onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar no Twitter')),
      const SizedBox(height: 22),
      if (query.isEmpty) ...[
        const Text('O que está acontecendo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final topic in ['ILLIT', 'NewJeans', 'NJZ', 'Música', 'Moda']) ListTile(contentPadding: EdgeInsets.zero, title: Text(topic, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Explorar publicações e novidades'), trailing: const Icon(Icons.chevron_right)),
      ] else ...[
        const Text('Resultados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        if (found.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Nenhuma publicação encontrada.', style: TextStyle(color: Colors.grey))),
        for (final p in found) ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text(p.avatar)), title: Text(p.name), subtitle: Text(p.handle + '\n' + p.text, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    ]);
  }
}

class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key, required this.icon, required this.title, required this.message});
  final IconData icon; final String title, message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 14),
    Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 7),
    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
  ])));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.posts, required this.onChanged, required this.onAction});
  final List<Post> posts; final VoidCallback onChanged; final void Function(Post, String) onAction;
  @override
  Widget build(BuildContext context) {
    final mine = posts.where((p) => p.handle == '@angel').toList();
    return ListView(children: [
      Container(height: 118, color: Theme.of(context).colorScheme.primary.withValues(alpha: .18)),
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CircleAvatar(radius: 34, child: Text('♡', style: TextStyle(fontSize: 28))),
        const SizedBox(height: 12), const Text('Angel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Text('@angel', style: TextStyle(color: Colors.grey)), const SizedBox(height: 12),
        const Text('Um cantinho meu na internet ♡'), const SizedBox(height: 16),
        const Text('0 seguindo     0 seguidores'), const Divider(height: 28),
        const Text('Publicações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ])),
      if (mine.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Suas publicações vão aparecer aqui.', style: TextStyle(color: Colors.grey)))),
      for (final p in mine) PostCard(post: p, onChanged: onChanged, onAction: (a) => onAction(p, a)),
    ]);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), onTap: onTap);
}
