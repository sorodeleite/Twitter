#!/usr/bin/env python3
"""
✧ AS CARINHAS DO IPHONE, NUM FONTINHO QUE FUNCIONA EM QUALQUER APARELHO ✧
----------------------------------------------------------------------------
O "Apple Color Emoji" só existe nos aparelhos da Apple: no Windows o
navegador cai no Segoe UI Emoji (e no Android, no Noto). Pra pessoa escolher
as carinhas do iPhone também no computador, a gente monta um fontinho de
*bitmaps coloridos* (tabelas CBDT/CBLC) com os desenhos da Apple em 64px —
o mesmo truque do Noto Color Emoji, que roda em todo lugar.

    python scripts/build-emoji-font.py

Ele baixa o pacote `emoji-datasource-apple` (uma vez, fica no .dsh-tmp/),
encolhe cada figurinha pra 128 cores (fica ~4x menor e ninguém nota),
monta o cmap + as ligaduras das bandeirinhas/famílias (GSUB) e salva:

    assets/emoji/apple-emoji.ttf

⚠️ é TTF e não WOFF2 de propósito: o Chrome não abre as tabelas de bitmap
(CBDT) quando elas vêm embrulhadas num woff2 (ele dá erro na fonte e cai
no emoji do sistema). O TTF inteirinho funciona no Chrome/Edge/Android.

⚠️ antes de rodar, instale as ferramentinhas (uma vez só):
    python -m pip install fonttools brotli pillow

⚠️ os DESENHOS são da Apple (© Apple Inc.) — o pacote emoji-datasource é
MIT pros DADOS, mas as imagens são da Apple. É o mesmo caminho que a
maioria dos sites fofos usa; o app só usa isso se a pessoa escolher
"iPhone" nas configurações.
"""
from __future__ import annotations

import io
import json
import os
import struct
import sys
import tarfile
import urllib.request
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
CACHE = RAIZ / ".dsh-tmp" / "emoji-font-cache"
SAIDA = RAIZ / "assets" / "emoji" / "apple-emoji.ttf"
VERSAO_DO_PACOTE = "16.0.0"
URL = f"https://registry.npmjs.org/emoji-datasource-apple/-/emoji-datasource-apple-{VERSAO_DO_PACOTE}.tgz"

# o tamanho da figurinha (o mesmo de todas as figurinhas da Apple no pacote)
PPEM = int(os.environ.get("EMOJI_FONT_PPEM", "64"))
# quantas cores cada figurinha guarda (128 já é lindo e o arquivo fica leve)
CORES = int(os.environ.get("EMOJI_FONT_CORES", "128"))
# a linha de base: os emojis vão de -0.2em a +0.8em (igual às fontes de emoji)
BEARING_Y = 51
# emojis "de verdade" que a gente NÃO quer trocar (viram letrinha/desenho do app)
CATEGORIAS_DE_FORA = {"Component"}

# os pedacinhos que só existem dentro de uma sequência (e não desenham nada)
ZERO_WIDTH = {
    0x200D: "zwj",       # zero width joiner
    0xFE0F: "vs16",      # pede a carinha colorida
    0xFE0E: "vs15",      # pede a letrinha (texto)
    0x20E3: "keycap",    # a caixinha do "1️⃣"
    0x1F3FB: "tom1",
    0x1F3FC: "tom2",
    0x1F3FD: "tom3",
    0x1F3FE: "tom4",
    0x1F3FF: "tom5",
}
# as letrinhas das bandeiras (🇧🇷 = "B" + "R"): elas não existem sozinhas no
# catálogo do pacote, então viram glifos "vazios" só pra ligadura da
# bandeirinha funcionar ✧
for _codigo in range(0x1F1E6, 0x1F200):
    ZERO_WIDTH[_codigo] = f"ri{_codigo:X}"


def baixar_origem() -> Path:
    """Baixa (uma vez) e abre o pacote com as figurinhas da Apple."""
    if CACHE.exists():
        for caminho in CACHE.iterdir():
            if caminho.is_dir() and (caminho / "emoji.json").exists():
                return caminho / "img" / "apple" / "64"
    CACHE.mkdir(parents=True, exist_ok=True)
    print("✧ baixando as figurinhas da Apple (só desta vez)...")
    with urllib.request.urlopen(URL) as resposta:
        dados = resposta.read()
    pacote = tarfile.open(fileobj=io.BytesIO(dados), mode="r:gz")
    try:
        pacote.extractall(CACHE, filter="data")
    except TypeError:  # Python antigo não conhece o `filter`
        pacote.extractall(CACHE)
    return CACHE / "package" / "img" / "apple" / "64"


