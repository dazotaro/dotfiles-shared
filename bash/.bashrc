# ~/.bashrc: executed by bash(1) for non-login shells.
# Cross-platform: Fedora + Debian/Mint + macOS.
#
# This file is SHARED and PUBLIC. Nothing machine-specific, identifying, or
# secret belongs here. Put that in ~/.bashrc.local, which is sourced at the
# end and is never tracked.

# ===== System Init =====
# Source global bashrc (Fedora uses /etc/bashrc, as does macOS; Debian sources
# /etc/bash.bashrc automatically)
[ -f /etc/bashrc ] && . /etc/bashrc

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Source bashrc.d snippets (Fedora convention, harmless elsewhere)
if [ -d ~/.bashrc.d ]; then
  for rc in ~/.bashrc.d/*; do
    [ -f "$rc" ] && . "$rc"
  done
  unset rc
fi

# ===== Platform detection =====
# One fact drives most of the Linux/macOS divergence in this file: where
# Homebrew lives. Everything else keys off BREW_PREFIX or an existence test.
case "$(uname -s)" in
Darwin)
  OS_NAME=macos
  if [ -x /opt/homebrew/bin/brew ]; then
    BREW_PREFIX=/opt/homebrew # Apple Silicon
  elif [ -x /usr/local/bin/brew ]; then
    BREW_PREFIX=/usr/local # Intel
  fi
  ;;
Linux)
  OS_NAME=linux
  [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && BREW_PREFIX=/home/linuxbrew/.linuxbrew
  ;;
*)
  OS_NAME=unknown
  ;;
esac
export OS_NAME

# ===== Shell Options =====
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# ===== PATH Setup =====
# Core paths
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
[[ ":$PATH:" != *":$HOME/bin:"* ]] && export PATH="$HOME/bin:$PATH"

# Go (if installed system-wide). Note: this used to live in ~/.profile, which
# bash never reads when ~/.bash_profile exists — so it was dead there.
[ -d /usr/local/go/bin ] && [[ ":$PATH:" != *":/usr/local/go/bin:"* ]] && export PATH="$PATH:/usr/local/go/bin"

# Snap (Debian/Mint)
[ -d /snap/bin ] && [[ ":$PATH:" != *":/snap/bin:"* ]] && export PATH="$PATH:/snap/bin"

# ===== Homebrew =====
# Must be before tool aliases so Homebrew-installed tools are found by command -v
if [ -n "$BREW_PREFIX" ] && [ -x "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

# ===== Bash Completion =====
# macOS: bash-completion@2 ships under the Homebrew prefix.
# Linux: distro paths.
if ! shopt -oq posix; then
  if [ -n "$BREW_PREFIX" ] && [ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
    . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"
  elif [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ===== Bash Aliases =====
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# ===== Modern CLI Tool Aliases (distro-aware) =====

# bat (Debian/Ubuntu calls it 'batcat')
if command -v batcat &>/dev/null; then
  alias bat='batcat'
  alias cat='batcat'
elif command -v bat &>/dev/null; then
  alias cat='bat'
fi

# fd (Debian/Ubuntu calls it 'fdfind')
if command -v fdfind &>/dev/null; then
  alias fd='fdfind'
fi

# eza - modern ls replacement
if command -v eza &>/dev/null; then
  alias ls='eza'
  alias ll='eza -la --git --icons'
  alias lt='eza --tree --level=2'
  alias la='eza -a'
fi

# ripgrep
if command -v rg &>/dev/null; then
  alias grep='rg'
fi

# delta is used automatically by git (configure in .gitconfig)

# ===== fzf Init (cross-platform) =====
if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
elif [ -f ~/.fzf.bash ]; then
  source ~/.fzf.bash
fi

# ===== History Shortcuts =====
alias hg='history | rg'
alias hf='history | fzf'
alias he='history | fzf | bash'

# ===== Neovim Aliases =====
# NVIM_APPNAME selects an alternate config dir under ~/.config. Both aliases
# no-op harmlessly if the named profile isn't present on this machine.
alias vo='NVIM_APPNAME=nvim nvim'
alias vl='NVIM_APPNAME=nvim-lazy0 nvim'

# ===== SSH Agent Setup =====
# macOS runs an ssh-agent under launchd and sets SSH_AUTH_SOCK itself, so the
# guard below means this whole block is a no-op there. On macOS prefer
# `ssh-add --apple-use-keychain <key>` once, rather than adding it per shell.
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval $(ssh-agent -s) >/dev/null
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# ===== Terminal Tab Title =====
title() { printf '\033]0;%s\007' "$*"; }

# ===== Android SDK =====
if [ -d "$HOME/Android/Sdk" ]; then
  export ANDROID_HOME=$HOME/Android/Sdk
  export ANDROID_SDK_ROOT=$ANDROID_HOME
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/platform-tools
  export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
  # JDK 17 for Android/Gradle builds (system default JDK is too new for RN/AGP)
  [ -n "$BREW_PREFIX" ] && [ -d "$BREW_PREFIX/opt/openjdk@17" ] && export JAVA_HOME="$BREW_PREFIX/opt/openjdk@17"
fi

# ===== NVM =====
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ===== Bun =====
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# ===== Deno =====
# Guarded deliberately: unguarded, this line errors on every shell start on a
# machine without Deno installed.
[ -s "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# ===== flyctl =====
if [ -d "$HOME/.fly" ]; then
  export FLYCTL_INSTALL="$HOME/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
fi

# ===== Postgres =====
export PGSSLROOTCERT=system

# ===== zoxide =====
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# ===== Starship Prompt (must be late — sets PROMPT_COMMAND) =====
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# ===== Local overrides — NOT tracked, NOT shared =====
# Machine-specific and identity-bearing settings live here: AWS_PROFILE, tokens,
# per-host PATH entries, personal tool paths. Deliberately last so it wins.
#
# Never set a default AWS_PROFILE on a machine with more than one account's
# credentials — prefix each invocation instead (AWS_PROFILE=x aws ...).
[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
