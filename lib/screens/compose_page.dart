import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/media_store.dart';
import '../widgets/avatar_widget.dart';

/// Compositor em tela cheia, no estilo do X.
class ComposePage extends StatefulWidget {
  const ComposePage({
    super.key,
    required this.accounts,
    required this.initialAccount,
    required this.onSubmit,
    this.replyTo,
  });

  final List<Account> accounts;
  final Account initialAccount;
  final void Function(Account author, String text, String? imagePath) onSubmit;
  final Post? replyTo;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  static const int maxLength = 1000;

  late final TextEditingController _controller =
      TextEditingController(text: widget.replyTo == null ? '' : '');
  late Account _author = widget.initialAccount;
  final _picker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPost =>
      (_controller.text.trim().isNotEmpty || _imagePath != null) &&
      _controller.text.characters.length <= maxLength;

  void _submit() {
    if (!_canPost) return;
    final text = _controller.text.trim();
    final image = _imagePath;
    widget.onSubmit(_author, text, image);
    Navigator.pop(context);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file != null && mounted) {
        final saved = await MediaStore.persist(file.path);
        if (!mounted) return;
        setState(() => _imagePath = saved);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui abrir a câmera/galeria agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final primaryText = isDark ? const Color(0xFFE7E9EA) : const Color(0xFF0F1419);
    final accent = theme.colorScheme.primary;
    final length = _controller.text.characters.length;
    final remaining = maxLength - length;
    final overLimit = remaining < 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Descartar',
        ),
        titleSpacing: 0,
        title: const Text('Criar post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _canPost ? _submit : null,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: Text(widget.replyTo == null ? 'Postar' : 'Responder'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                children: [
                  Row(
                    children: [
                      Icon(Icons.public_rounded, size: 15, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'Todos podem responder',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  if (widget.replyTo != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Respondendo a ${widget.replyTo!.handle}',
                      style: TextStyle(color: secondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarWidget(
                        emoji: _author.avatarEmoji,
                        imagePath: _author.avatarPath,
                        radius: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: widget.accounts.length > 1 ? _chooseAuthor : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _author.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: primaryText,
                                      ),
                                    ),
                                    if (_author.verified) ...[
                                      const SizedBox(width: 3),
                                      VerifiedBadge(size: 15),
                                    ],
                                    const SizedBox(width: 6),
                                    if (widget.accounts.length > 1)
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          size: 18, color: secondary),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              _author.handle,
                              style: TextStyle(color: secondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(fontSize: 19, height: 1.35, color: primaryText),
                      decoration: InputDecoration(
                        hintText: widget.replyTo == null
                            ? 'O que está acontecendo na sua vida revisada?'
                            : 'Poste sua resposta',
                        hintStyle: TextStyle(fontSize: 19, color: secondary),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                      ),
                    ),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 54),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 320),
                              child: Image.file(
                                File(_imagePath!),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(alpha: 0.65),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _imagePath = null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Galeria',
                          onPressed: () => _pick(ImageSource.gallery),
                          icon: Icon(Icons.photo_outlined, color: accent),
                        ),
                        IconButton(
                          tooltip: 'Câmera',
                          onPressed: () => _pick(ImageSource.camera),
                          icon: Icon(Icons.camera_alt_outlined, color: accent),
                        ),
                        IconButton(
                          tooltip: 'Emoji',
                          onPressed: _openEmojiPicker,
                          icon: Icon(Icons.emoji_emotions_outlined, color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor, width: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 18, color: secondary),
                  const SizedBox(width: 4),
                  Text('Mídia', style: TextStyle(fontSize: 12.5, color: secondary)),
                  const Spacer(),
                  if (length > 0)
                    Text(
                      '$length/$maxLength',
                      style: TextStyle(
                        color: overLimit ? const Color(0xFFF4212E) : secondary,
                        fontSize: 12.5,
                        fontWeight: overLimit ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  if (length > 0) const SizedBox(width: 10),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: overLimit ? 1 : (length / maxLength).clamp(0.0, 1.0),
                          strokeWidth: 2.6,
                          backgroundColor: theme.dividerColor,
                          color: overLimit
                              ? const Color(0xFFF4212E)
                              : (remaining <= 40 ? const Color(0xFFFFD400) : accent),
                        ),
                        if (remaining <= 40)
                          Text(
                            '$remaining',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: overLimit ? const Color(0xFFF4212E) : secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _chooseAuthor() {
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
                child: Text('Postar como',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              for (final account in widget.accounts)
                ListTile(
                  leading: AvatarWidget(
                    emoji: account.avatarEmoji,
                    imagePath: account.avatarPath,
                    radius: 20,
                  ),
                  title: Text(account.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(account.handle),
                  trailing: account.id == _author.id
                      ? Icon(Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _author = account);
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

  void _openEmojiPicker() {
    const emojis = [
      '♡', '✧', '🥺', '✨', '☁️', '🌷', '🍡', '🐆', '🐰', '🐈', '💿', '🎤',
      '😭', '😍', '🥹', '😺', '🫶', '💌', '🩷', '🦋', '🌈', '🌙', '⭐', '🕊️',
      '😂', '😅', '🙈', '👀', '💅', '🧸', '🍓', '🥰', '💐', '🫧', '🎀', '🪞',
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final emoji in emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    final value = _controller.value;
                    final selection = value.selection;
                    final text = value.text;
                    final start = selection.start >= 0 ? selection.start : text.length;
                    final end = selection.end >= 0 ? selection.end : text.length;
                    final newText = text.replaceRange(start, end, emoji);
                    _controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: start + emoji.length),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
