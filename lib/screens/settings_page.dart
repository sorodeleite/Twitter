import 'package:flutter/material.dart';

import '../services/updater_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.accent,
    required this.palette,
    required this.appleEmoji,
    required this.onThemeChanged,
    required this.onAccentChanged,
    required this.onEmojiChanged,
    required this.onResetData,
  });

  final ThemeMode themeMode;
  final Color accent;
  final List<Color> palette;
  final bool appleEmoji;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<Color> onAccentChanged;
  final ValueChanged<bool> onEmojiChanged;
  final Future<void> Function() onResetData;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _hexCtrl = TextEditingController();
  late ThemeMode _themeMode = widget.themeMode;
  late Color _accent = widget.accent;
  late bool _emoji = widget.appleEmoji;

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  void _applyHex() {
    var text = _hexCtrl.text.trim().replaceAll('#', '');
    if (text.length == 6) text = 'FF$text';
    final value = int.tryParse(text, radix: 16);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HEX inválido. Exemplo: #8B5CF6')),
      );
      return;
    }
    setState(() => _accent = Color(value));
    widget.onAccentChanged(Color(value));
    _hexCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.brightness == Brightness.dark
        ? const Color(0xFF71767B)
        : const Color(0xFF536471);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
        children: [
          _header('Aparência'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.brightness_auto_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Escuro'),
                icon: Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {_themeMode},
            onSelectionChanged: (value) {
              setState(() => _themeMode = value.first);
              widget.onThemeChanged(value.first);
            },
          ),
          const SizedBox(height: 18),
          _header('Cor de destaque'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in widget.palette)
                GestureDetector(
                  onTap: () {
                    setState(() => _accent = color);
                    widget.onAccentChanged(color);
                  },
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: color,
                    child: _accent.toARGB32() == color.toARGB32()
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'HEX personalizado',
                    hintText: '#8B5CF6',
                  ),
                  onSubmitted: (_) => _applyHex(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: _applyHex, child: const Text('Aplicar')),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emojis estilo iPhone'),
            subtitle: Text(
              'Usa a fonte de emojis da Apple no app inteiro',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            value: _emoji,
            onChanged: (value) {
              setState(() => _emoji = value);
              widget.onEmojiChanged(value);
            },
          ),
          const Divider(height: 26),
          _header('Atualizações'),
          const SizedBox(height: 6),
          Text(
            'O botão ⋮ no topo (e este aqui) procura o release mais recente no GitHub, '
            'baixa o APK e abre o instalador — igual ao Little Pause e ao Sleep My Angel.',
            style: TextStyle(fontSize: 13, color: secondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Versão instalada: ${UpdaterService.currentBuildNumber > 0 ? 'build #${UpdaterService.currentBuildNumber}' : 'build local (debug)'}\n'
              'Repositório: github.com/${UpdaterService.repo}',
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => UpdaterService.showUpdateDialog(context),
            icon: const Icon(Icons.system_update_rounded, size: 19),
            label: const Text('Procurar atualização'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: const StadiumBorder(),
            ),
          ),
          const Divider(height: 26),
          _header('Dados'),
          const SizedBox(height: 6),
          Text(
            'Suas contas, posts, notificações e conversas ficam só neste aparelho.',
            style: TextStyle(fontSize: 13, color: secondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Apagar tudo?'),
                  content: const Text(
                    'Isso remove posts, curtidas, DMs, notificações e contas criadas por você. '
                    'Não dá para desfazer.',
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Apagar'),
                    ),
                  ],
                ),
              );
              if (yes == true) {
                await widget.onResetData();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tudo apagado. O app começou de novo ♡')),
                );
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Apagar todos os dados'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Twitter · vida revisada ♡',
              style: TextStyle(color: secondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
      );
}

