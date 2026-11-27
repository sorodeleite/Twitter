import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/bot_engine.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.post,
    required this.accounts,
    required this.meAccount,
    required this.onChanged,
    required this.onOpenProfile,
  });

  final Post post;
  final List<Account> accounts;
  final Account meAccount;
  final VoidCallback onChanged;
  final void Function(Account) onOpenProfile;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _ctrl = TextEditingController();
  late Account _replyAs = widget.meAccount;
  final List<Timer> _timers = [];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final reply = Reply(
      id: 'rep-${DateTime.now().microsecondsSinceEpoch}',
      accountId: _replyAs.id,
      name: _replyAs.name,
      handle: _replyAs.handle,
      avatarEmoji: _replyAs.avatarEmoji,
      avatarPath: _replyAs.avatarPath,
      verified: _replyAs.verified,
      text: text,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      widget.post.replies.add(reply);
      _ctrl.clear();
    });
    widget.onChanged();
    _maybeBotReply(reply);
  }

  void _maybeBotReply(Reply mine) {
    if (!_replyAs.isMe) return;
    final author = widget.accounts
        .where((a) => a.id == widget.post.accountId || a.handle == widget.post.handle)
        .firstOrNull;
    if (author == null || !author.autoInteract || author.isMe) return;
    if (author.id == 'illit' && !_rngBool()) return;

    final timer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      final replyText = BotEngine.generateReply(author, widget.post);
      setState(() {
        widget.post.replies.add(Reply(
          id: 'rep-bot-${DateTime.now().microsecondsSinceEpoch}',
          accountId: author.id,
          name: author.name,
          handle: author.handle,
          avatarEmoji: author.avatarEmoji,
          avatarPath: author.avatarPath,
          verified: author.verified,
          text: replyText,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ));
        widget.post.likes += 1;
      });
      widget.onChanged();
    });
    _timers.add(timer);
  }

  bool _rngBool() => DateTime.now().millisecond % 2 == 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final accent = theme.colorScheme.primary;
    final primaryText = isDark ? const Color(0xFFE7E9EA) : const Color(0xFF0F1419);
    final p = widget.post;
    final media = p.mediaPath;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () => _showMore(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarWidget(
                            emoji: p.avatarEmoji,
                            imagePath: p.avatarPath,
                            radius: 23,
                            onTap: () => _openAcc(p.accountId, p.handle),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        p.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                    ),
                                    if (p.verified) ...[
                                      const SizedBox(width: 3),
                                      VerifiedBadge(size: 16),
                                    ],
                                  ],
                                ),
                                Text(p.handle,
                                    style: TextStyle(color: secondary, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TweetText(
                        text: p.text,
                        style: TextStyle(fontSize: 17, height: 1.4, color: primaryText),
                        accent: accent,
                      ),
                      if (media != null && media.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 380),
                            child: AppMediaImage(path: media),
                          ),
                        ),
                      ],
                      if (p.linkUrl != null && p.linkUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(p.linkUrl!),
                              mode: LaunchMode.externalApplication),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor, width: 0.8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link_rounded, size: 18, color: accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.linkUrl!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: accent, fontSize: 13),
                                  ),
                                ),
                                Icon(Icons.open_in_new_rounded, size: 15, color: secondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        '${formatClock(p.createdAtMs)} · ${formatFullDateTime(p.createdAtMs).split('· ').last} · '
                        '${formatCount(p.views)} visualizações',
                        style: TextStyle(color: secondary, fontSize: 13),
                      ),
                      const Divider(height: 22),
                      Row(
                        children: [
                          _stat('${formatCount(p.reposts)}', 'Reposts'),
                          const SizedBox(width: 18),
                          _stat('${formatCount(p.likes)}', 'Curtidas'),
                          const SizedBox(width: 18),
                          _stat('${formatCount(p.replies.length)}', 'Respostas'),
                          const SizedBox(width: 18),
                          _stat('${formatCount(p.bookmarked ? 1 : 0)}', 'Salvos'),
                        ],
                      ),
                      const Divider(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            tooltip: 'Responder',
                            onPressed: () => _focusComposer(),
                            icon: Icon(Icons.chat_bubble_outline_rounded, color: secondary),
                          ),
                          IconButton(
                            tooltip: 'Repostar',
                            onPressed: () {
                              setState(() {
                                p.reposted = !p.reposted;
                                p.reposts =
                                    (p.reposts + (p.reposted ? 1 : -1)).clamp(0, 1 << 30);
                              });
                              widget.onChanged();
                            },
                            icon: Icon(Icons.repeat_rounded,
                                color: p.reposted ? const Color(0xFF00BA7C) : secondary),
                          ),
                          IconButton(
                            tooltip: 'Curtir',
                            onPressed: () {
                              setState(() {
                                p.liked = !p.liked;
                                p.likes = (p.likes + (p.liked ? 1 : -1)).clamp(0, 1 << 30);
                              });
                              widget.onChanged();
                            },
                            icon: Icon(
                              p.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: p.liked ? const Color(0xFFF91880) : secondary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Salvar',
                            onPressed: () {
                              setState(() => p.bookmarked = !p.bookmarked);
                              widget.onChanged();
                            },
                            icon: Icon(
                              p.bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: p.bookmarked ? accent : secondary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Compartilhar',
                            onPressed: () => _showMore(context),
                            icon: Icon(Icons.share_outlined, color: secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 0.7, thickness: 0.7, color: theme.dividerColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Row(
                    children: [
                      AvatarWidget(
                        emoji: _replyAs.avatarEmoji,
                        imagePath: _replyAs.avatarPath,
                        radius: 18,
                        onTap: _chooseReplyAs,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Responder como ${_replyAs.name}',
                        style: TextStyle(color: secondary, fontSize: 12.5),
                      ),
                      const Spacer(),
                      if (widget.accounts.length > 1)
                        TextButton(
                          onPressed: _chooseReplyAs,
                          child: const Text('trocar'),
                        ),
                    ],
                  ),
                ),
                if (p.replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                    child: Center(
                      child: Text(
                        'Sem respostas ainda. Seja a primeira a responder ♡',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  ),
                for (final r in p.replies) _buildReply(r, secondary, accent, theme),
                const SizedBox(height: 30),
              ],
            ),
          ),
          _buildComposer(theme, secondary),
        ],
      ),
    );
  }

  Widget _buildReply(Reply r, Color secondary, Color accent, ThemeData theme) {
    return Column(
      children: [
        InkWell(
          onTap: () => _openAcc(r.accountId, r.handle),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(
                  emoji: r.avatarEmoji,
                  imagePath: r.avatarPath,
                  radius: 18,
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
                              r.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                          ),
                          if (r.verified) ...[
                            const SizedBox(width: 3),
                            VerifiedBadge(size: 14),
                          ],
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${r.handle} · ${formatRelativeTime(r.createdAtMs)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: secondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(r.text, style: const TextStyle(fontSize: 14.5, height: 1.36)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 15, color: secondary),
                          const SizedBox(width: 4),
                          Text('${r.likes}',
                              style: TextStyle(color: secondary, fontSize: 12)),
                          const SizedBox(width: 18),
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 14, color: secondary),
                          const SizedBox(width: 4),
                          Text('Responder', style: TextStyle(color: secondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
      ],
    );
  }

  Widget _buildComposer(ThemeData theme, Color secondary) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor, width: 0.6)),
          color: theme.scaffoldBackgroundColor,
        ),
        child: Row(
          children: [
            AvatarWidget(
              emoji: _replyAs.avatarEmoji,
              imagePath: _replyAs.avatarPath,
              radius: 17,
              onTap: _chooseReplyAs,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Postar sua resposta…',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: _sendReply,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Responder'),
            ),
          ],
        ),
      ),
    );
  }

  final FocusNode _focusNode = FocusNode();

  void _focusComposer() => _focusNode.requestFocus();

  void _chooseReplyAs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: Text('Responder como',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              for (final a in widget.accounts)
                ListTile(
                  leading: AvatarWidget(
                    emoji: a.avatarEmoji,
                    imagePath: a.avatarPath,
                    radius: 19,
                  ),
                  title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(a.handle),
                  trailing: a.id == _replyAs.id
                      ? Icon(Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _replyAs = a);
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('Copiar texto'),
              onTap: () {
                Navigator.pop(ctx);
                _copyText();
              },
            ),
            if (widget.post.linkUrl != null)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Abrir link'),
                onTap: () {
                  Navigator.pop(ctx);
                  launchUrl(Uri.parse(widget.post.linkUrl!),
                      mode: LaunchMode.externalApplication);
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(ctx);
                _copyText();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openAcc(String id, String handle) {
    final target = widget.accounts.firstWhere(
      (a) => a.id == id || a.handle == handle,
      orElse: () => widget.meAccount,
    );
    widget.onOpenProfile(target);
  }

  Future<void> _copyText() async {
    await Clipboard.setData(
      ClipboardData(text: '${widget.post.name} ${widget.post.handle}\n${widget.post.text}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texto copiado ♡')),
    );
  }

  Widget _stat(String value, String label) {
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF71767B)
        : const Color(0xFF536471);
    return Row(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: secondary, fontSize: 14)),
      ],
    );
  }
}
