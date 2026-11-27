#!/usr/bin/env python3
"""Assina o APK com a chave fixa do projeto.

Sem isso cada build do GitHub Actions sairia com uma chave de debug diferente,
e o Android recusaria instalar a atualização por cima ("app não instalado").
Com a chave commitada em signing/twitter-release.jks o update funciona sempre.
"""
from pathlib import Path
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
APK_DIR = ROOT / "build" / "app" / "outputs" / "flutter-apk"
SRC = APK_DIR / "app-release.apk"
ALIGNED = APK_DIR / "app-release-aligned.apk"
SIGNED = APK_DIR / "app-release-signed.apk"
KEYSTORE = ROOT / "signing" / "twitter-release.jks"

STORE_PASS = "twitter2026"
KEY_PASS = "twitter2026"
ALIAS = "twitter"


def build_tools() -> Path:
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not sdk:
        raise SystemExit("ANDROID_HOME/ANDROID_SDK_ROOT não definido")
    root = Path(sdk) / "build-tools"
    versions = [p for p in root.iterdir() if p.is_dir()]
    if not versions:
        raise SystemExit(f"nenhum build-tools em {root}")

    def version_key(path: Path) -> tuple:
        return tuple(int(n) for n in re.findall(r"\d+", path.name))

    return max(versions, key=version_key)


def run(args: list) -> None:
    print("+", " ".join(str(a) for a in args))
    subprocess.run(args, check=True)


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"APK não encontrado: {SRC}")
    if not KEYSTORE.exists():
        raise SystemExit(f"keystore não encontrado: {KEYSTORE}")

    tools = build_tools()
    zipalign = tools / "zipalign"
    apksigner = tools / "apksigner"
    if not zipalign.exists() or not apksigner.exists():
        raise SystemExit(f"zipalign/apksigner não encontrados em {tools}")

    run([str(zipalign), "-f", "-p", "4", str(SRC), str(ALIGNED)])
    run([
        str(apksigner), "sign",
        "--ks", str(KEYSTORE),
        "--ks-key-alias", ALIAS,
        "--ks-pass", f"pass:{STORE_PASS}",
        "--key-pass", f"pass:{KEY_PASS}",
        "--out", str(SIGNED),
        str(ALIGNED),
    ])
    run([str(apksigner), "verify", "--print-certs", str(SIGNED)])
    print(f"APK assinado: {SIGNED} ({SIGNED.stat().st_size / (1024 * 1024):.1f} MB)")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        print(f"falhou: {error}", file=sys.stderr)
        raise SystemExit(1)
