/// Fatos reais sobre o ILLIT (아일릿) usados pela conta @illitupdates.
///
/// Informações conferidas em novembro de 2026 (Wikipedia EN/PT, Belift Lab,
/// Oricon, Circle Chart, Billboard e notícias coreanas). O app também busca
/// notícias e lançamentos ao vivo; esta base garante que a conta seja
/// completa mesmo sem internet.
class IllitMember {
  const IllitMember({
    required this.name,
    required this.fullName,
    required this.korean,
    required this.birthday,
    required this.nationality,
    required this.emoji,
    required this.note,
  });

  final String name;
  final String fullName;
  final String korean;
  final String birthday;
  final String nationality;
  final String emoji;
  final String note;
}

class IllitRelease {
  const IllitRelease({
    required this.kind,
    required this.title,
    required this.date,
    required this.titleTrack,
    required this.tracks,
    required this.note,
  });

  final String kind;
  final String title;
  final String date;
  final String titleTrack;
  final List<String> tracks;
  final String note;
}

class IllitFact {
  const IllitFact(this.title, this.body);
  final String title;
  final String body;
}

class IllitKnowledge {
  static const updatedAt = '27 de novembro de 2026';
  static const group = 'ILLIT';
  static const koreanName = '아일릿';
  static const fandom = 'GLLIT (글릿)';
  static const label = 'BELIFT LAB (HYBE)';
  static const debut = '25 de março de 2024';
  static const colors = 'Super Real Me · I\'ll Like You · Bomb · Mamihlapinatapai · Break Even';

  static const about =
      'ILLIT (아일릿, "ai-lit") é um girl group sul-coreano de cinco integrantes formado pela BELIFT LAB, '
      'sublabel da HYBE, através do reality show "R U Next?" da JTBC (2023). O grupo estreou em '
      '25 de março de 2024 com o EP "Super Real Me" e o single "Magnetic", que liderou a Circle Digital '
      'Chart e virou febre mundial. É o terceiro girl group da HYBE, depois de LE SSERAFIM e NewJeans. '
      'O fandom se chama GLLIT (글릿), nome anunciado em 1º de setembro de 2024 e inspirado em "glitter" — '
      'as pessoas que brilham aos olhos do ILLIT e fazem o grupo brilhar também.';

  static const members = <IllitMember>[
    IllitMember(
      name: 'Yunah',
      fullName: 'Noh Yunah',
      korean: '노윤아 · 윤아',
      birthday: '15 de janeiro de 2004',
      nationality: 'Coreia do Sul (Chungju)',
      emoji: '🐆',
      note: 'A mais velha do grupo. Participou do "R U Next?" e é uma das vozes que assina letras do ILLIT '
          '(créditos em "Do the Dance" e "You\'re Under Arrest").',
    ),
    IllitMember(
      name: 'Minju',
      fullName: 'Park Minju',
      korean: '박민주 · 민주',
      birthday: '11 de maio de 2004',
      nationality: 'Coreia do Sul',
      emoji: '🐰',
      note: 'Vocalista e uma das caras do grupo, muito lembrada pelos fancams e pela presença de palco. '
          'Assina "Love, Older You" junto com as outras integrantes.',
    ),
    IllitMember(
      name: 'Moka',
      fullName: 'Sakai Moka',
      korean: '사카이 모카 · 모카',
      birthday: '8 de outubro de 2004',
      nationality: 'Japão',
      emoji: '🍡',
      note: 'Integrante japonesa, conhecida pela expressividade e pelo vocal doce. Está em hiato desde '
          '19 de junho de 2026 por questões de saúde (ansiedade e tensão excessiva), após uma primeira '
          'pausa em abril do mesmo ano.',
    ),
    IllitMember(
      name: 'Wonhee',
      fullName: 'Lee Wonhee',
      korean: '이원희 · 원희',
      birthday: '26 de junho de 2007',
      nationality: 'Coreia do Sul',
      emoji: '🐈',
      note: 'Escolhida pelo público no "R U Next?" e um dos rostos mais virais do grupo. Em novembro de '
          '2026 ficou em recuperação de febre e de uma lesão no tornozelo.',
    ),
    IllitMember(
      name: 'Iroha',
      fullName: 'Hokazono Iroha',
      korean: '호카조노 이로하 · 이로하',
      birthday: '4 de fevereiro de 2008',
      nationality: 'Japão',
      emoji: '🌷',
      note: 'A maknae (mais nova) e integrante japonesa. Assina letras como "Paw, Paw!" e "Love, Older You". '
          'Também tratando lesão no tornozelo em novembro de 2026.',
    ),
  ];

