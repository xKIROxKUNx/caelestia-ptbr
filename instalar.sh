#!/usr/bin/env bash
# Instala a tradução pt-BR do Caelestia shell.
#
# Copia o tradutor, o mapa de strings e as unidades systemd para os lugares padrão,
# aplica a tradução e reinicia o shell. Pode ser rodado de novo a qualquer momento.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
DADOS="${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-ptbr"
UNIDADES="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
ORIGEM_SHELL="/etc/xdg/quickshell/caelestia"

verde()    { printf '\033[32m%s\033[0m\n' "$*"; }
amarelo()  { printf '\033[33m%s\033[0m\n' "$*"; }
erro()     { printf '\033[31merro: %s\033[0m\n' "$*" >&2; exit 1; }

# 'caelestia shell -k' só alcança instâncias cujo caminho de config bate com o que o
# quickshell resolve agora — e esse caminho muda no meio da instalação, quando a cópia
# em ~/.config passa a existir. Matar por PID é o único jeito confiável.
parar_shell() {
    local pids
    pids=$(qs list --all 2>/dev/null \
        | awk '/Process ID:/{pid=$3} /Config path:.*caelestia/{if(pid){print pid; pid=""}}')
    if [ -n "$pids" ]; then
        # shellcheck disable=SC2086
        kill $pids 2>/dev/null || true
        sleep 2
    fi
}

iniciar_shell() {
    # setsid é necessário: iniciado direto daqui, o processo morre junto com o script.
    setsid -f qs -c caelestia -n -d >/dev/null 2>&1 </dev/null
    sleep 5
}

# --- 1. dependências -------------------------------------------------------

[ -f "$ORIGEM_SHELL/shell.qml" ] || erro \
    "não encontrei $ORIGEM_SHELL/shell.qml.
       Instale o caelestia-shell antes: https://github.com/caelestia-dots/shell"

command -v qs      >/dev/null || erro "quickshell (qs) não está no PATH."
command -v python3 >/dev/null || erro "python3 não está no PATH."

verde "✓ caelestia-shell, quickshell e python3 encontrados"

# --- 2. arquivos -----------------------------------------------------------

install -Dm755 "$RAIZ/caelestia-ptbr" "$BIN/caelestia-ptbr"
install -Dm644 "$RAIZ/pt_BR.tsv"      "$DADOS/pt_BR.tsv"
verde "✓ tradutor em $BIN/caelestia-ptbr"
verde "✓ mapa em $DADOS/pt_BR.tsv"

# --- 3. reaplicação automática após atualizações do pacote -----------------

install -Dm644 "$RAIZ/systemd/caelestia-ptbr.service" "$UNIDADES/caelestia-ptbr.service"
install -Dm644 "$RAIZ/systemd/caelestia-ptbr.path"    "$UNIDADES/caelestia-ptbr.path"

if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now caelestia-ptbr.path
    verde "✓ caelestia-ptbr.path ativa — retraduz sozinho após atualizar o caelestia-shell"
else
    amarelo "! systemd de usuário indisponível; unidades copiadas mas não ativadas."
    amarelo "  Rode 'caelestia-ptbr' na mão depois de cada atualização do pacote."
fi

# --- 4. traduzir -----------------------------------------------------------

echo
parar_shell
"$BIN/caelestia-ptbr"

# --- 5. reiniciar o shell --------------------------------------------------

echo
iniciar_shell

if qs list --all 2>/dev/null | grep -q "$HOME/.config/quickshell/caelestia"; then
    verde "✓ shell reiniciado a partir de ~/.config/quickshell/caelestia"
else
    amarelo "! o shell não subiu sozinho. Inicie com: caelestia shell -d"
fi

# --- 6. avisos -------------------------------------------------------------

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo
       amarelo "! $BIN não está no seu PATH."
       amarelo "  Adicione ao seu shell rc para chamar 'caelestia-ptbr' de qualquer lugar:"
       amarelo "    export PATH=\"\$PATH:$BIN\"" ;;
esac

OVERLAY="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-ptbr/local.tsv"

echo
verde "Tradução instalada."
echo
verde "  Ajustar uma palavra   crie $OVERLAY"
verde "                        com 'inglês<TAB>português' e rode: caelestia-ptbr"
verde "                        (esse arquivo sobrevive às atualizações)"
verde "  Atualizar             ./atualizar.sh"
