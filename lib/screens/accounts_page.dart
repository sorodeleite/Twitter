import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/media_store.dart';
import '../widgets/avatar_widget.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
    required this.accounts,
    required this.onAccountsChanged,
    required this.onPostAsAccount,
    required this.onOpenProfile,
  });

  final List<Account> accounts;
  final VoidCallback onAccountsChanged;
  final void Function(Account) onPostAsAccount;
  final void Function(Account) onOpenProfile;

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friends = widget.accounts.where((a) => !a.isMe && a.isFriend).toList();
    final bots = widget.accounts.where((a) => !a.isMe && !a.isFriend).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas & Bots', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          FilledButton.icon(
            onPressed: () => _openEditor(context, null),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Criar'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Text(
            'Crie as contas das suas amigas e os bots. Cada uma interage do jeitinho dela: '
            'curte, reposta, responde e conversa por DM. Você define bio e localização do tamanho '
            'que quiser, escolhe a foto e ensina o jeito de escrever — cole mensagens reais e o app '
            'copia o estilo.',
            style: TextStyle(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF71767B)
                  : const Color(0xFF536471),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('AMIGAS', friends.length),
          if (friends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhuma amiga adicionada ainda. Toque em "Criar"!',
                  style: TextStyle(color: Colors.grey)),
            ),
          for (final acc in friends) _accountTile(context, acc),
          const SizedBox(height: 20),
          _sectionTitle('BOTS & ATUALIZAÇÕES', bots.length),
          for (final acc in bots) _accountTile(context, acc),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label, int count) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(width: 6),
            Text('($count)', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
      );

  Widget _accountTile(BuildContext context, Account acc) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpenProfile(acc),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              AvatarWidget(
                emoji: acc.avatarEmoji,
                imagePath: acc.avatarPath,
                radius: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            acc.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        if (acc.verified) ...[
                          const SizedBox(width: 4),
                          VerifiedBadge(size: 15),
                        ],
                      ],
                    ),
                    Text(
                      '${acc.handle} · ${acc.isBot ? 'bot' : 'amiga'}'
                      '${acc.autoInteract ? ' · interage nos seus tweets' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (acc.bio.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          acc.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) async {
                  switch (value) {
                    case 'post':
                      Navigator.pop(context);
                      widget.onPostAsAccount(acc);
                      break;
                    case 'edit':
                      _openEditor(context, acc);
                      break;
                    case 'profile':
                      widget.onOpenProfile(acc);
                      break;
                    case 'delete':
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Remover ${acc.name}?'),
                          content: const Text(
                            'A conta sai da lista, mas os posts dela continuam na timeline.',
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remover'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        widget.accounts.remove(acc);
                        widget.onAccountsChanged();
                      }
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'post', child: Text('Postar como esta conta')),
                  const PopupMenuItem(value: 'edit', child: Text('Editar dados & estilo')),
                  const PopupMenuItem(value: 'profile', child: Text('Ver perfil')),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: acc.id != 'illit' && acc.id != 'me',
                    child: Text(
                      'Remover conta',
                      style: TextStyle(color: acc.id == 'illit' ? Colors.grey : Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, Account? existing) {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final handleCtrl = TextEditingController(text: existing?.handle ?? '@');
    final bioCtrl = TextEditingController(text: existing?.bio ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final siteCtrl = TextEditingController(text: existing?.website ?? '');
    final joinedCtrl = TextEditingController(text: existing?.joinedDate ?? 'novembro de 2026');
    final emojiCtrl = TextEditingController(text: existing?.avatarEmoji ?? '🎀');
    final favEmojisCtrl = TextEditingController(text: existing?.favoriteEmojis ?? '♡ ✨ kkkk');
    final templatesCtrl = TextEditingController(text: (existing?.replyTemplates ?? []).join('\n'));
    final samplesCtrl = TextEditingController(text: (existing?.examplePosts ?? []).join('\n'));
    final styleNotesCtrl = TextEditingController(text: existing?.styleNotes ?? '');
    final followingCtrl = TextEditingController(text: '${existing?.followingCount ?? 24}');
    final followersCtrl = TextEditingController(text: '${existing?.followersCount ?? 48}');
    String? avatarPath = existing?.avatarPath;
    String? bannerPath = existing?.bannerPath;
    bool isFriend = existing?.isFriend ?? true;
    bool verified = existing?.verified ?? false;
    bool autoInteract = existing?.autoInteract ?? true;
    bool useLowercase = existing?.useLowercase ?? true;
    final picker = ImagePicker();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                        isNew ? 'Nova conta' : 'Editar conta',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        var handle = handleCtrl.text.trim();
                        if (handle.isEmpty || handle == '@') {
                          handle = '@${name.toLowerCase().replaceAll(RegExp(r'\s+'), '')}';
                        } else if (!handle.startsWith('@')) {
                          handle = '@$handle';
                        }
                        final templates = templatesCtrl.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        final samples = samplesCtrl.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        if (isNew) {
                          widget.accounts.add(Account(
                            id: 'acc-${DateTime.now().microsecondsSinceEpoch}',
                            name: name,
                            handle: handle,
                            bio: bioCtrl.text,
                            location: locCtrl.text,
                            website: siteCtrl.text.trim(),
                            joinedDate: joinedCtrl.text.trim().isEmpty
                                ? 'novembro de 2026'
                                : joinedCtrl.text.trim(),
                            avatarEmoji:
                                emojiCtrl.text.trim().isEmpty ? '♡' : emojiCtrl.text.trim(),
                            avatarPath: avatarPath,
                            bannerPath: bannerPath,
                            verified: verified,
                            isFriend: isFriend,
                            isBot: !isFriend,
                            autoInteract: autoInteract,
                            useLowercase: useLowercase,
                            favoriteEmojis: favEmojisCtrl.text.trim(),
                            styleNotes: styleNotesCtrl.text.trim(),
                            replyTemplates: templates,
                            examplePosts: samples,
                            followingCount: int.tryParse(followingCtrl.text.trim()) ?? 24,
                            followersCount: int.tryParse(followersCtrl.text.trim()) ?? 48,
                          ));
                        } else {
                          existing.name = name;
                          existing.handle = handle;
                          existing.bio = bioCtrl.text;
                          existing.location = locCtrl.text;
                          existing.website = siteCtrl.text.trim();
                          existing.joinedDate = joinedCtrl.text.trim();
                          existing.avatarEmoji =
                              emojiCtrl.text.trim().isEmpty ? '♡' : emojiCtrl.text.trim();
                          existing.avatarPath = avatarPath;
                          existing.bannerPath = bannerPath;
                          existing.verified = verified;
                          existing.isFriend = isFriend;
                          existing.isBot = !isFriend;
                          existing.autoInteract = autoInteract;
                          existing.useLowercase = useLowercase;
                          existing.favoriteEmojis = favEmojisCtrl.text.trim();
                          existing.styleNotes = styleNotesCtrl.text.trim();
                          existing.replyTemplates = templates;
                          existing.examplePosts = samples;
                          existing.followingCount =
                              int.tryParse(followingCtrl.text.trim()) ?? existing.followingCount;
                          existing.followersCount =
                              int.tryParse(followersCtrl.text.trim()) ?? existing.followersCount;
                        }
                        widget.onAccountsChanged();
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AvatarWidget(
                      emoji: emojiCtrl.text.isEmpty ? '♡' : emojiCtrl.text,
                      imagePath: avatarPath,
                      radius: 27,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final f = await picker.pickImage(
                                  source: ImageSource.gallery, imageQuality: 88);
                              if (f != null) {
                                final saved = await MediaStore.persist(f.path);
                                setModalState(() => avatarPath = saved);
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined, size: 17),
                            label: const Text('Foto de perfil'),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final f = await picker.pickImage(
                                  source: ImageSource.gallery, imageQuality: 88);
                              if (f != null) {
                                final saved = await MediaStore.persist(f.path);
                                setModalState(() => bannerPath = saved);
                              }
                            },
                            icon: const Icon(Icons.panorama_outlined, size: 17),
                            label: const Text('Foto de capa'),
                          ),
                        ],
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
                  minLines: 3,
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
                    labelText: 'Localização (do tamanho que quiser)',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: siteCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(labelText: 'Link / site'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: joinedCtrl,
                        decoration: const InputDecoration(labelText: 'Ingressou em'),
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
                const SizedBox(height: 18),
                const Text('JEITO DE ESCREVER',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(
                  'Cole abaixo mensagens reais dela (uma por linha). O app copia o estilo: '
                  'minúsculas, emojis, "kkkk" e transforma as frases nas respostas automáticas.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: samplesCtrl,
                  minLines: 3,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Como ela escreve (exemplos)',
                    hintText: 'amg eu amei isso kkkk 🥺\nmeu deus que lindo\nconta tudo!!',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final analysis = _analyzeStyle(samplesCtrl.text);
                    if (analysis.templates.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cole pelo menos uma frase para eu copiar ♡')),
                      );
                      return;
                    }
                    setModalState(() {
                      templatesCtrl.text = analysis.templates.join('\n');
                      if (analysis.emojis.isNotEmpty) {
                        favEmojisCtrl.text = analysis.emojis;
                      }
                      useLowercase = analysis.lowercase;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Estilo copiado: ${analysis.templates.length} frase(s), '
                          '${analysis.emojis.isEmpty ? 'sem emojis' : analysis.emojis}'
                          '${analysis.lowercase ? ', tudo em minúsculo' : ''} ♡',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Copiar o jeito de escrever'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: templatesCtrl,
                  minLines: 4,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Respostas automáticas (1 por linha)',
                    hintText: 'amg simm tudo pra mim 🥺♡\nmds eu sabia kkkk',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: favEmojisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Emojis / risadas preferidas',
                    hintText: 'ex: 🥺 ♡ kkkk 😭',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: styleNotesCtrl,
                  minLines: 2,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Personalidade (opcional)',
                    hintText: 'ex: carinhosa, fala rápido, surta com ILLIT',
                    alignLabelWithHint: true,
                  ),
                ),
                ..._switches(
                  isFriend: isFriend,
                  useLowercase: useLowercase,
                  autoInteract: autoInteract,
                  verified: verified,
                  onFriend: (v) => setModalState(() => isFriend = v),
                  onLowercase: (v) => setModalState(() => useLowercase = v),
                  onAuto: (v) => setModalState(() => autoInteract = v),
                  onVerified: (v) => setModalState(() => verified = v),
                ),
                const SizedBox(height: 8),
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
        joinedCtrl.dispose();
        emojiCtrl.dispose();
        favEmojisCtrl.dispose();
        templatesCtrl.dispose();
        samplesCtrl.dispose();
        styleNotesCtrl.dispose();
        followingCtrl.dispose();
        followersCtrl.dispose();
      });
    });
  }

  List<Widget> _switches({
    required bool isFriend,
    required bool useLowercase,
    required bool autoInteract,
    required bool verified,
    required ValueChanged<bool> onFriend,
    required ValueChanged<bool> onLowercase,
    required ValueChanged<bool> onAuto,
    required ValueChanged<bool> onVerified,
  }) =>
      [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Conta de amiga'),
          subtitle: const Text('Desative para ser um bot de tema/notícias'),
          value: isFriend,
          onChanged: onFriend,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Escreve tudo em minúsculo'),
          value: useLowercase,
          onChanged: onLowercase,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Interagir automaticamente nos meus tweets'),
          value: autoInteract,
          onChanged: onAuto,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Selo verificado'),
          value: verified,
          onChanged: onVerified,
        ),
      ];

  _StyleAnalysis _analyzeStyle(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final letters = RegExp(r'[A-ZÀ-Þ]').allMatches(raw).length;
    final lowerLetters = RegExp(r'[a-zà-þ]').allMatches(raw).length;
    final emojiRegex =
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F900}-\u{1F9FF}]', unicode: true);
    final emojis = <String>{};
    for (final m in emojiRegex.allMatches(raw)) {
      emojis.add(m.group(0)!);
    }
    if (RegExp(r'k{3,}', caseSensitive: false).hasMatch(raw)) emojis.add('kkkk');
    final totalLetters = letters + lowerLetters;
    return _StyleAnalysis(
      templates: lines.take(14).toList(),
      emojis: emojis.take(6).join(' '),
      lowercase: totalLetters == 0 || letters / totalLetters < 0.08,
    );
  }
}

class _StyleAnalysis {
  _StyleAnalysis({
    required this.templates,
    required this.emojis,
    required this.lowercase,
  });

  final List<String> templates;
  final String emojis;
  final bool lowercase;
}