  static const releases = <IllitRelease>[
    IllitRelease(
      kind: 'EP · 1º mini álbum',
      title: 'Super Real Me',
      date: '25 de março de 2024',
      titleTrack: 'Magnetic',
      tracks: ['My World', 'Magnetic', 'Midnight Fiction', 'Lucky Girl Syndrome'],
      note: 'Estreia. "Magnetic" liderou a Circle Digital Chart, entrou no Billboard Hot 100 (#91) e fez '
          'do ILLIT o ato de K-pop mais rápido a chegar ao Hot 100 e o primeiro grupo de K-pop a entrar '
          'no UK Official Singles com o single de estreia. Álbum: #93 na Billboard 200 e 2× Platina na Coreia.',
    ),
    IllitRelease(
      kind: 'EP · 2º mini álbum',
      title: 'I\'ll Like You',
      date: '21 de outubro de 2024',
      titleTrack: 'Cherish (My Love)',
      tracks: ['I\'ll Like You', 'Cherish (My Love)', 'IYKYK', 'Pimple', 'Tick-Tack'],
      note: 'Entrou na Billboard 200 (#94). O MV de "Tick-Tack" passou de 10 milhões de views em 16 horas. '
          'Em 22 de novembro saiu "Baby It\'s Both", versão em inglês de "Tick-Tack" com Ava Max.',
    ),
    IllitRelease(
      kind: 'EP · 3º mini álbum',
      title: 'Bomb',
      date: '16 de junho de 2025',
      titleTrack: 'Do the Dance (빌려온 고양이)',
      tracks: ['Little Monster', 'Do the Dance', 'Jellyous', 'Oops!', '밤소풍 (Night Picnic)'],
      note: 'Terceiro EP, certificado Platina na Coreia (250 mil cópias). "Jellyous" ganhou MV em 6 de '
          'julho e uma versão com Sophie Powers em agosto.',
    ),
    IllitRelease(
      kind: 'EP · 4º mini álbum',
      title: 'Mamihlapinatapai',
      date: '30 de abril de 2026',
      titleTrack: 'It\'s Me',
      tracks: ['GRWM (Get Ready With Me)', 'It\'s Me', 'Paw, Paw!', 'Mamihlapinatapai', 'Love, Older You'],
      note: 'Anunciado no show de Seul da turnê Press Start (15 de março de 2026). "It\'s Me" concorreu a '
          'Best Dance Performance no MAMA 2026.',
    ),
    IllitRelease(
      kind: 'EP · 5º mini álbum',
      title: 'Break Even',
      date: '26 de outubro de 2026',
      titleTrack: 'You\'re Under Arrest (체포하겠어)',
      tracks: ['Super in Love', 'More', 'You\'re Under Arrest', 'Pop'],
      note: 'O lançamento mais recente. A faixa-título foi apresentada uma semana antes, no show de Incheon. '
          'Em 18 de novembro a BELIFT reduziu a agenda de divulgação por problemas de saúde das integrantes.',
    ),
  ];

  static const singles = <String>[
    'Almond Chocolate — 14/02/2025 (1ª música original japonesa, OST do filme "It Takes More Than a Pretty Face to Fall in Love"; versão coreana em 10/03/2025)',
    'See U Tonight — 2025, com Kylie Cantrall (Yunah e Minju participam do EP "B.O.Y.")',
    'Toki Yo Tomare (時よ止まれ) — 01/09/2025 (1º maxi single japonês; inclui "Topping", pré-lançada em 11/08)',
    'Secret Quest (비밀찾기) — 04/11/2025 (ending de "Pokémon Horizons: Rising Hope")',
    'Not Cute Anymore — 24/11/2025 (1º single album coreano)',
    'Sunday Morning — 13/01/2026 (2º single japonês; opening da 2ª temporada de "Tis Time for Torture, Princess")',
    'Iconic by Mistake — 12/06/2026 (single colaborativo com LE SSERAFIM e KATSEYE)',
    'I Got Your Back — 26/07/2026 (single japonês com Jisoo e Momoka, do HANA; versão coreana em 17/08/2026)',
    'Swingin\' Magic — 21/09/2026 (single digital japonês, tema do anime "Magical Sisters LuluttoLilly")',
    'You\'re Under Arrest — 26/10/2026 (faixa-título de "Break Even")',
  ];

