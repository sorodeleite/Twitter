import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/illit_knowledge.dart';
import '../models.dart';
import '../widgets/post_card.dart';

/// Enciclopédia do ILLIT dentro do app: ficha, membros, discografia, prêmios,
/// recordes, turnês, linha do tempo e notícias reais.
class IllitWikiPage extends StatefulWidget {
  const IllitWikiPage({
    super.key,
    required this.account,
    required this.posts,
    required this.onOpenPost,
    required this.onRefresh,
    required this.onChanged,
    required this.onAction,
    required this.onOpenProfile,
  });

  final Account account;
  final List<Post> posts;
  final void Function(Post) onOpenPost;
  final Future<void> Function() onRefresh;
  final VoidCallback onChanged;
  final void Function(Post, String) onAction;
  final void Function(Account) onOpenProfile;

  @override
  State<IllitWikiPage> createState() => _IllitWikiPageState();
}

class _IllitWikiPageState extends State<IllitWikiPage> {
  bool refreshing = false;

  Future<void> _refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final accent = theme.colorScheme.primary;

    final live = widget.posts
        .where((p) =>
            p.accountId == widget.account.id &&
            p.id.startsWith('illit-') &&
            !p.id.startsWith('illit-ficha') &&
            !p.id.startsWith('illit-members') &&
            !p.id.startsWith('illit-discografia') &&
            !p.id.startsWith('illit-records') &&
            !p.id.startsWith('illit-mma') &&
            !p.id.startsWith('illit-break') &&
            !p.id.startsWith('illit-status') &&
            !p.id.startsWith('illit-tours'))
        .toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enciclopédia ILLIT',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'Atualizar notícias',
            onPressed: refreshing ? null : _refresh,
            icon: refreshing
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          _hero(context, accent, secondary),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _quickFacts(theme, secondary),
                const SizedBox(height: 16),
                _section(
                  context,
                  title: 'Sobre o grupo',
                  icon: Icons.info_outline_rounded,
                  child: Text(
                    IllitKnowledge.about,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                ),
                _section(
                  context,
                  title: 'Integrantes',
                  icon: Icons.groups_2_outlined,
                  child: Column(
                    children: [
                      for (final member in IllitKnowledge.members) ...[
                        _memberCard(theme, member, accent, secondary),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Discografia',
                  icon: Icons.album_outlined,
                  child: Column(
                    children: [
                      for (final release in IllitKnowledge.releases)
                        _releaseCard(theme, release, accent, secondary),
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Singles, OSTs e colaborações',
                  icon: Icons.music_note_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final single in IllitKnowledge.singles)
                        _bullet(single, secondary),
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Prêmios',
                  icon: Icons.emoji_events_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final award in IllitKnowledge.awards) _bullet(award, secondary),
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Recordes e marcos',
                  icon: Icons.trending_up_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final record in IllitKnowledge.records) _bullet(record, secondary),
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Turnês e shows',
                  icon: Icons.mic_external_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final tour in IllitKnowledge.tours) _bullet(tour, secondary),
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Linha do tempo',
                  icon: Icons.timeline_rounded,
                  child: Column(
                    children: [
                      for (var i = 0; i < IllitKnowledge.timeline.length; i++)
                        _timelineItem(
                          theme,
                          IllitKnowledge.timeline[i],
                          secondary,
                          last: i == IllitKnowledge.timeline.length - 1,
                        ),
                    ],
                  ),
                ),
                _section(
                  context,
                  title: 'Links oficiais',
                  icon: Icons.link_rounded,
                  child: Column(
                    children: [
                      for (final link in IllitKnowledge.links)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.open_in_new_rounded, size: 18, color: accent),
                          title: Text(link.title,
                              style: TextStyle(fontSize: 14, color: accent)),
                          subtitle: Text(link.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, color: secondary)),
                          onTap: () => launchUrl(Uri.parse(link.body),
                              mode: LaunchMode.externalApplication),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 17, color: accent),
                          const SizedBox(width: 6),
                          const Text('Você sabia?',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final fact in IllitKnowledge.funFacts)
                        _bullet(fact, secondary),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text('Últimas notícias (ao vivo)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (refreshing)
                      const SizedBox(
                          width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Notícias, vídeos e lançamentos buscados agora no Google News, YouTube e iTunes.',
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (live.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: OutlinedButton.icon(
                onPressed: refreshing ? null : _refresh,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Buscar notícias reais do ILLIT'),
              ),
            ),
          for (final post in live.take(8))
            PostCard(
              post: post,
              onChanged: widget.onChanged,
              onAction: (action) => widget.onAction(post, action),
              onOpenThread: () => widget.onOpenPost(post),
              onOpenProfile: () => widget.onOpenProfile(widget.account),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
            child: Text(
              'Informações conferidas em ${IllitKnowledge.updatedAt} · '
              'fontes: Wikipedia, Belift Lab/HYBE, Billboard, Circle Chart, Oricon e notícias coreanas. '
              'Novidades entram sozinhas quando você puxa a timeline para baixo.',
              style: TextStyle(fontSize: 11, color: secondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, Color accent, Color secondary) {
    return Container(
      height: 168,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.85),
            const Color(0xFF8B5CF6).withValues(alpha: 0.75),
            const Color(0xFFEC4899).withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(Icons.auto_awesome_rounded,
                size: 130, color: Colors.white.withValues(alpha: 0.16)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('ILLIT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                    SizedBox(width: 8),
                    Icon(Icons.verified_rounded, color: Colors.white, size: 22),
                  ],
                ),
                Text('아일릿 · “ai-lit”',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13)),
                const Spacer(),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _heroChip(Icons.apartment_rounded, 'BELIFT LAB · HYBE'),
                    _heroChip(Icons.favorite_rounded, 'GLLIT'),
                    _heroChip(Icons.cake_rounded, '25/03/2024'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _quickFacts(ThemeData theme, Color secondary) {
    final facts = <(String, String)>[
      ('Integrantes', '5'),
      ('Estreia', '25/03/2024'),
      ('Fandom', 'GLLIT'),
      ('Agência', 'BELIFT LAB'),
      ('EPs', '5'),
      ('Singles', '10+'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runSpacing: 10,
        children: [
          for (final fact in facts)
            SizedBox(
              width: MediaQuery.of(context).size.width / 3.4,
              child: Column(
                children: [
                  Text(fact.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(fact.$1, style: TextStyle(fontSize: 11, color: secondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _bullet(String text, Color secondary) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: secondary, shape: BoxShape.circle),
              ),
            ),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.42)),
            ),
          ],
        ),
      );

  Widget _memberCard(ThemeData theme, IllitMember member, Color accent, Color secondary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(member.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(member.korean,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: secondary)),
                    ),
                  ],
                ),
                Text(
                  '${member.fullName} · ${member.birthday} · ${member.nationality}',
                  style: TextStyle(fontSize: 12, color: secondary, height: 1.3),
                ),
                const SizedBox(height: 5),
                Text(member.note, style: const TextStyle(fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _releaseCard(ThemeData theme, IllitRelease release, Color accent, Color secondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.album_rounded, color: accent, size: 22),
          ),
          title: Text(release.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          subtitle: Text(
            '${release.kind} · ${release.date}',
            style: TextStyle(fontSize: 11.5, color: secondary),
          ),
          children: [
            Text('Faixa-título: ${release.titleTrack}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Faixas: ${release.tracks.join(' · ')}',
                style: TextStyle(fontSize: 12.5, color: secondary, height: 1.35)),
            const SizedBox(height: 8),
            Text(release.note, style: const TextStyle(fontSize: 12.5, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(ThemeData theme, String text, Color secondary, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 1.4, color: theme.dividerColor),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 12),
              child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}


