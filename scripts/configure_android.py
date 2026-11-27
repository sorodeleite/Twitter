#!/usr/bin/env python3
"""Ajusta o projeto Android gerado pelo `flutter create` no CI.

- libera internet e a instalação de APK (atualização pelo próprio app);
- troca o nome do app para "Twitter";
- gera os ícones do launcher a partir de assets/icon.png.

Roda depois do `flutter create` e antes do build.
"""
from pathlib import Path
import re

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"


def patch_manifest() -> None:
    text = MANIFEST.read_text(encoding="utf-8")

    permissions = [
        'android.permission.INTERNET',
        'android.permission.REQUEST_INSTALL_PACKAGES',
    ]
    missing = [p for p in permissions if p not in text]
    if missing:
        block = "".join(f'    <uses-permission android:name="{p}" />\n' for p in missing)
        text = text.replace("<application", block + "\n    <application", 1)

    text = re.sub(r'android:label="[^"]*"', 'android:label="Twitter"', text)
    MANIFEST.write_text(text, encoding="utf-8")
    print(f"manifest ok: {MANIFEST}")


def build_icons() -> None:
    source = ROOT / "assets" / "icon.png"
    if not source.exists():
        print("assets/icon.png não encontrado, mantendo ícone padrão")
        return
    icon = Image.open(source).convert("RGB")
    sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for density, size in sizes.items():
        target = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        resampling = getattr(Image, "Resampling", Image)
        icon.resize((size, size), resampling.LANCZOS).save(target, format="PNG")
    print("ícones do launcher gerados")


def main() -> None:
    if not MANIFEST.exists():
        raise SystemExit(f"manifest não encontrado: {MANIFEST}")
    patch_manifest()
    build_icons()


if __name__ == "__main__":
    main()
