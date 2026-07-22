#!/usr/bin/env bash
# Exile Forge installer for Linux (CachyOS, Arch, Ubuntu, etc.)
# Requisitos: Steam com POE2 instalado, protontricks
# Uso: ./install.sh [--uninstall]

set -euo pipefail

# ---------- Configuração ----------
APP_NAME="Exile Forge"
APP_DIR="$HOME/exile-forge"
EXE_NAME="Exile Forge.exe"
EXE_PATH="$APP_DIR/$EXE_NAME"
LAUNCHER="$APP_DIR/start.sh"
DESKTOP="$HOME/.local/share/applications/exile-forge.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
ICON_PATH="$ICON_DIR/exile-forge.png"
ZIP_PATH="$APP_DIR/Exile.Forge.zip"

# Candidatos a host Proton (Exile Forge funciona pros dois).
# Auto-detecção na ordem abaixo — primeiro instalado vence.
CANDIDATE_HOSTS=(
    "2694490:Path of Exile 2"
    "238960:Path of Exile"
)

# Mantidos pra retro-compat — preenchidos por check_prereqs().
PROTON_APPID=""
GAME_NAME=""

# URL da release (verifique em github.com/talagio90/GGPK-Modding-Tool/releases).
# "latest" → resolve dinamicamente via redirect /releases/latest.
# Pra fixar versão específica, coloque a tag (ex: "V4.4") antes de rodar.
RELEASE_TAG="${RELEASE_TAG:-latest}"
RESOLVED_TAG=""
DOWNLOAD_URL="https://github.com/talagio90/GGPK-Modding-Tool/releases/latest"

# ---------- Cores ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()  { printf "${GREEN}[+]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err()   { printf "${RED}[-]${NC} %s\n" "$*" >&2; }

# ---------- Verificações de pré-requisitos ----------
check_prereqs() {
    info "Verificando pré-requisitos..."

    if ! command -v steam >/dev/null 2>&1; then
        err "Steam não encontrado."
        err "  Arch/CachyOS: sudo pacman -S steam"
        err "  Ubuntu:        sudo apt install steam"
        exit 1
    fi
    info "Steam: ok"

    local manifest=""
    for entry in "${CANDIDATE_HOSTS[@]}"; do
        local candidate_appid="${entry%%:*}"
        local candidate_name="${entry#*:}"
        if [[ -f "$HOME/.steam/steam/steamapps/appmanifest_${candidate_appid}.acf" ]]; then
            PROTON_APPID="$candidate_appid"
            GAME_NAME="$candidate_name"
            break
        fi
    done

    if [[ -z "$PROTON_APPID" ]]; then
        err "Nenhum jogo Proton compatível está instalado."
        err "  Instale um destes pela Steam (qualquer um serve como host do prefixo):"
        for entry in "${CANDIDATE_HOSTS[@]}"; do
            err "    - ${entry#*:} (appid ${entry%%:*})"
        done
        exit 1
    fi
    info "${GAME_NAME} (appid ${PROTON_APPID}) será usado como host do prefixo Proton"
    info "Versão alvo: ${RELEASE_TAG} (será resolvida automaticamente antes do download)"

    if ! command -v protontricks-launch >/dev/null 2>&1; then
        err "protontricks não encontrado."
        err "  Arch/CachyOS: sudo pacman -S protontricks"
        err "  Ubuntu:        https://github.com/Matoking/protontricks"
        exit 1
    fi
    info "protontricks: ok"

    for cmd in unzip curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            err "$cmd não encontrado."
            exit 1
        fi
    done

    if pgrep -af "PathOfExile" >/dev/null 2>&1; then
        warn "POE2 está rodando. Pode haver locks em arquivos .ggpk."
    fi
}

# ---------- Resolução de versão ----------
# Se RELEASE_TAG=="latest", segue o redirect /releases/latest do GitHub e
# extrai a tag real. Sem dependência extra — só curl + grep + sed.
resolve_release_tag() {
    if [[ "$RELEASE_TAG" != "latest" ]]; then
        RESOLVED_TAG="$RELEASE_TAG"
        return 0
    fi

    local effective_url
    effective_url=$(curl -fsSL -o /dev/null -w '%{url_effective}' \
        "https://github.com/talagio90/GGPK-Modding-Tool/releases/latest" 2>/dev/null) \
        || { err "Falha ao resolver última release do GitHub."; return 1; }

    RESOLVED_TAG=$(printf '%s' "$effective_url" | grep -oE 'tag/V[^/]+' | head -1 | sed 's|tag/||')
    [[ -n "$RESOLVED_TAG" ]] || { err "Não extraiu tag de: $effective_url"; return 1; }
    return 0
}

