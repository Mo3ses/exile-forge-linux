# CLAUDE.md — contexto para Claude Code

## O que é este repositório

Wrapper para rodar o **Exile Forge** (ferramenta de modding de `.ggpk` do Path of Exile 1 & 2) em Linux. Exile Forge é app .NET 10 + WPF Windows-only. Roda via Steam Proton sem patches.

## Status

✅ Testado e funcionando em **CachyOS** (Arch-based) com:
- Steam + Proton Experimental
- POE2 instalado (AppID 2694490) como host do prefixo Wine
- protontricks

## Arquitetura

```
~/exile-forge/
├── install.sh         # instala em qualquer Linux com Steam+POE2+protontricks
├── start.sh           # launcher (chama protontricks-launch --no-runtime --appid 2694490)
├── Exile Forge.exe    # ~250 MB — gitignored, baixado por install.sh
└── README.md          # docs completos
```

**Por que funciona tão bem:**
- Exile Forge é .NET 10 **self-contained** (runtime bundled no exe)
- WPF via Proton + DXVK → D3D9 traduzido pra Vulkan
- Sem memory reading de processo do jogo (não precisa admin/anti-cheat)
- Sem drivers Windows (sem ViGEmBus/HidHide)

## Comandos importantes

| Comando | Pra quê |
|---|---|
| `./install.sh` | Instala do zero (baixa exe, cria launcher+menu) |
| `./install.sh --uninstall` | Remove tudo |
| `~/exile-forge/start.sh` | Roda o Exile Forge |
| `bash -n install.sh && bash -n start.sh` | Sanity check de sintaxe |

## Variáveis importantes no install.sh

```bash
CANDIDATE_HOSTS=( "2694490:Path of Exile 2" "238960:Path of Exile" )
# Auto-detecta qual está instalado na ordem acima — POE2 primeiro, depois POE1.
RELEASE_TAG="V4.4"       # atualizar pra V5.0 quando sair
DOWNLOAD_URL="..."       # URL da release no GitHub (deriva de RELEASE_TAG)
```

## Pra rodar em outra máquina Linux

```bash
# 1. Clone este repo
git clone https://github.com/Mo3ses/exile-forge-linux.git ~/exile-forge
cd ~/exile-forge

# 2. Pré-requisitos (uma vez)
sudo pacman -S steam protontricks     # Arch/CachyOS
# ou: sudo apt install steam && instalar protontricks pelo GitHub

# 3. Instalar POE2 (ou outro jogo Proton) via Steam — pra criar o prefixo

# 4. Rodar
chmod +x install.sh
./install.sh
```

## Quando Claude Code for ajudar neste repo

- Se usuário pedir pra **rodar**: verificar pré-requisitos (Steam, POE2, protontricks), rodar `./install.sh` ou `start.sh`
- Se usuário pedir pra **atualizar**: editar `RELEASE_TAG` no `install.sh`, commitar
- Se usuário pedir pra **portar pra outro jogo Proton**: adicionar nova entrada `appid:NomeDoJogo` no array `CANDIDATE_HOSTS` no `install.sh`
- Se WPF renderizar mal: tentar `DXVK_HUD=1` ou `PROTON_USE_WINED3D=1`
- **Não tentar** substituir DLLs, patchear o exe, ou inventar workarounds — Exile Forge funciona out-of-the-box

## Notas históricas

- Sessão inicial: tentou-se abordagem similar com POE2 Assistant (fracassou por admin check + DLL override complexidade)
- Exile Forge é um caminho MUITO mais simples porque não precisa ler memória do processo do jogo
- Wrapper criado após sucesso confirmado com DXVK ativo + WPF rodando nativamente em janela