  static const awards = <String>[
    '66º Japan Record Awards (2024) — New Artist Award',
    'MAMA 2024 — Best New Artist – Female',
    '34º Seoul Music Awards (2025) — Best Group',
    'MMA 2026 (15/11/2026, Gocheok Sky Dome) — Top 10, Global Top 10, Best Performance Female e Global Impact Artist (4 prêmios na mesma noite)',
    'Billboard — primeira "K-Pop Rookie of the Month" da história (junho de 2024)',
  ];

  static const records = <String>[
    '"Magnetic" é o primeiro single de estreia de um ato de K-pop a entrar no Billboard Hot 100 (#91) e o ILLIT foi o ato de K-pop mais rápido a aparecer no chart.',
    'Primeiro grupo de K-pop a entrar no UK Official Singles com o single de estreia ("Magnetic", #80).',
    '"Super Real Me" vendeu cerca de 738 mil cópias na Coreia e ganhou certificação 2× Platina da KMCA.',
    '"Bomb" ganhou Platina da KMCA (250 mil cópias).',
    '"Tick-Tack" ultrapassou 10 milhões de views no YouTube em 16 horas.',
    'Terceiro girl group da HYBE, depois de LE SSERAFIM e NewJeans.',
  ];

  static const tours = <String>[
    'Glitter Day (fan concert, 2025) — Seul (7 e 8/06), Yokohama (10 e 11/08), Osaka (3 e 4/09) e Seul de novo (8 e 9/11).',
    'Press Start (1ª turnê, 2026) — Seul (março), Aichi (junho) e Incheon (outubro). Foi no show de Seul que "Mamihlapinatapai" foi anunciado; em Aichi, "I Got Your Back".',
  ];

  static const timeline = <String>[
    '30/06 a 01/09/2023 — "R U Next?" (JTBC): 22 participantes disputam o novo girl group da BELIFT LAB. A lineup final: Wonhee, Youngseo, Minju, Iroha, Moka e Yunah.',
    '05/01/2024 — Youngseo deixa o grupo antes da estreia; o ILLIT segue com cinco integrantes.',
    '28/02/2024 — Primeira aparição pública no desfile da Acne Studios, em Paris, antes da estreia.',
    '25/03/2024 — Estreia com "Super Real Me" e "Magnetic".',
    '01/09/2024 — Anúncio oficial do fandom GLLIT.',
    '21/10/2024 — "I\'ll Like You" e "Cherish (My Love)".',
    '14/02/2025 — "Almond Chocolate", primeira música original japonesa.',
    '16/06/2025 — "Bomb" e "Do the Dance".',
    '01/09/2025 — Estreia japonesa com "Toki Yo Tomare".',
    '24/11/2025 — Primeiro single album coreano, "Not Cute Anymore".',
    '13/01/2026 — "Sunday Morning".',
    '30/04/2026 — "Mamihlapinatapai" e "It\'s Me".',
    '12/06/2026 — "Iconic by Mistake" com LE SSERAFIM e KATSEYE.',
    '26/07/2026 — "I Got Your Back", single japonês com Jisoo e Momoka (HANA).',
    '26/10/2026 — "Break Even" e "You\'re Under Arrest".',
    '15/11/2026 — Quatro prêmios no MMA 2026.',
    '18/11/2026 — BELIFT reduz a divulgação de "Break Even" por saúde: Yunah, Minju e Wonhee tiveram febre e sintomas gripais; Wonhee e Iroha tratam lesões no tornozelo. A participação no MAMA 2026 seria ajustada conforme a recuperação.',
  ];

  static const links = <IllitFact>[
    IllitFact('Site oficial (BELIFT LAB)', 'https://beliftlab.com/artist/profile/Illit'),
    IllitFact('YouTube oficial', 'https://www.youtube.com/@ILLIT_official'),
    IllitFact('HYBE LABELS (MV e teasers)', 'https://www.youtube.com/@HYBELABELS'),
    IllitFact('Notícias no Google', 'https://news.google.com/search?q=ILLIT%20kpop'),
    IllitFact('Discografia na Wikipedia', 'https://en.wikipedia.org/wiki/Illit_discography'),
  ];

  static const funFacts = <String>[
    'O nome "I\'ll-It" foi revelado no episódio final do "R U Next?" e representa a ideia de escolher um verbo entre "I\'ll" e "it" — as meninas decidem o próprio caminho.',
    'GLLIT vem de "glitter": o fandom é quem brilha aos olhos do ILLIT e faz o grupo brilhar.',
    'Antes da estreia, o ILLIT foi o primeiro artista de K-pop a aparecer no desfile da Acne Studios, em Paris.',
    'Yunah, Minju, Moka, Wonhee e Iroha já assinaram letras de músicas do grupo.',
  ];
}
