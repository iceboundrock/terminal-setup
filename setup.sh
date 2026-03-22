#!/bin/bash
#
# terminal-setup — One-script Mac terminal environment setup
#
# Stack: Ghostty + (Fish or Zsh) + Starship + Nerd Font (MesloLGS)
# Tools: bat, eza, fd, ripgrep, btop, zoxide, jq, tldr, delta, lazygit, fzf
# Node:  fnm (Fast Node Manager) — works with both Fish and Zsh
# Theme: Catppuccin Mocha (Starship)
#
# Usage:
#   ./setup.sh              # interactive shell choice
#   ./setup.sh --fish       # use Fish
#   ./setup.sh --zsh        # use Zsh (with fish-like plugins)
#

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ─── Shell Choice ────────────────────────────────────────────────────
SHELL_CHOICE=""
for arg in "$@"; do
    case "$arg" in
        --fish) SHELL_CHOICE="fish" ;;
        --zsh)  SHELL_CHOICE="zsh" ;;
    esac
done

if [[ -z "$SHELL_CHOICE" ]]; then
    echo ""
    echo -e "${BOLD}Which shell do you want to use?${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} ${BOLD}Fish${NC}  — Modern shell, amazing defaults, not POSIX"
    echo -e "  ${GREEN}2)${NC} ${BOLD}Zsh${NC}   — POSIX-compatible, fish-like with plugins"
    echo ""
    while true; do
        read -rp "Choose [1/2]: " choice
        case "$choice" in
            1|fish) SHELL_CHOICE="fish"; break ;;
            2|zsh)  SHELL_CHOICE="zsh"; break ;;
            *) echo "Please enter 1 or 2." ;;
        esac
    done
fi

echo ""
info "Setting up with ${BOLD}${SHELL_CHOICE}${NC}"

# ─── Pre-flight ──────────────────────────────────────────────────────
[[ "$(uname)" != "Darwin" ]] && error "This script is for macOS only."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

# If running via curl pipe (no local configs dir), clone the repo first
if [[ ! -d "$CONFIGS_DIR" ]]; then
    info "Config files not found locally, cloning repo..."
    TMPDIR_CLONE="$(mktemp -d)"
    git clone --depth 1 https://github.com/lewislulu/terminal-setup.git "$TMPDIR_CLONE/terminal-setup"
    SCRIPT_DIR="$TMPDIR_CLONE/terminal-setup"
    CONFIGS_DIR="$SCRIPT_DIR/configs"
fi

# ─── Step 1: Homebrew ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🍺 Step 1/8: Homebrew${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# ─── Step 2: Ghostty ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  👻 Step 2/8: Ghostty Terminal${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if [[ ! -d "/Applications/Ghostty.app" ]]; then
    info "Installing Ghostty..."
    brew install --cask ghostty
    success "Ghostty installed"
else
    success "Ghostty already installed"
fi

# ─── Step 3: Nerd Font (MesloLGS NF) ────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🔤 Step 3/8: Nerd Font (MesloLGS NF)${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

FONT_DIR="$HOME/Library/Fonts"
MESLO_BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
MESLO_FONTS=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
)

FONT_INSTALLED=true
for font in "${MESLO_FONTS[@]}"; do
    [[ ! -f "$FONT_DIR/$font" ]] && FONT_INSTALLED=false && break
done

if $FONT_INSTALLED; then
    success "MesloLGS NF fonts already installed"
else
    info "Downloading MesloLGS NF fonts..."
    mkdir -p "$FONT_DIR"
    for font in "${MESLO_FONTS[@]}"; do
        encoded=$(echo "$font" | sed 's/ /%20/g')
        curl -fsSL "$MESLO_BASE_URL/$encoded" -o "$FONT_DIR/$font"
    done
    success "MesloLGS NF fonts installed"
fi

# ─── Step 4: Shell ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
if [[ "$SHELL_CHOICE" == "fish" ]]; then
    echo -e "${BOLD}  🐟 Step 4/8: Fish Shell${NC}"
else
    echo -e "${BOLD}  🐚 Step 4/8: Zsh + Fish-like Plugins${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if [[ "$SHELL_CHOICE" == "fish" ]]; then
    if ! command -v fish &>/dev/null; then
        info "Installing Fish..."
        brew install fish
        success "Fish installed"
    else
        success "Fish already installed"
    fi

    FISH_PATH="$(which fish)"
    if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
        info "Adding Fish to /etc/shells (may need sudo)..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    if [[ "$SHELL" != "$FISH_PATH" ]]; then
        info "Setting Fish as default shell..."
        chsh -s "$FISH_PATH"
        success "Default shell changed to Fish"
    else
        success "Fish is already the default shell"
    fi
else
    # Zsh is pre-installed on macOS, just install the plugins
    ZSH_PLUGINS=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
    for plugin in "${ZSH_PLUGINS[@]}"; do
        if brew list "$plugin" &>/dev/null; then
            success "$plugin already installed"
        else
            info "Installing $plugin..."
            brew install "$plugin"
            success "$plugin installed"
        fi
    done

    ZSH_PATH="$(which zsh)"
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        info "Setting Zsh as default shell..."
        chsh -s "$ZSH_PATH"
        success "Default shell changed to Zsh"
    else
        success "Zsh is already the default shell"
    fi
fi

# ─── Step 5: CLI Tools ──────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🛠  Step 5/8: CLI Tools${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

