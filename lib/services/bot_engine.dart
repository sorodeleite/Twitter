import 'dart:math';

import '../models.dart';

/// Motor que dá "vida" às contas de amigas e bots: respostas no jeito de
/// escrever de cada uma, DMs e pequenas variações de humor.
class BotEngine {
  static final _rng = Random();

  static List<Account> defaultAccounts() => [
        Account(
          id: 'me',
          name: 'Angel',
          handle: '@angel',
          bio: 'vivendo minha vida revisada ♡\n'
              'tudo já é meu no aqui e agora. a imaginação é a única realidade.\n'
              'esse cantinho é só meu, das minhas amigas e das nossas fixações.',
          location: 'no meu mundo ideal ✧ (a localização pode ser do tamanho que eu quiser)',
          website: 'https://github.com/sorodeleite/Twitter',
          joinedDate: 'novembro de 2026',
          avatarEmoji: '♡',
          avatarPath: 'asset:assets/images/HYGeCyRbgAAL7R_.jpg',
          bannerPath: 'asset:assets/images/HTva9CwXEAAAf5-.jpg',
          verified: true,
          isMe: true,
          autoInteract: false,
          followingCount: 4,
          followersCount: 128,
        ),
        Account(
          id: 'illit',
          name: 'ILLIT Updates',
          handle: '@illitupdates',
          bio: 'atualizações reais sobre o ILLIT (아일릿) ♡\n'
              'notícias, lançamentos, prêmios, turnês e o dia a dia das meninas.\n'
              'fandom: GLLIT · desde 2024 · ficha completa no perfil fixado',
          location: 'Seul, Coreia do Sul',
          website: 'https://beliftlab.com/artist/profile/Illit',
          joinedDate: 'março de 2024',
          avatarEmoji: '✧',
          avatarPath: 'asset:assets/images/HYGeDTaaMAAQd74.jpg',
          bannerPath: 'asset:assets/images/72451152-FA2A-4645-A1D0-5287E73383B5.jpg',
          verified: true,
          isBot: true,
          autoInteract: true,
          useLowercase: false,
          favoriteEmojis: '✧ ♡ 💿',
          styleNotes: 'Conta de atualizações oficial do ILLIT: carinhosa com GLLITs, empolgada e sempre com fonte.',
          replyTemplates: [
            'Moka e as meninas mandaram um oi pra você hoje ♡',
            'ouvindo Magnetic enquanto tudo dá certo por aí ✧',
            'energia de GLLIT abençoada hoje ♡',
            'o ILLIT mandou lembranças (e um pedacinho de "Magnetic") ✧',
          ],
          followingCount: 5,
          followersCount: 84200,
        ),
        Account(
          id: 'neville',
          name: 'vida revisada ♡',
          handle: '@revisada',
          bio: 'assuma o sentimento do desejo realizado.\n'
              'o passado muda quando você revisa na imaginação.\n'
              '— Neville Goddard',
          location: 'estado do fim',
          joinedDate: 'janeiro de 2024',
          avatarEmoji: '☁️',
          verified: true,
          isBot: true,
          autoInteract: true,
          useLowercase: true,
          favoriteEmojis: '☁️ ♡ ✧',
          styleNotes: 'Acolhedora, calma, fala da lei da suposição e da revisão como fato consumado.',
          replyTemplates: [
            'já é real, você já está vivendo isso ♡',
            'a revisão já aconteceu e a realidade só está espelhando agora ☁️',
            'continua descansando nessa certeza, já deu tudo certo ✧',
            'o seu eu revisado já tem isso garantido ♡',
            'não precisa correr atrás, só se sentir no fim ☁️',
            'o "eu já tenho" é o único estado que você precisa hoje ♡',
          ],
          followingCount: 1,
          followersCount: 3333,
        ),
        Account(
          id: 'friend-1',
          name: 'mimi',
          handle: '@mimisworld',
          bio: 'melhor amiga, fã de ILLIT e especialista em mandar print às 3h da manhã 🥺♡',
          location: 'aqui do ladinho',
          joinedDate: 'outubro de 2026',
          avatarEmoji: '🎀',
          avatarPath: 'asset:assets/images/HYGeDzGbYAArkl0.jpg',
          verified: false,
          isFriend: true,
          autoInteract: true,
          useLowercase: true,
          favoriteEmojis: '🥺 ♡ kkkk',
          styleNotes: 'Escreve tudo em minúsculo, carinhosa, animada, usa "amg", "mds", "kkkk" e muitos emojis.',
          replyTemplates: [
            'amgg simm tudo pra mim 🥺♡',
            'mds eu sabia q ia acontecer kkkk ♡',
            'ai que perfeito, você merece muito!!',
            'meu deus eu amo acompanhar sua vida assim',
            'miga isso é a coisa mais linda q eu vi hoje 🥺',
            'tô surtando por você kkkk ♡',
            'sério eu te amo tanto, ta?',
            'conta tudo depois no wpp!!',
          ],
          followingCount: 48,
          followersCount: 62,
        ),
      ];

  static const _emojisFallback = ['♡', '✨', '🥺'];

