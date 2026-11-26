import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
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
  late Color accent;
  late ThemeMode themeMode;
  static const palette = <Color>[
    Color(0xFF1D9BF0), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFFE879A8), Color(0xFF14B8A6), Color(0xFF22C55E),
    Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFF64748B),
    Color(0xFF111827),
  ];

  @override
  void initState() {
    super.initState();
    accent = Color(widget.prefs.getInt('accent') ?? palette.first.toARGB32());
    themeMode = ThemeMode.values[widget.prefs.getInt('themeMode') ?? 0];
  }

  Future<void> setAccent(Color color) async {
    setState(() => accent = color);
    await widget.prefs.setInt('accent', color.toARGB32());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() => themeMode = mode);
    await widget.prefs.setInt('themeMode', mode.index);
  }

  ThemeData makeTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
    return ThemeData(
      useMaterial3: true, colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),
      dividerColor: brightness == Brightness.light ? const Color(0xFFE7E7E7) : const Color(0xFF2F3336),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light ? const Color(0xFFF1F3F5) : const Color(0xFF202327),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Twitter',
    theme: makeTheme(Brightness.light), darkTheme: makeTheme(Brightness.dark), themeMode: themeMode,
    home: MainShell(accent: accent, palette: palette, onAccentChanged: setAccent,
      themeMode: themeMode, onThemeChanged: setThemeMode),
  );
}