# ---------- Download ----------
download_exile_forge() {
    mkdir -p "$APP_DIR"

    if [[ -f "$EXE_PATH" ]]; then
        info "$EXE_NAME já existe em $APP_DIR, pulando download."
        return 0
    fi

    if ! resolve_release_tag; then
        err "Defina RELEASE_TAG manualmente (ex: RELEASE_TAG=V4.4 ./install.sh)."
        exit 1
    fi
    DOWNLOAD_URL="https://github.com/talagio90/GGPK-Modding-Tool/releases/download/${RESOLVED_TAG}/Exile.Forge.zip"
    info "Baixando Exile Forge ${RESOLVED_TAG}..."
    if ! curl -fsSL -o "$ZIP_PATH" "$DOWNLOAD_URL"; then
        err "Falha no download. Verifique:"
        err "  $DOWNLOAD_URL"
        exit 1
    fi

    info "Extraindo..."
    (cd "$APP_DIR" && unzip -q -o "$ZIP_PATH" "$EXE_NAME")
    [[ -f "$EXE_PATH" ]] || { err "Extração falhou."; exit 1; }
    rm "$ZIP_PATH"
    info "Download e extração concluídos."
}

# ---------- Launcher ----------
write_launcher() {
    cat > "$LAUNCHER" << EOF
#!/usr/bin/env bash
# Exile Forge launcher — gerado por install.sh
# .NET 10 + WPF funciona out-of-the-box no Proton moderno.

set -uo pipefail

EXILE_DIR="$APP_DIR"
EXE="\$EXILE_DIR/$EXE_NAME"
POE2_APPID="$PROTON_APPID"

if [[ ! -f "\$EXE" ]]; then
    echo "ERRO: \$EXE não encontrado." >&2
    echo "Rode install.sh novamente." >&2
    exit 1
fi

if ! command -v protontricks-launch >/dev/null 2>&1; then
    echo "ERRO: protontricks-launch não instalado." >&2
    exit 1
fi

if pgrep -af "$EXE_NAME" >/dev/null 2>&1; then
    echo "[start.sh] matando instância anterior..."
    PIDS=\$(pgrep -f "$EXE_NAME")
    [[ -n "\$PIDS" ]] && kill \$PIDS 2>/dev/null || true
    sleep 1
fi

echo "[start.sh] iniciando Exile Forge..."
exec env WINEDEBUG=-all \\
    protontricks-launch --no-runtime --appid "\$POE2_APPID" "\$EXE" "\$@"
EOF
    chmod +x "$LAUNCHER"
    info "Launcher criado: $LAUNCHER"
}

# ---------- Ícone ----------
install_icon() {
    mkdir -p "$ICON_DIR"
    if [[ ! -f "$ICON_PATH" ]]; then
        info "Baixando ícone placeholder..."
        curl -fsSL -o "$ICON_PATH" \
            "https://web.poecdn.com/image/Art/2DItems/Weapons/OneHandWeapons/Daggers/Dagger2.png?w=1&h=1&scale=1" \
            2>/dev/null || warn "Falha no ícone (não crítico)"
    fi
}

# ---------- Entrada .desktop ----------
write_desktop_entry() {
    mkdir -p "$(dirname "$DESKTOP")"
    cat > "$DESKTOP" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
GenericName=GGPK Modding Tool
Comment=Path of Exile GGPK modding toolkit (${RESOLVED_TAG:-$RELEASE_TAG})
Exec=$LAUNCHER %u
Icon=exile-forge
Terminal=false
StartupNotify=true
StartupWMClass=$EXE_NAME
Categories=Game;
Keywords=poe;path of exile;ggpk;modding;
MimeType=application/x-msdownload;
EOF
    chmod 644 "$DESKTOP"
    info "Entrada de menu criada: $DESKTOP"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    fi
}

# ---------- Uninstall ----------
uninstall() {
    warn "Removendo instalação..."
    rm -f "$LAUNCHER" "$DESKTOP" "$ICON_PATH" "$ZIP_PATH"
    if [[ -d "$APP_DIR" ]]; then
        read -p "Remover também $APP_DIR inteiro (inclui exe de ~250MB)? [y/N] " ans
        if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
            rm -rf "$APP_DIR"
            info "$APP_DIR removido."
        fi
    fi
    info "Desinstalação concluída."
}

# ---------- Main ----------
if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall
    exit 0
fi

info "=== Instalador Exile Forge ==="
check_prereqs
download_exile_forge
write_launcher
install_icon
write_desktop_entry

echo ""
info "Instalação completa!"
echo "  - Launcher: $LAUNCHER"
echo "  - Menu:     procure por '$APP_NAME'"
echo ""
echo "Para desinstalar: $0 --uninstall"