  static List<String> _emojiList(Account account) {
    final list = account.favoriteEmojis
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty && e != 'kkkk')
        .toList();
    return list.isEmpty ? _emojisFallback : list;
  }

  static String _style(Account account, String text) {
    var out = text.trim();
    if (account.useLowercase) out = out.toLowerCase();
    final emojis = _emojiList(account);
    if (emojis.isNotEmpty && !emojis.any(out.contains)) {
      out = '$out ${emojis[_rng.nextInt(emojis.length)]}';
    }
    return out;
  }

  static bool _has(String text, List<String> words) {
    final lower = text.toLowerCase();
    return words.any(lower.contains);
  }

  /// Resposta para um post seu (ou de outra conta).
  static String generateReply(Account account, Post post) {
    final text = post.text;
    final isIllitAccount = account.isIllit;
    final mine = post.accountId == 'me' || post.handle == '@angel';
    final templates = account.replyTemplates;

    if (isIllitAccount) {
      if (templates.isNotEmpty && _rng.nextDouble() < 0.45) {
        return _style(account, templates[_rng.nextInt(templates.length)]);
      }
      if (text.toLowerCase().contains('moka')) {
        return 'a Moka é um amor, manda carinho pra ela ♡ #GLLIT';
      }
      return _style(account, 'GLLITs sempre por aqui ♡ acompanhe as atualizações reais no perfil');
    }

    if (templates.isNotEmpty && _rng.nextDouble() < 0.62) {
      return _style(account, templates[_rng.nextInt(templates.length)]);
    }

    if (_has(text, ['illit', 'moka', 'wonhee', 'minju', 'yunah', 'iroha', 'kpop'])) {
      final options = [
        'a moka tá linda demais ultimamente né',
        'illit salvando o dia como sempre',
        'amo tanto as meninas sério',
        'tô ouvindo illit agora enquanto leio isso kkkk',
        'depois me manda o vídeo, preciso ver',
      ];
      return _style(account, options[_rng.nextInt(options.length)]);
    }

    if (_has(text, ['revis', 'neville', 'manifest', 'suposi', 'sonho', 'imagina'])) {
      if (account.id == 'neville') {
        return _style(account, [
          'é exatamente isso: vive no fim, não no como ☁️',
          'revisa a cena e deixa o mundo se ajustar ♡',
          'você não está pedindo, você já tem ✧',
        ][_rng.nextInt(3)]);
      }
      return _style(account, [
        'já é seu!! nem tem dúvida',
        'sinto daqui que já tá tudo realizado',
        'amando ver você vivendo exatamente o que queria',
      ][_rng.nextInt(3)]);
    }

    if (_has(text, ['triste', 'cansad', 'medo', 'ansios', 'difícil', 'difícil', 'chorar'])) {
      return _style(account, [
        'tô aqui com você, respira',
        'vai passar, e você não está sozinha',
        'te mando um abraço enorme agora',
      ][_rng.nextInt(3)]);
    }

    if (_has(text, ['trabalho', 'estudo', 'prova', 'faculdade', 'emprego'])) {
      return _style(account, [
        'boaaa, você consegue!!',
        'orgulho de você, sério',
        'já já isso vai estar resolvido',
      ][_rng.nextInt(3)]);
    }

    if (_has(text, ['amor', 'namor', 'crush', 'beij'])) {
      return _style(account, [
        'aiii conta mais!!',
        'eu surtando por você aqui',
        'esse é o tipo de post que eu amo',
      ][_rng.nextInt(3)]);
    }

    final generic = mine
        ? [
            'amg eu amo tanto quando você posta',
            'isso ficou perfeito',
            'tô aqui lendo tudo, continue',
            'que energia boa, sério',
            'salvei esse post pra mim',
          ]
        : [
            'tudo muito lindo por aqui',
            'eu amo demais isso',
            'perfeito sério',
            'tô aqui torcendo por você sempre',
          ];
    return _style(account, generic[_rng.nextInt(generic.length)]);
  }

  static String generateReplyText(Account account, String text) => generateReply(
        account,
        Post(
          id: 'tmp',
          accountId: 'me',
          name: 'você',
          handle: '@angel',
          avatarEmoji: '♡',
          text: text,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  static String generateDmReply(Account account, String message) {
    final lower = message.toLowerCase();
    String reply;
    if (_has(lower, ['oi', 'olá', 'ola', 'ei', 'bom dia', 'boa noite', 'boa tarde'])) {
      reply = account.id == 'neville'
          ? 'oi, meu bem. como está o seu fim hoje? ☁️'
          : 'oii!! tava pensando em você agora mesmo 🥺';
    } else if (_has(lower, ['obrigad', 'valeu', 'brigad'])) {
      reply = 'imaginaa, tô sempre aqui com você ♡';
    } else if (_has(lower, ['illit', 'moka'])) {
      reply = 'amg eu tava vendo foto da moka agora kkkk ela é tudo';
    } else if (_has(lower, ['triste', 'cansad', 'ansios'])) {
      reply = 'oi, respira. quer falar sobre isso? tô aqui 🥺';
    } else if (_has(lower, ['amor', 'crush', 'namor'])) {
      reply = 'conta tudooo, quero saber de cada detalhe';
    } else if (_has(lower, ['revis', 'sonho', 'neville', 'manifest'])) {
      reply = account.id == 'neville'
          ? 'já está feito. só sente como se fosse agora ☁️'
          : 'amiga eu acredito em você, já deu certo';
    } else if (lower.trim().endsWith('?')) {
      reply = 'simmm!! e pode ter certeza que já tá tudo do seu jeito';
    } else {
      reply = account.id == 'neville'
          ? 'você já é a pessoa dessa história. descansa nisso ♡'
          : 'amg simm kkkk tô rindo aqui';
    }
    return _style(account, reply);
  }

  static Duration reactionDelay(int index) =>
      Duration(milliseconds: 1800 + index * 2100 + _rng.nextInt(2200));

  static Duration dmDelay() => Duration(milliseconds: 900 + _rng.nextInt(1400));
}
