# Exile Forge for Linux

Wrapper para rodar o [Exile Forge](https://github.com/talagio90/GGPK-Modding-Tool) (ferramenta de modding dos arquivos `.ggpk` do Path of Exile 1 & 2) em Linux via Steam Proton.

Exile Forge é um app .NET 10 + WPF Windows-only. Funciona **out-of-the-box** no Proton moderno sem patches.

## Pré-requisitos

| Dependência | Instalação |
|---|---|
| **Steam** | `sudo pacman -S steam` (Arch/CachyOS) / `sudo apt install steam` (Ubuntu) |
| **Path of Exile 1 ou 2** | Instalar pela Steam — serve apenas para prover um prefixo Wine Proton funcional (qualquer um dos dois serve; o instalador auto-detecta) |
| **protontricks** | `sudo pacman -S protontricks` (Arch/CachyOS) ou [instalação manual](https://github.com/Matoking/protontricks) |
| **Proton** (>= 8.0) | Já vem com Steam (Proton Experimental ou Proton 9.x) |
| `unzip`, `curl` | Já presentes na maioria das distros |

### Verificar pré-requisitos

```bash
command -v steam protontricks-launch unzip curl
ls ~/.steam/steam/steamapps/appmanifest_2694490.acf   # POE2 (ou appmanifest_238960.acf pra POE1)
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
- Verifica pré-requisitos (auto-detecta POE2 ou POE1 instalado)
- **Auto-detecta a última release** do GitHub via redirect `/releases/latest` → tag (ex: V4.4) — sem precisar editar o script pra atualizar
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
| Diretamente | `protontricks-launch --no-runtime --appid <POE_APPID> "$HOME/exile-forge/Exile Forge.exe"` onde `<POE_APPID>` é `2694490` (POE2) ou `238960` (POE1) |

## Apontar pro Path of Exile

Ao abrir o Exile Forge pela primeira vez, ele pede o path do jogo. Use:

```
/home/<seu-user>/.steam/steam/steamapps/common/Path of Exile 2
```

ou, se você usa POE1:

```
/home/<seu-user>/.steam/steam/steamapps/common/Path of Exile
```

## Customização

### Mudar ícone

```bash
# Baixe um PNG 256x256 do logo do Exile Forge
cp ~/Downloads/exile-forge-logo.png ~/.local/share/icons/hicolor/256x256/apps/exile-forge.png
```

### Usar outro jogo Proton como host do prefixo

O instalador já auto-detecta **Path of Exile 2** (appid 2694490) ou **Path of Exile 1** (appid 238960) — primeiro instalado vence. Pra usar um terceiro jogo Proton, edite o array `CANDIDATE_HOSTS` no topo do `install.sh`:

```bash
CANDIDATE_HOSTS=(
    "2694490:Path of Exile 2"
    "238960:Path of Exile"
    "123456:Outro Jogo"   # adicione outro appid aqui
)
```

Depois rode `./install.sh --uninstall` e reinstale.

### Atualizar pra nova versão

O instalador baixa a **última release** automaticamente — basta remover o exe antigo e reinstalar:

```bash
rm ~/exile-forge/Exile\ Forge.exe
./install.sh
```

Pro fixar numa versão específica (ex: testar beta, ou baixar versão antiga), use a env var:

```bash
RELEASE_TAG=V4.3 ./install.sh
```

(Para o app Exile Forge em si, **não há auto-update interno** — você precisa baixar manualmente. Use este wrapper pra ficar sempre na última.)

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

`start.sh` chama `protontricks-launch --no-runtime --appid <POE_APPID>` (detectado em runtime — POE2 ou POE1), que:
1. Usa o Wine do Proton Experimental
2. Roda dentro do prefixo Proton do jogo detectado (sem interferir)
3. Carrega nosso `Exile Forge.exe` (que tem .NET 10 bundled)

DXVK traduz D3D9 do WPF para Vulkan automaticamente. Resultado: app nativo em janela, sem terminal.

## Troubleshooting

### App não abre / fecha imediatamente

```bash
# Roda com debug pra ver o erro
WINEDEBUG=+module,+seh protontricks-launch --no-runtime --appid <POE_APPID> \
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