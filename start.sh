#!/usr/bin/env bash
# Exile Forge launcher for CachyOS / Steam Proton.
# .NET 10 + WPF funciona no Proton sem patches.
# O exe é self-contained (vem bundled com .NET 10 runtime).

set -uo pipefail

EXILE_DIR="$HOME/exile-forge"
EXE="$EXILE_DIR/Exile Forge.exe"
POE2_APPID="2694490"

if [[ ! -f "$EXE" ]]; then
    echo "ERRO: $EXE não encontrado." >&2
    exit 1
fi

if ! command -v protontricks-launch >/dev/null 2>&1; then
    echo "ERRO: protontricks-launch não está instalado." >&2
    exit 1
fi

# Mata instância anterior
if pgrep -af "Exile Forge.exe" >/dev/null 2>&1; then
    echo "[start.sh] matando instância anterior..."
    PIDS=$(pgrep -f "Exile Forge.exe")
    [[ -n "$PIDS" ]] && kill $PIDS 2>/dev/null || true
    sleep 1
fi

echo "[start.sh] iniciando Exile Forge (mesmo prefix Wine do POE2)..."

exec env WINEDEBUG=-all \
    protontricks-launch --no-runtime --appid "$POE2_APPID" "$EXE" "$@"