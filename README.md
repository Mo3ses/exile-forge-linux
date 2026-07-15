# Exile Forge for Linux

Wrapper para rodar o [Exile Forge](https://github.com/talagio90/GGPK-Modding-Tool) (ferramenta de modding dos arquivos `.ggpk` do Path of Exile 1 & 2) em Linux via Steam Proton.

Exile Forge é um app .NET 10 + WPF Windows-only. Funciona **out-of-the-box** no Proton moderno sem patches.

## Pré-requisitos

| Dependência | Instalação |
|---|---|
| **Steam** | `sudo pacman -S steam` (Arch/CachyOS) / `sudo apt install steam` (Ubuntu) |
| **Path of Exile 2** (ou outro jogo Proton) | Instalar pela Steam — serve apenas para prover um prefixo Wine Proton funcional |
| **protontricks** | `sudo pacman -S protontricks` (Arch/CachyOS) ou [instalação manual](https://github.com/Matoking/protontricks) |
| **Proton** (>= 8.0) | Já vem com Steam (Proton Experimental ou Proton 9.x) |
| `unzip`, `curl` | Já presentes na maioria das distros |

### Verificar pré-requisitos

```bash
command -v steam protontricks-launch unzip curl
ls ~/.steam/steam/steamapps/appmanifest_2694490.acf   # appid do POE2
```

## Instalação

### Opção A — usar `install.sh` (recomendado)

```bash
git clone <url-do-repo> ~/exile-forge    # ou copie os arquivos manualmente
cd ~/exile-forge
chmod +x install.sh
./install.sh
```

O `install.sh`:
- Verifica pré-requisitos
- Baixa o Exile Forge V4.3 do GitHub
- Cria `start.sh` (launcher)
- Baixa ícone placeholder
- Cria entrada `.desktop` no menu do sistema

### Opção B — manual

```bash
# Coloque o Exile Forge.exe em algum lugar (ex: ~/exile-forge/)
# Crie o launcher (veja start.sh)
# Crie a entrada .desktop em ~/.local/share/applications/
```

## Uso

| Método | Comando |
|---|---|
| Pelo menu de apps | Procure "Exile Forge" no menu do seu DE |
| Pelo terminal | `~/exile-forge/start.sh` |
| Pelo GTK | `gtk-launch exile-forge` |
| Diretamente | `protontricks-launch --no-runtime --appid 2694490 "$HOME/exile-forge/Exile Forge.exe"` |

## Apontar pro POE2

Ao abrir o Exile Forge pela primeira vez, ele pede o path do jogo. Use:

```
/home/<seu-user>/.steam/steam/steamapps/common/Path of Exile 2
```

(ou `Path of Exile` para POE1)

## Customização

### Mudar ícone

```bash
# Baixe um PNG 256x256 do logo do Exile Forge
cp ~/Downloads/exile-forge-logo.png ~/.local/share/icons/hicolor/256x256/apps/exile-forge.png
```

### Usar outro jogo Proton como host do prefixo

Edite o topo do `install.sh`:

```bash
PROTON_APPID="123456"  # appid de outro jogo Proton
GAME_NAME="Outro Jogo"
```

Depois rode `./install.sh --uninstall` e reinstale.

### Atualizar pra nova versão

Edite `RELEASE_TAG` no topo do `install.sh` (ex: `"V4.4"`). O instalador só baixa se `Exile Forge.exe` não existir — então:

```bash
rm ~/exile-forge/Exile\ Forge.exe
./install.sh
```

## Desinstalação

```bash
./install.sh --uninstall
```

Remove launcher, ícone e entrada de menu. Opcionalmente remove o executável.

## Estrutura

```
~/exile-forge/
├── Exile Forge.exe    # ~250 MB — app principal (bundled .NET 10)
├── start.sh           # launcher via protontricks-launch
├── install.sh         # instalador/desinstalador
└── README.md          # este arquivo

~/.local/share/applications/exile-forge.desktop   # entrada do menu
~/.local/share/icons/.../exile-forge.png          # ícone
```

## Como funciona

`start.sh` chama `protontricks-launch --no-runtime --appid 2694490`, que:
1. Usa o Wine do Proton Experimental
2. Roda dentro do prefixo Proton do POE2 (sem interferir)
3. Carrega nosso `Exile Forge.exe` (que tem .NET 10 bundled)

DXVK traduz D3D9 do WPF para Vulkan automaticamente. Resultado: app nativo em janela, sem terminal.

## Troubleshooting

### App não abre / fecha imediatamente

```bash
# Roda com debug pra ver o erro
WINEDEBUG=+module,+seh protontricks-launch --no-runtime --appid 2694490 \
    "$HOME/exile-forge/Exile Forge.exe"
```

### WPF renderiza mal

```bash
# Forçar DXVK HUD pra debug
DXVK_HUD=1 ~/exile-forge/start.sh
```

### Quer desabilitar DXVK e usar OpenGL/WineD3D

```bash
PROTON_USE_WINED3D=1 ~/exile-forge/start.sh
```

### Path do POE2 não é detectado

Verifique:
```bash
ls ~/.steam/steam/steamapps/common/Path\ of\ Exile\ 2/
```

Se diferente (biblioteca Steam em outro disco), use o caminho real.

## Licença

Exile Forge é software proprietário do autor talagio90. Este wrapper é apenas um instalador — não redistribui nem modifica o app original. Verifique a licença do Exile Forge no GitHub antes de redistribuir.

## Créditos

- **Exile Forge** por [@talagio90](https://github.com/talagio90)
- **protontricks** por [@Matoking](https://github.com/Matoking)
- **Wine/Proton** por WineHQ e Valve