def nome_do_glifo(codigos) -> str:
    return "u" + "_".join(f"{c:X}" for c in codigos)


def emoji_do_pacote(entrada) -> list[int] | None:
    """Os códigos de uma entrada (a versão "completa", com o FE0F)."""
    cru = entrada.get("unified") or ""
    if not cru:
        return None
    try:
        return [int(parte, 16) for parte in cru.split("-")]
    except ValueError:
        return None


def png_encolhido(caminho: Path) -> bytes:
    """A figurinha em PNG de 128 cores (o mesmo desenho, ~4x menor)."""
    imagem = Image.open(caminho).convert("RGBA")
    pequena = imagem.quantize(colors=CORES, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    memoria = io.BytesIO()
    pequena.save(memoria, "PNG", optimize=True)
    return memoria.getvalue()


def tabela_cbdt(imagens: dict[str, bytes]) -> bytes:
    """A tabela CBDT: cada glifo é um PNG de 64px com as medidas dele."""
    dados = b""
    for png in imagens.values():
        dados += struct.pack(">BBbBB", PPEM, PPEM, 0, BEARING_Y, PPEM)
        dados += struct.pack(">L", len(png)) + png
    return dados


def tabela_cblc(primeiro: int, ultimo: int, imagens: dict[str, bytes]) -> bytes:
    """A tabela CBLC: onde cada imagem começa (um "índice" pro CBDT)."""
    deslocamentos = []
    total = 0
    for png in imagens.values():
        deslocamentos.append(total)
        total += 9 + len(png)  # 5 de medidas + 4 do tamanho + o PNG
    deslocamentos.append(total)

    subtabela = struct.pack(">HHL", 1, 17, 0)
    subtabela += b"".join(struct.pack(">L", valor) for valor in deslocamentos)
    array = struct.pack(">HHL", primeiro, ultimo, 8)
    # sbitLineMetrics (12 bytes cada): ascendente, descendente, largura…
    hori = bytes([80, 20, PPEM, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    vert = bytes([PPEM, PPEM, PPEM, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    tamanho = struct.pack(">LLLL", 56, len(array) + len(subtabela), 1, 0)
    tamanho += hori + vert
    tamanho += struct.pack(">HHBBBb", primeiro, ultimo, PPEM, PPEM, 32, 1)
    return struct.pack(">HHL", 2, 0, 1) + tamanho + array + subtabela


class TabelaCrua:
    """Uma tabela que a gente monta na mão (o fontTools só copia os bytes)."""

    def __init__(self, dados: bytes):
        self.dados = dados

    def compile(self, ttFont) -> bytes:
        return self.dados


def montar(diretorio: Path) -> TTFont:
    with open(CACHE / "package" / "emoji.json", encoding="utf-8") as arquivo:
        catalogo = json.load(arquivo)

    # ✧ as entradas que a gente leva: as "de verdade", sem os tons de pele
    entradas = []
    for entrada in catalogo:
        if not entrada.get("has_img_apple"):
            continue
        if entrada.get("skin_variations"):
            continue
        if entrada.get("category") in CATEGORIAS_DE_FORA:
            continue
        codigos = emoji_do_pacote(entrada)
        if not codigos:
            continue
        # os "1️⃣" precisam de letrinha/número, que este fontinho não tem
        if 0x20E3 in codigos:
            continue
        if not (diretorio / entrada["image"]).exists():
            continue
        entradas.append((codigos, entrada))

    # ✧ cada entrada vira um glifo; os pedacinhos (ZWJ, FE0F…) viram zeros
    glifos: dict[str, dict] = {}       # nome do glifo -> {"png": ...}
    cmap: dict[int, str] = {}
    ligaduras: list[tuple[list[int], str]] = []

    # (só pra testar um pedacinho do fontinho, sem montar os 1.500)
    limite = int(os.environ.get("EMOJI_FONT_LIMITE", "0") or 0)
    if limite > 0:
        entradas = entradas[:limite]

    for codigos, entrada in entradas:
        nome = nome_do_glifo(codigos)
        glifos[nome] = {"png": png_encolhido(diretorio / entrada["image"])}
        if len(codigos) == 1:
            cmap[codigos[0]] = nome
        else:
            # a versão "sem o FE0F" também vale (as vezes o navegador tira ele)
            ligaduras.append((codigos, nome))
            sem_fe0f = [c for c in codigos if c != 0xFE0F]
            if sem_fe0f != codigos:
                ligaduras.append((sem_fe0f, nome))
            # …e a "não qualificada" do catálogo, quando existe
            alternativa = entrada.get("non_qualified") or ""
            if alternativa:
                try:
                    alt = [int(parte, 16) for parte in alternativa.split("-")]
                except ValueError:
                    alt = []
                if alt and alt != codigos and alt != sem_fe0f:
                    ligaduras.append((alt, nome))
            # os pedacinhos aparecem sozinhos no cmap (como glifo zero)
            for codigo in codigos:
                if codigo in ZERO_WIDTH:
                    cmap.setdefault(codigo, ZERO_WIDTH[codigo])

    # ✧ um glifo "vazio" pra cada pedacinho (não desenha e não avança)
    zeros = {nome: 0 for nome in ZERO_WIDTH.values()}
    # ✧ …e os dígitos ficam de fora: "0"…"9" continuam sendo letrinhas do app
    nomes = [".notdef"] + sorted(zeros) + sorted(glifos)
    indice_do_glifo = {nome: i for i, nome in enumerate(nomes)}

    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder(nomes)
    fb.setupCharacterMap(cmap)
    caneta = TTGlyphPen(None)
    vazio = caneta.glyph()
    fb.setupGlyf({nome: vazio for nome in nomes})
    medidas = {}
    for nome in nomes:
        if nome == ".notdef":
            medidas[nome] = (1000, 0)
        elif nome in zeros:
            medidas[nome] = (0, 0)
        else:
            medidas[nome] = (1000, 0)
    fb.setupHorizontalMetrics(medidas)
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({
        "familyName": "Pooftie Apple Emoji",
        "styleName": "Regular",
        "uniqueFontIdentifier": f"PooftieAppleEmoji-{VERSAO_DO_PACOTE}",
        "fullName": "Pooftie Apple Emoji",
        "psName": "PooftieAppleEmoji",
        "version": "Version 1.0",
        "licenseDescription": "Emoji artwork © Apple Inc. (emoji-datasource-apple)",
    })
    fb.setupOS2(
        sTypoAscender=800, sTypoDescender=-200,
        usWinAscent=800, usWinDescent=200,
    )
    fb.setupPost()
    fonte = fb.font

    # ✧ as ligaduras (bandeirinhas, famílias, casais…) entram no "ccmp",
    # que o navegador aplica sempre ✧
    regras = []
    for codigos, nome in ligaduras:
        partes = []
        for codigo in codigos:
            if codigo in cmap:
                partes.append(cmap[codigo])
            elif codigo in ZERO_WIDTH:
                partes.append(ZERO_WIDTH[codigo])
            else:
                partes = []
                break
        if len(partes) > 1:
            regras.append("  sub " + " ".join(partes) + " by " + nome + ";")
    regras = sorted(set(regras))

    fea = ["languagesystem DFLT dflt;", "feature ccmp {"]
    fea += regras
    fea += ["} ccmp;"]
    arquivo_fea = CACHE / "ligaduras.fea"
    arquivo_fea.write_text("\n".join(fea) + "\n", encoding="utf-8")
    from fontTools.feaLib.builder import addOpenTypeFeatures
    addOpenTypeFeatures(fonte, str(arquivo_fea))

    # ✧ as tabelas de bitmap ✧
    primeiro = indice_do_glifo[sorted(glifos)[0]]
    ultimo = indice_do_glifo[sorted(glifos)[-1]]
    imagens_em_ordem = {nome: glifos[nome]["png"] for nome in sorted(glifos)}
    fonte["CBDT"] = TabelaCrua(tabela_cbdt(imagens_em_ordem))
    fonte["CBLC"] = TabelaCrua(tabela_cblc(primeiro, ultimo, imagens_em_ordem))
    return fonte


def main() -> int:
    diretorio = baixar_origem()
    print(f"✧ figurinhas em {diretorio}")
    fonte = montar(diretorio)
    # ⚠️ TTF (e NÃO woff2): o Chrome não abre as tabelas de bitmap (CBDT)
    # quando elas vêm embrulhadas num woff2 — ele dá "font error" e cai no
    # emoji do sistema. O TTF vai inteirinho e funciona em todo lugar. ✧
    fonte.flavor = None
    saida = Path(os.environ.get("EMOJI_FONT_SAIDA") or SAIDA)
    saida.parent.mkdir(parents=True, exist_ok=True)
    fonte.save(str(saida))
    tamanho = saida.stat().st_size / 1048576
    print(f"✧ pronto: {saida} ({tamanho:.2f} MB, {len(fonte.getGlyphOrder())} glifos)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
