import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import 'avatar_widget.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onChanged,
    required this.onAction,
    required this.onOpenThread,
    required this.onOpenProfile,
  });

  final Post post;
  final VoidCallback onChanged;
  final ValueChanged<String> onAction;
  final VoidCallback onOpenThread;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final primaryText = isDark ? const Color(0xFFE7E9EA) : const Color(0xFF0F1419);
    final media = post.mediaPath;

    return Column(
      children: [
        InkWell(
          onTap: post.accountId.startsWith('external-') && post.linkUrl != null
              ? () => launchUrl(
                    Uri.parse(post.linkUrl!),
                    mode: LaunchMode.externalApplication,
                  )
              : onOpenThread,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.pinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.push_pin_rounded, size: 13, color: secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Post fixado',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
                        ),
                      ],
                    ),
                  )
                else if (post.repostedBy != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.repeat_rounded, size: 13, color: secondary),
                        const SizedBox(width: 6),
                        Text(
                          '${post.repostedBy} repostou',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarWidget(
                      emoji: post.avatarEmoji,
                      imagePath: post.avatarPath,
                      radius: 20,
                      onTap: onOpenProfile,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: onOpenProfile,
                                  child: Text(
                                    post.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: primaryText,
                                    ),
                                  ),
                                ),
                              ),
                              if (post.verified) ...[
                                const SizedBox(width: 3),
                                VerifiedBadge(size: 15.5),
                              ],
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${post.handle} · ${formatRelativeTime(post.createdAtMs)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: secondary, fontSize: 14),
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 26,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  splashRadius: 18,
                                  icon: Icon(Icons.more_horiz_rounded,
                                      size: 18, color: secondary),
                                  onPressed: () => _showMenu(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TweetText(
                              text: post.text,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.38,
                                color: primaryText,
                              ),
                              accent: accent,
                            ),
                          ),
                          if (media != null && media.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _openImageViewer(context, media),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.dividerColor, width: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 290),
                                    child: AppMediaImage(path: media),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (post.linkUrl != null && post.linkUrl!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => launchUrl(
                                Uri.parse(post.linkUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor, width: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.link_rounded, size: 17, color: accent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.linkTitle ?? 'Abrir link',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            Uri.tryParse(post.linkUrl!)?.host ??
                                                'link original',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.open_in_new_rounded, size: 14, color: secondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TweetAction(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  count: post.replies.length,
                                  color: secondary,
                                  onTap: post.accountId.startsWith('external-') && post.linkUrl != null
                                      ? () => launchUrl(
                                            Uri.parse(post.linkUrl!),
                                            mode: LaunchMode.externalApplication,
                                          )
                                      : onOpenThread,
                                  tooltip: post.accountId.startsWith('external-')
                                      ? 'Ver conversa no X'
                                      : 'Responder',
                                ),
                                _TweetAction(
                                  icon: Icons.repeat_rounded,
                                  count: post.reposts,
                                  active: post.reposted,
                                  color: secondary,
                                  activeColor: const Color(0xFF00BA7C),
                                  onTap: () {
                                    post.reposted = !post.reposted;
                                    post.reposts = (post.reposts + (post.reposted ? 1 : -1)).clamp(0, 1 << 30);
                                    onChanged();
                                  },
                                  tooltip: 'Repostar',
                                ),
                                _TweetAction(
                                  icon: post.liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  count: post.likes,
                                  active: post.liked,
                                  color: secondary,
                                  activeColor: const Color(0xFFF91880),
                                  onTap: () {
                                    post.liked = !post.liked;
                                    post.likes = (post.likes + (post.liked ? 1 : -1)).clamp(0, 1 << 30);
                                    onChanged();
                                  },
                                  tooltip: 'Curtir',
                                ),
                                _TweetAction(
                                  icon: Icons.bar_chart_rounded,
                                  count: post.views,
                                  color: secondary,
                                  onTap: onOpenThread,
                                  tooltip: 'Visualizações',
                                ),
                                Row(
                                  children: [
                                    _IconAction(
                                      icon: post.bookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: post.bookmarked ? accent : secondary,
                                      onTap: () {
                                        post.bookmarked = !post.bookmarked;
                                        onChanged();
                                      },
                                      tooltip: post.bookmarked ? 'Remover dos salvos' : 'Salvar',
                                    ),
                                    const SizedBox(width: 12),
                                    _IconAction(
                                      icon: Icons.share_outlined,
                                      color: secondary,
                                      onTap: () => onAction('Compartilhar'),
                                      tooltip: 'Compartilhar',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    final isMine = post.handle == '@angel';
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
                onAction('Copiar');
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(post.pinned ? 'Desafixar do perfil' : 'Fixar no perfil'),
              onTap: () {
                Navigator.pop(ctx);
                onAction(post.pinned ? 'Desafixar' : 'Fixar');
              },
            ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar post'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAction('Editar');
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Excluir post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onAction('Excluir');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: AppMediaImage(path: path, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 44,
              right: 16,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TweetText extends StatelessWidget {
  const TweetText({
    super.key,
    required this.text,
    required this.style,
    required this.accent,
  });

  final String text;
  final TextStyle style;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'([#@][\w\u00C0-\u017F]+)');
    var last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: TextStyle(color: accent),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _TweetAction extends StatelessWidget {
  const _TweetAction({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    this.active = false,
    this.activeColor,
    this.tooltip,
  });

  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = active ? (activeColor ?? color) : color;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 1),
          child: Row(
            children: [
              Icon(icon, size: 18, color: c),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  formatCompact(count),
                  style: TextStyle(fontSize: 12.5, color: c),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
}


