import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/bot_engine.dart';
import '../widgets/avatar_widget.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
    required this.accounts,
    required this.threads,
    required this.onOpenChat,
  });

  final List<Account> accounts;
  final Map<String, List<DmMessage>> threads;
  final void Function(Account) onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? const Color(0xFF71767B)
        : const Color(0xFF536471);
    final contacts = accounts.where((a) => !a.isMe).toList();

    if (contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Crie uma conta de amiga ou bot para conversar por DM ♡',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary),
          ),
        ),
      );
    }

    final withMessages = contacts
        .where((a) => (threads[a.id] ?? []).isNotEmpty)
        .toList()
      ..sort((a, b) {
        final ta = (threads[a.id] ?? []).last.createdAtMs;
        final tb = (threads[b.id] ?? []).last.createdAtMs;
        return tb.compareTo(ta);
      });
    final withoutMessages = contacts.where((a) => (threads[a.id] ?? []).isEmpty).toList();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 19, color: secondary),
                const SizedBox(width: 10),
                Text('Buscar mensagens', style: TextStyle(color: secondary, fontSize: 14)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              const Text('Mensagens',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const Spacer(),
              Icon(Icons.edit_square, size: 20, color: theme.colorScheme.primary),
            ],
          ),
        ),
        if (withMessages.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mail_outline_rounded,
                      size: 34, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                const Text('Bem-vinda às suas mensagens',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Conversas privadas com suas amigas e bots. Toque em uma conta abaixo para começar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: secondary, fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _showContacts(context, contacts, secondary),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  child: const Text('Escrever uma mensagem'),
                ),
              ],
            ),
          ),
        for (final acc in withMessages) _conversation(context, acc, secondary),
        if (withoutMessages.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text('SUGERIDOS',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w800, color: secondary, letterSpacing: 1)),
          ),
          for (final acc in withoutMessages) _conversation(context, acc, secondary),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _conversation(BuildContext context, Account acc, Color secondary) {
    final theme = Theme.of(context);
    final msgs = threads[acc.id] ?? [];
    final last = msgs.isNotEmpty ? msgs.last : null;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: AvatarWidget(
            emoji: acc.avatarEmoji,
            imagePath: acc.avatarPath,
            radius: 24,
          ),
          title: Row(
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
                VerifiedBadge(size: 14),
              ],
              const SizedBox(width: 5),
              Flexible(
                child: Text(acc.handle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 13)),
              ),
              if (last != null) ...[
                Text(' · ', style: TextStyle(color: secondary, fontSize: 13)),
                Text(formatRelativeTime(last.createdAtMs),
                    style: TextStyle(color: secondary, fontSize: 13)),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              last != null
                  ? (last.senderId == 'me' ? 'Você: ${last.text}' : last.text)
                  : 'Toque para mandar uma mensagem',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: last == null ? secondary : null,
                fontSize: 13.5,
              ),
            ),
          ),
          onTap: () => onOpenChat(acc),
        ),
        Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor),
      ],
    );
  }

  void _showContacts(BuildContext context, List<Account> contacts, Color secondary) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Escolha a conversa',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              for (final acc in contacts)
                ListTile(
                  leading: AvatarWidget(
                    emoji: acc.avatarEmoji,
                    imagePath: acc.avatarPath,
                    radius: 20,
                  ),
                  title: Text(acc.name),
                  subtitle: Text(acc.handle),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOpenChat(acc);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class DmChatPage extends StatefulWidget {
  const DmChatPage({
    super.key,
    required this.account,
    required this.messages,
    required this.onChanged,
  });

  final Account account;
  final List<DmMessage> messages;
  final VoidCallback onChanged;

  @override
  State<DmChatPage> createState() => _DmChatPageState();
}

class _DmChatPageState extends State<DmChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  Timer? _typingTimer;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.messages.add(DmMessage(
        id: 'dm-${DateTime.now().microsecondsSinceEpoch}',
        senderId: 'me',
        text: text,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      _ctrl.clear();
      _typing = true;
    });
    widget.onChanged();
    _scrollToEnd();

    _typingTimer?.cancel();
    _typingTimer = Timer(BotEngine.dmDelay(), () {
      if (!mounted) return;
      final replyText = BotEngine.generateDmReply(widget.account, text);
      setState(() {
        _typing = false;
        widget.messages.add(DmMessage(
          id: 'dm-bot-${DateTime.now().microsecondsSinceEpoch}',
          senderId: widget.account.id,
          text: replyText,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ));
      });
      widget.onChanged();
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final secondary = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(
              emoji: widget.account.avatarEmoji,
              imagePath: widget.account.avatarPath,
              radius: 17,
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
                          widget.account.name,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (widget.account.verified) ...[
                        const SizedBox(width: 3),
                        VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  Text(
                    _typing ? 'digitando…' : widget.account.handle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _typing ? accent : secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvatarWidget(
                            emoji: widget.account.avatarEmoji,
                            imagePath: widget.account.avatarPath,
                            radius: 34,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.account.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                          Text(widget.account.handle,
                              style: TextStyle(color: secondary, fontSize: 13)),
                          const SizedBox(height: 14),
                          Text(
                            'Comece uma conversa ♡ ${widget.account.isBot ? 'essa conta responde no estilo dela.' : ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: secondary, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, i) {
                      final m = widget.messages[i];
                      final isMe = m.senderId == 'me';
                      final previous = i > 0 ? widget.messages[i - 1] : null;
                      final showDate = previous == null ||
                          !_sameDay(previous.createdAtMs, m.createdAtMs);
                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                _dateLabel(m.createdAtMs),
                                style: TextStyle(color: secondary, fontSize: 11.5),
                              ),
                            ),
                          Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.76,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? accent
                                    : (isDark
                                        ? const Color(0xFF2F3336)
                                        : const Color(0xFFEFF3F4)),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                                  bottomRight: Radius.circular(isMe ? 6 : 20),
                                ),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : null,
                                  fontSize: 14.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor, width: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Enviar mensagem…',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(backgroundColor: accent),
                    tooltip: 'Enviar',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(int a, int b) {
    final da = DateTime.fromMillisecondsSinceEpoch(a);
    final db = DateTime.fromMillisecondsSinceEpoch(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  String _dateLabel(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (_sameDay(ms, now.millisecondsSinceEpoch)) return 'Hoje';
    return '${dt.day} de ${monthsPt[dt.month - 1]}';
  }
}
