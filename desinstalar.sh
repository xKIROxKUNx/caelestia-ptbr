#!/usr/bin/env bash
# Remove a tradução pt-BR e devolve o Caelestia shell ao original em /etc/xdg.
#
# Nada do pacote caelestia-shell é tocado em momento algum, então isto apenas
# apaga a cópia traduzida e os arquivos que o instalador criou.

set -euo pipefail

BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
DADOS="${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-ptbr"
UNIDADES="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
COPIA="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"

verde()   { printf '\033[32m%s\033[0m\n' "$*"; }
amarelo() { printf '\033[33m%s\033[0m\n' "$*"; }

# Precisa parar o shell ANTES de apagar a cópia: 'caelestia shell -k' resolve o caminho
# da config no momento em que roda, e sem a cópia ele deixa de alcançar a instância viva.
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

parar_shell

if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now caelestia-ptbr.path >/dev/null 2>&1 || true
    rm -f "$UNIDADES/caelestia-ptbr.path" "$UNIDADES/caelestia-ptbr.service"
    systemctl --user daemon-reload
    verde "✓ unidades systemd removidas"
fi

rm -f  "$BIN/caelestia-ptbr"
rm -rf "$DADOS"
verde "✓ tradutor e mapa removidos"

# Restos de uma execução interrompida, se houver.
rm -rf "$COPIA.new" "$COPIA.old"
rm -rf "$COPIA"
verde "✓ cópia traduzida removida — o shell volta a carregar /etc/xdg/quickshell/caelestia"

setsid -f qs -c caelestia -n -d >/dev/null 2>&1 </dev/null
sleep 5

if qs list --all 2>/dev/null | grep -q '/etc/xdg/quickshell/caelestia'; then
    verde "✓ shell reiniciado em inglês, a partir de /etc/xdg"
else
    amarelo "! o shell não subiu sozinho. Inicie com: caelestia shell -d"
fi

OVERLAY="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-ptbr/local.tsv"
if [ -f "$OVERLAY" ]; then
    echo
    amarelo "Seus ajustes pessoais foram mantidos em $OVERLAY"
    amarelo "(apague na mão se não for reinstalar)"
fi