TOOLS=(bat eza fd ripgrep btop zoxide jq tldr git-delta lazygit fzf)

for tool in "${TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        success "$tool already installed"
    else
        info "Installing $tool..."
        brew install "$tool"
        success "$tool installed"
    fi
done

# ─── Step 6: Starship Prompt ────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🚀 Step 6/8: Starship Prompt${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    brew install starship
    success "Starship installed"
else
    success "Starship already installed"
fi

# ─── Step 7: fnm + Node.js ──────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  🟢 Step 7/8: fnm + Node.js${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

if ! command -v fnm &>/dev/null; then
    info "Installing fnm (Fast Node Manager)..."
    brew install fnm
    success "fnm installed"
else
    success "fnm already installed"
fi

# Load fnm in current shell so we can install Node
eval "$(fnm env --use-on-cd --shell bash)"

info "Installing Node LTS..."
fnm install --lts
fnm default lts-latest
fnm use lts-latest
success "Node LTS installed and set as default"

# ─── Step 8: Config Files ───────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  📦 Step 8/8: Deploying Configs${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"

# --- Ghostty config ---
GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_CONFIG_DIR"
if [[ -f "$GHOSTTY_CONFIG_DIR/config.ghostty" ]]; then
    cp "$GHOSTTY_CONFIG_DIR/config.ghostty" "$GHOSTTY_CONFIG_DIR/config.ghostty.bak.$(date +%s)"
    warn "Backed up existing Ghostty config"
fi
cp "$CONFIGS_DIR/ghostty.config" "$GHOSTTY_CONFIG_DIR/config.ghostty"
success "Ghostty config deployed"

# --- Starship config ---
mkdir -p "$HOME/.config"
if [[ -f "$HOME/.config/starship.toml" ]]; then
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
    warn "Backed up existing starship.toml"
fi
cp "$CONFIGS_DIR/starship.toml" "$HOME/.config/starship.toml"
success "Starship config deployed"

# --- Shell-specific config ---
if [[ "$SHELL_CHOICE" == "fish" ]]; then
    # Fish config
    FISH_CONFIG_DIR="$HOME/.config/fish"
    mkdir -p "$FISH_CONFIG_DIR"

    if [[ -f "$FISH_CONFIG_DIR/config.fish" ]]; then
        cp "$FISH_CONFIG_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish.bak.$(date +%s)"
        warn "Backed up existing config.fish"
    fi
    cp "$CONFIGS_DIR/config.fish" "$FISH_CONFIG_DIR/config.fish"
    success "Fish config deployed"

    # Fish abbreviations
    info "Setting up Fish abbreviations..."
    fish -c '
        abbr -a --global ls "eza --icons --group-directories-first"
        abbr -a --global ll "eza -la --icons --group-directories-first"
        abbr -a --global lt "eza --tree --icons --level=2"
        abbr -a --global cat "bat"
        abbr -a --global find "fd"
        abbr -a --global grep "rg"
        abbr -a --global top "btop"
        abbr -a --global lg "lazygit"
        abbr -a --global cd "z"
    '
    success "Fish abbreviations set"

    # Zoxide + fzf init for fish
    if ! grep -qF "zoxide" "$FISH_CONFIG_DIR/config.fish" 2>/dev/null; then
        info "Adding zoxide + fzf init to fish config..."
        cat >> "$FISH_CONFIG_DIR/config.fish" << 'FISHEOF'

# zoxide
zoxide init fish | source

# fzf
fzf --fish | source
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
if command -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
end
FISHEOF
        success "Zoxide + fzf init added"
    else
        success "Zoxide init already present"
    fi
else
    # Zsh config
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
        warn "Backed up existing .zshrc"
    fi
    cp "$CONFIGS_DIR/.zshrc" "$HOME/.zshrc"
    success "Zsh config deployed"
fi

# ─── Git config for delta ────────────────────────────────────────────
info "Configuring git-delta as git pager..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.dark true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
success "git-delta configured"

# ─── Done! ───────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✅ All done!${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Your terminal stack:${NC}"
echo -e "    👻 Ghostty              — terminal emulator"
if [[ "$SHELL_CHOICE" == "fish" ]]; then
    echo -e "    🐟 Fish                 — shell"
else
    echo -e "    🐚 Zsh                  — shell (POSIX-compatible)"
    echo -e "    ✨ zsh-autosuggestions   — fish-like suggestions"
    echo -e "    🎨 zsh-syntax-highlight — fish-like highlighting"
fi
echo -e "    🚀 Starship             — prompt (Catppuccin Mocha)"
echo -e "    🔤 MesloLGS NF          — nerd font"
echo -e "    🟢 fnm                  — Node version manager (fast!)"
echo -e "    📦 bat eza fd rg        — modern coreutils"
echo -e "    📊 btop                 — system monitor"
echo -e "    🔀 lazygit + delta      — git tools"
echo -e "    📁 zoxide               — smart cd"
echo -e "    🔍 fzf                  — fuzzy finder"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "    1. Restart your terminal (or open ${BOLD}Ghostty${NC})"
echo -e "    2. Node is ready: ${BOLD}node --version${NC}"
echo -e "    3. Pin a project: ${BOLD}echo 22 > .node-version${NC} (fnm auto-switches)"
echo -e "    4. Try: ${BOLD}Ctrl+R${NC} (fzf history) / ${BOLD}Ctrl+T${NC} (fzf files)"
echo ""