class Post {
  Post({required this.name, required this.handle, required this.avatar, required this.text,
    required this.time, this.verified = false, this.image, this.likes = 0,
    this.reposts = 0, this.replies = 0, this.isBot = false});
  final String name, handle, avatar, text, time;
  final bool verified, isBot;
  final String? image;
  int likes, reposts, replies;
  bool liked = false, reposted = false;
  Map<String, dynamic> toJson() => {'name': name, 'handle': handle, 'avatar': avatar, 'text': text, 'time': time, 'image': image, 'likes': likes, 'reposts': reposts, 'replies': replies, 'isBot': isBot, 'verified': verified, 'liked': liked, 'reposted': reposted};
  factory Post.fromJson(Map<String, dynamic> j) => Post(name: j['name'], handle: j['handle'], avatar: j['avatar'], text: j['text'], time: j['time'], image: j['image'], likes: j['likes'] ?? 0, reposts: j['reposts'] ?? 0, replies: j['replies'] ?? 0, isBot: j['isBot'] ?? false, verified: j['verified'] ?? false)..liked = j['liked'] ?? false..reposted = j['reposted'] ?? false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.accent, required this.palette,
    required this.onAccentChanged, required this.themeMode, required this.onThemeChanged});
  final Color accent;
  final List<Color> palette;
  final ValueChanged<Color> onAccentChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final List<Post> posts = [
    Post(name: 'ILLIT Updates', handle: '@illitupdates', avatar: '✧',
      text: 'Your little ILLIT update corner ♡ News, schedules and moments from the girls.',
      time: '2 min', verified: true, isBot: true, likes: 128),
    Post(name: 'NJZ Daily', handle: '@njzdaily', avatar: '🐰',
      text: 'A little place for NewJeans memories, updates and photos. More soon! ♡',
      time: '18 min', verified: true, isBot: true, likes: 94),
    Post(name: 'mimi', handle: '@mimisworld', avatar: '୨ৎ',
      text: 'this is going to be such a cute little corner of the internet',
      time: '32 min', likes: 23, replies: 4),
    Post(name: 'pop updates', handle: '@popdiary', avatar: '♡',
      text: 'Keeping up with the music, the moments and everything in between.',
      time: '1 h', isBot: true, likes: 61),
  ];
  final TextEditingController searchController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final saved = widget.prefs.getString('timeline_posts');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        if (decoded.isNotEmpty) posts.addAll(decoded.map((item) => Post.fromJson(item as Map<String, dynamic>)));
      } catch (_) {}
    }
  }

  Future<void> savePosts() async => widget.prefs.setString('timeline_posts', jsonEncode(posts.map((post) => post.toJson()).toList()));
  String get title => ['Home', 'Explore', 'Notifications', 'Messages', 'Profile'][tab];

  void addPost(String text, {String? imagePath}) {
    if (text.trim().isEmpty) return;
    setState(() {
      posts.insert(0, Post(name: 'you', handle: '@youraccount', avatar: '♡',
        text: text.trim(), time: 'now', image: imagePath));
      tab = 0;
    });
    savePosts();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(posts: posts, onChanged: () { setState(() {}); savePosts(); }),
      ExplorePage(controller: searchController),
      const SimplePage(icon: Icons.notifications_none_rounded, title: 'Notifications',
        subtitle: 'You’re all caught up. New activity will appear here.'),
      const SimplePage(icon: Icons.mail_outline_rounded, title: 'Messages',
        subtitle: 'Your conversations will live here.'),
      const ProfilePage(),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(12),
          child: CircleAvatar(backgroundColor: widget.accent.withValues(alpha: .13),
            child: Icon(Icons.flutter_dash_rounded, color: widget.accent))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: 'Appearance', icon: const Icon(Icons.palette_outlined),
          onPressed: openAppearance), const SizedBox(width: 4)],
      ),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 0 ? FloatingActionButton(onPressed: compose,
        backgroundColor: widget.accent, foregroundColor: Colors.white, child: const Icon(Icons.add)) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.mail_outline), selectedIcon: Icon(Icons.mail), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void compose() {
    final controller = TextEditingController();
    XFile? selectedImage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Cancel')),
              const Spacer(),
              const Text('New post', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              FilledButton(onPressed: () {
                addPost(controller.text, imagePath: selectedImage?.path);
                Navigator.pop(sheetContext);
              }, child: const Text('Post')),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(child: Text('♡')),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: controller, autofocus: true, minLines: 3, maxLines: 6, maxLength: 280,
                decoration: const InputDecoration(hintText: 'What’s happening? ♡', filled: false,
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, counterText: ''),
              )),
            ]),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(selectedImage!.path), height: 165, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            const Divider(),
            Row(children: [
              IconButton(tooltip: 'Choose photo', onPressed: () async {
                final file = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 88);
                if (file != null) refreshSheet(() => selectedImage = file);
              }, icon: const Icon(Icons.image_outlined)),
              IconButton(tooltip: 'Take photo', onPressed: () async {
                final file = await imagePicker.pickImage(source: ImageSource.camera, imageQuality: 88);
                if (file != null) refreshSheet(() => selectedImage = file);
              }, icon: const Icon(Icons.camera_alt_outlined)),
              const Spacer(),
              const Text('Everyone can reply', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void openAppearance() {
    final colorController = TextEditingController(text: '#${widget.accent.value.toRadixString(16).substring(2).toUpperCase()}');
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, refresh) {
        final isDark = widget.themeMode == ThemeMode.dark;
        return Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Appearance', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6), const Text('Make your little corner feel like yours.'),
            const SizedBox(height: 22),
            const Text('THEME', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('System'), selected: widget.themeMode == ThemeMode.system,
                onSelected: (_) { widget.onThemeChanged(ThemeMode.system); refresh(() {}); }),
              ChoiceChip(label: const Text('Light'), selected: widget.themeMode == ThemeMode.light,
                onSelected: (_) { widget.onThemeChanged(ThemeMode.light); refresh(() {}); }),
              ChoiceChip(label: const Text('Dark'), selected: isDark,
                onSelected: (_) { widget.onThemeChanged(ThemeMode.dark); refresh(() {}); }),
            ]),
            const SizedBox(height: 22),
            const Text('ACCENT COLOR', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Wrap(spacing: 14, runSpacing: 14, children: widget.palette.map((color) =>
              GestureDetector(onTap: () { widget.onAccentChanged(color); refresh(() {}); },
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    border: Border.all(color: widget.accent.toARGB32() == color.toARGB32()
                      ? Theme.of(context).colorScheme.onSurface : Colors.transparent, width: 3)),
                  child: widget.accent.toARGB32() == color.toARGB32()
                    ? const Icon(Icons.check, color: Colors.white, size: 19) : null,
                ))).toList()),
            const SizedBox(height: 18),
            TextField(controller: colorController, textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'Custom HEX color', hintText: '#F4A7C7',
                suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: () {
                  final hex = colorController.text.trim().replaceFirst('#', '');
                  final normalized = hex.length == 6 ? 'FF' + hex : hex;
                  final value = int.tryParse(normalized, radix: 16);
                  if (value != null && normalized.length == 8) {
                    widget.onAccentChanged(Color(value));
                    refresh(() {});
                  }
                }))),
          ]));
      }));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.posts, required this.onChanged});
  final List<Post> posts;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: const Row(children: [
        Expanded(child: Padding(padding: EdgeInsets.all(15), child: Center(child: Text('For you', style: TextStyle(fontWeight: FontWeight.bold))))),
        Expanded(child: Padding(padding: EdgeInsets.all(15), child: Center(child: Text('Following')))),
      ])),
    Expanded(child: ListView.builder(itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(post: posts[index], onChanged: onChanged))),
  ]);
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onChanged});
  final Post post;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(onTap: () => showModalBottomSheet(context: context,
      builder: (_) => Padding(padding: const EdgeInsets.all(24),
        child: Text('Replies to ' + post.name + '\n\nBe the first to reply ♡'))),
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 22, backgroundColor: accent.withValues(alpha: .13),
            child: Text(post.avatar, style: TextStyle(color: accent, fontSize: 19))),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(post.name, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold))),
              if (post.verified) ...[const SizedBox(width: 3), Icon(Icons.verified, color: accent, size: 15)],
              if (post.isBot) ...[const SizedBox(width: 5), const Icon(Icons.smart_toy_outlined, size: 13, color: Colors.grey)],
              const SizedBox(width: 5),
              Expanded(child: Text(post.handle + ' · ' + post.time, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12))),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ]),
            const SizedBox(height: 6), Text(post.text, style: const TextStyle(fontSize: 14.5, height: 1.4)),
            if (post.image != null && File(post.image!).existsSync()) ...[const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(post.image!), fit: BoxFit.cover))],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Action(icon: Icons.chat_bubble_outline, count: post.replies.toString(), onTap: () {}),
              _Action(icon: Icons.repeat, count: post.reposts.toString(), active: post.reposted,
                onTap: () { post.reposted = !post.reposted; post.reposts += post.reposted ? 1 : -1; onChanged(); }),
              _Action(icon: post.liked ? Icons.favorite : Icons.favorite_border, count: post.likes.toString(),
                active: post.liked, activeColor: Colors.pink,
                onTap: () { post.liked = !post.liked; post.likes += post.liked ? 1 : -1; onChanged(); }),
              _Action(icon: Icons.share_outlined, count: '', onTap: () {}),
            ]),
          ])),
        ])));
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.count, required this.onTap, this.active = false, this.activeColor});
  final IconData icon; final String count; final VoidCallback onTap; final bool active; final Color? activeColor;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      child: Row(children: [
        Icon(icon, size: 17, color: active ? (activeColor ?? Theme.of(context).colorScheme.primary) : Colors.grey),
        if (count.isNotEmpty) ...[const SizedBox(width: 5), Text(count, style: const TextStyle(fontSize: 11, color: Colors.grey))],
      ])));
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    TextField(controller: controller, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search')),
    const SizedBox(height: 22), const Text('What’s happening', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 14),
    for (final item in ['ILLIT', 'NewJeans', 'NJZ', 'Music', 'Your interests'])
      ListTile(contentPadding: EdgeInsets.zero, title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Explore posts and updates'), trailing: const Icon(Icons.chevron_right)),
  ]);
}

class SimplePage extends StatelessWidget {
  const SimplePage({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 14), Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 7), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
    ])));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(children: [
    Container(height: 120, color: Theme.of(context).colorScheme.primary.withValues(alpha: .18)),
    Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CircleAvatar(radius: 34, child: Text('♡', style: TextStyle(fontSize: 28))),
      const SizedBox(height: 12), const Text('Your name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const Text('@youraccount', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 12), const Text('A little corner of the internet ♡'),
      const SizedBox(height: 16), const Text('0 Following     0 Followers'),
      const Divider(height: 28), const Text('Your posts will appear here.'),
    ])),
  ]);
}
