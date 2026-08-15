#!/usr/bin/env bash
# Atualiza a tradução: busca a versão nova do projeto e reinstala.
#
# Não é preciso clonar de novo — este script atualiza o clone em que ele mesmo está.
# Seus ajustes pessoais em ~/.config/caelestia-ptbr/local.tsv nunca são tocados.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$RAIZ"

verde()   { printf '\033[32m%s\033[0m\n' "$*"; }
amarelo() { printf '\033[33m%s\033[0m\n' "$*"; }
erro()    { printf '\033[31merro: %s\033[0m\n' "$*" >&2; exit 1; }

[ -d .git ] || erro \
    "$RAIZ não é um clone git.
       Se você baixou o projeto como .zip, clone-o para poder atualizar:
         git clone https://github.com/xKIROxKUNx/caelestia-ptbr.git"

command -v git >/dev/null || erro "git não está instalado."

# --- alterações locais -----------------------------------------------------

if ! git diff --quiet || ! git diff --cached --quiet; then
    amarelo "! Você tem alterações locais neste clone:"
    git status --short
    echo
    amarelo "  Para personalizar palavras sem conflitar com atualizações, use o overlay:"
    amarelo "    ~/.config/caelestia-ptbr/local.tsv"
    amarelo "  Ele sobrepõe o mapa base e nunca é sobrescrito."
    echo
    read -r -p "Descartar as alterações locais e atualizar? [s/N] " resposta
    case "$resposta" in
        [sSyY]) git checkout -- . ;;
        *) erro "atualização cancelada." ;;
    esac
fi

# --- buscar ----------------------------------------------------------------

ANTES="$(git rev-parse HEAD)"
VERSAO_ANTES="$(git describe --tags --always 2>/dev/null || echo '?')"

verde "Buscando atualizações..."
git fetch --tags --quiet origin

DEPOIS="$(git rev-parse '@{u}' 2>/dev/null || echo "$ANTES")"

if [ "$ANTES" = "$DEPOIS" ]; then
    verde "✓ Já está na versão mais recente ($VERSAO_ANTES). Nada a fazer."
    exit 0
fi

echo
verde "Novidades:"
git log --no-merges --pretty='  • %s' "$ANTES..$DEPOIS"
echo

git merge --ff-only --quiet "$DEPOIS" || erro \
    "não foi possível avançar automaticamente. Resolva com 'git pull' e rode de novo."

VERSAO_DEPOIS="$(git describe --tags --always 2>/dev/null || echo '?')"
verde "✓ Atualizado: $VERSAO_ANTES → $VERSAO_DEPOIS"

# --- reinstalar ------------------------------------------------------------

echo
exec ./instalar.sh
