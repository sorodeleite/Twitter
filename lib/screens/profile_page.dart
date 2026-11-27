import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/media_store.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/post_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.account,
    required this.allPosts,
    required this.accounts,
    required this.onAccountUpdated,
    required this.onPostsChanged,
    required this.onPostAction,
    required this.onOpenThread,
    required this.onOpenProfile,
    this.onOpenDm,
    this.onOpenIllitWiki,
    this.isEmbeddedTab = true,
  });

  final Account account;
  final List<Post> allPosts;
  final List<Account> accounts;
  final VoidCallback onAccountUpdated;
  final VoidCallback onPostsChanged;
  final void Function(Post, String) onPostAction;
  final void Function(Post) onOpenThread;
  final void Function(Account) onOpenProfile;
  final void Function(Account)? onOpenDm;
  final VoidCallback? onOpenIllitWiki;
  final bool isEmbeddedTab;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final acc = widget.account;

    final userPosts = widget.allPosts
        .where((p) => p.accountId == acc.id || p.handle == acc.handle)
        .toList();
    final mediaPosts =
        userPosts.where((p) => p.mediaPath != null && p.mediaPath!.isNotEmpty).toList();
    final likedPosts = widget.allPosts.where((p) => p.liked).toList();
    final repliedPosts = widget.allPosts
        .where((p) => p.replies.any((r) => r.handle == acc.handle))
        .toList();

    final body = NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(context, acc, secondary),
              _buildActions(context, acc),
              _buildIdentity(context, acc, secondary),
              _buildTabs(context, secondary),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPostList(userPosts, 'Ainda não há posts por aqui.'),
          _buildPostList(repliedPosts, 'Nenhuma resposta ainda.'),
          _buildMediaGrid(mediaPosts),
          _buildPostList(likedPosts, 'Nenhuma curtida ainda.'),
        ],
      ),
    );

    if (widget.isEmbeddedTab) return body;
    return Scaffold(
      body: Stack(
        children: [
          body,
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 21),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Voltar',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context, Account acc, Color secondary) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 188,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: Color(acc.bannerColorValue).withValues(alpha: 0.3),
            child: acc.bannerPath != null && acc.bannerPath!.isNotEmpty
                ? AppMediaImage(path: acc.bannerPath!, height: 150)
                : null,
          ),
          Positioned(
            left: 14,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: AvatarWidget(
                emoji: acc.avatarEmoji,
                imagePath: acc.avatarPath,
                radius: 37,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Account acc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!acc.isMe && widget.onOpenDm != null) ...[
            _CircleOutlineButton(
              icon: Icons.mail_outline_rounded,
              tooltip: 'Mensagem',
              onTap: () => widget.onOpenDm!(acc),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton(
            onPressed: () => _openEditSheet(context),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: BorderSide(color: theme.dividerColor),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              foregroundColor: primary,
            ),
            child: Text(
              acc.isMe ? 'Editar perfil' : (acc.isBot ? 'Editar bot' : 'Editar conta'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          if (acc.isIllit) ...[
            const SizedBox(width: 8),
            _CircleOutlineButton(
              icon: Icons.menu_book_rounded,
              tooltip: 'Enciclopédia ILLIT',
              onTap: widget.onOpenIllitWiki,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, Account acc, Color secondary) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  acc.name,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              if (acc.verified) ...[
                const SizedBox(width: 4),
                VerifiedBadge(size: 19),
              ],
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  acc.handle,
                  style: TextStyle(color: secondary, fontSize: 14.5),
                ),
              ),
              if (acc.isBot) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'automatizado',
                    style: TextStyle(fontSize: 10.5, color: secondary),
                  ),
                ),
              ],
            ],
          ),
          if (acc.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(acc.bio, style: const TextStyle(fontSize: 14.5, height: 1.4)),
          ],
          if (acc.isIllit) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: widget.onOpenIllitWiki,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 20, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enciclopédia ILLIT',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: accent)),
                          const SizedBox(height: 2),
                          Text(
                            'Membros, discografia completa, prêmios, recordes e turnês — atualizado de verdade.',
                            style: TextStyle(fontSize: 12, color: secondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: accent, size: 20),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (acc.location.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _MetaItem(icon: Icons.location_on_outlined, text: acc.location),
                ),
              if (acc.website.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _MetaItem(
                    icon: Icons.link_rounded,
                    text: acc.website.replaceFirst(RegExp(r'^https?://'), ''),
                    color: accent,
                    onTap: () {
                      var url = acc.website.trim();
                      if (!url.startsWith('http')) url = 'https://$url';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
              _MetaItem(
                icon: Icons.calendar_today_outlined,
                text: 'Ingressou em ${acc.joinedDate}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 4,
            children: [
              _count(context, '${acc.followingCount}', 'Seguindo'),
              _count(context, '${acc.followersCount}', 'Seguidores'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _count(BuildContext context, String value, String label) {
    final secondary =
        Theme.of(context).brightness == Brightness.dark ? const Color(0xFF71767B) : const Color(0xFF536471);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: secondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, Color secondary) {
    return TabBar(
      controller: _tabs,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelColor: secondary,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Theme.of(context).dividerColor,
      tabs: const [
        Tab(text: 'Posts'),
        Tab(text: 'Respostas'),
        Tab(text: 'Mídia'),
        Tab(text: 'Curtidas'),
      ],
    );
  }

  Widget _buildPostList(List<Post> items, String emptyText) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        return PostCard(
          post: p,
          onChanged: widget.onPostsChanged,
          onAction: (a) => widget.onPostAction(p, a),
          onOpenThread: () => widget.onOpenThread(p),
          onOpenProfile: () {
            final target = widget.accounts.firstWhere(
              (a) => a.id == p.accountId || a.handle == p.handle,
              orElse: () => widget.account,
            );
            widget.onOpenProfile(target);
          },
        );
      },
    );
  }

  Widget _buildMediaGrid(List<Post> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text('Nenhuma mídia publicada ainda.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        return GestureDetector(
          onTap: () => widget.onOpenThread(p),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: AppMediaImage(path: p.mediaPath!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  void _openEditSheet(BuildContext context) {
    final acc = widget.account;
    final nameCtrl = TextEditingController(text: acc.name);
    final handleCtrl = TextEditingController(text: acc.handle);
    final bioCtrl = TextEditingController(text: acc.bio);
    final locCtrl = TextEditingController(text: acc.location);
    final siteCtrl = TextEditingController(text: acc.website);
    final emojiCtrl = TextEditingController(text: acc.avatarEmoji);
    final joinedCtrl = TextEditingController(text: acc.joinedDate);
    final followingCtrl = TextEditingController(text: '${acc.followingCount}');
    final followersCtrl = TextEditingController(text: '${acc.followersCount}');
    String? avatarPath = acc.avatarPath;
    String? bannerPath = acc.bannerPath;
    bool verified = acc.verified;
    final picker = ImagePicker();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    Expanded(
                      child: Text(
                        acc.isMe ? 'Editar perfil' : 'Editar conta',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        acc.name = nameCtrl.text.trim().isEmpty ? acc.name : nameCtrl.text.trim();
                        var handle = handleCtrl.text.trim();
                        if (handle.isEmpty) handle = acc.handle;
                        if (!handle.startsWith('@')) handle = '@$handle';
                        acc.handle = handle;
                        acc.bio = bioCtrl.text;
                        acc.location = locCtrl.text;
                        acc.website = siteCtrl.text.trim();
                        acc.avatarEmoji =
                            emojiCtrl.text.trim().isEmpty ? '♡' : emojiCtrl.text.trim();
                        acc.avatarPath = avatarPath;
                        acc.bannerPath = bannerPath;
                        acc.verified = verified;
                        acc.joinedDate = joinedCtrl.text.trim().isEmpty
                            ? acc.joinedDate
                            : joinedCtrl.text.trim();
                        acc.followingCount =
                            int.tryParse(followingCtrl.text.trim()) ?? acc.followingCount;
                        acc.followersCount =
                            int.tryParse(followersCtrl.text.trim()) ?? acc.followersCount;

                        for (final p in widget.allPosts) {
                          if (p.accountId == acc.id) {
                            p.name = acc.name;
                            p.handle = acc.handle;
                            p.avatarEmoji = acc.avatarEmoji;
                            p.avatarPath = acc.avatarPath;
                            p.verified = acc.verified;
                          }
                        }
                        widget.onAccountUpdated();
                        widget.onPostsChanged();
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AvatarWidget(
                      emoji: acc.avatarEmoji,
                      imagePath: avatarPath,
                      radius: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final f = await picker.pickImage(
                              source: ImageSource.gallery, imageQuality: 88);
                          if (f != null) {
                            final saved = await MediaStore.persist(f.path);
                            setModalState(() => avatarPath = saved);
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Foto de perfil'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final f = await picker.pickImage(
                              source: ImageSource.gallery, imageQuality: 88);
                          if (f != null) {
                            final saved = await MediaStore.persist(f.path);
                            setModalState(() => bannerPath = saved);
                          }
                        },
                        icon: const Icon(Icons.panorama_outlined, size: 18),
                        label: const Text('Capa'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome de exibição'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: handleCtrl,
                  decoration: const InputDecoration(labelText: '@usuário'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  minLines: 4,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Bio (sem limite de tamanho)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Localização (do tamanho que você quiser)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: siteCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Link / site'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: joinedCtrl,
                        decoration: const InputDecoration(labelText: 'Ingressou em'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: emojiCtrl,
                        decoration: const InputDecoration(labelText: 'Emoji reserva'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: followingCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Seguindo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: followersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Seguidores'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Selo verificado'),
                  value: verified,
                  onChanged: (v) => setModalState(() => verified = v),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // espera a animação da bottom sheet terminar antes de descartar os campos
      Future.delayed(const Duration(milliseconds: 700), () {
        nameCtrl.dispose();
        handleCtrl.dispose();
        bioCtrl.dispose();
        locCtrl.dispose();
        siteCtrl.dispose();
        emojiCtrl.dispose();
        joinedCtrl.dispose();
        followingCtrl.dispose();
        followersCtrl.dispose();
      });
    });
  }
}

class _CircleOutlineButton extends StatelessWidget {
  const _CircleOutlineButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(9),
          side: BorderSide(color: theme.dividerColor),
          foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.text,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final secondary =
        Theme.of(context).brightness == Brightness.dark ? const Color(0xFF71767B) : const Color(0xFF536471);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: color ?? secondary),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color ?? secondary, fontSize: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
