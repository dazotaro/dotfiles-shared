#!/usr/bin/env bash
# macOS toolchain install.
#
# The package list below is EXACTLY the list submitted for approval. Do not add
# to it here — an unapproved install is a policy infraction on a managed
# machine, and the diff between this file and the approval email is the record
# that nothing extra went on.
#
# Dry-run by default. Pass --apply to install.

set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  echo "macOS only." >&2
  exit 1
fi

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

# --- the approved list -----------------------------------------------------

FORMULAE=(
  git
  neovim
  tmux
  ripgrep
  fd
  fzf
  bat
  eza
  git-delta
  starship
  zoxide
  stow
  btop
  uv # Python toolchain
)

CASKS=(
  ghostty
  font-jetbrains-mono-nerd-font
)

run() {
  if [ "$APPLY" = 1 ]; then
    echo "+ $*"
    "$@"
  else
    echo "would run: $*"
  fi
}

echo "=== 1. Xcode Command Line Tools ==="
if xcode-select -p >/dev/null 2>&1; then
  echo "already installed at $(xcode-select -p)"
else
  # This opens a GUI dialog and returns immediately. It is not scriptable past
  # this point — wait for it to finish before continuing.
  run xcode-select --install
  echo "NOTE: wait for the GUI installer to finish, then re-run this script."
  [ "$APPLY" = 1 ] && exit 0
fi
echo

echo "=== 2. Homebrew ==="
if command -v brew >/dev/null 2>&1; then
  echo "already installed at $(command -v brew)"
  BREW=$(command -v brew)
else
  echo 'would run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  if [ "$APPLY" = 1 ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  BREW=/opt/homebrew/bin/brew
  [ -x /usr/local/bin/brew ] && BREW=/usr/local/bin/brew
fi
echo

echo "=== 3. Formulae ==="
run "$BREW" install "${FORMULAE[@]}"
echo

echo "=== 4. Casks ==="
run "$BREW" install --cask "${CASKS[@]}"
echo

echo "=== 5. Node via nvm ==="
# Deliberately NOT via Homebrew — the node formula fights version managers.
# nvm appends its snippet to the first profile file that already EXISTS, out of
# ~/.bashrc ~/.bash_profile ~/.zprofile ~/.zshrc. On a fresh Mac none do and it
# skips the wiring; after bootstrap.sh, ~/.bashrc is a symlink INTO this repo
# and >> writes through it. Point it at the untracked local file instead.
echo 'would run: PROFILE=$HOME/.bashrc.local curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
if [ "$APPLY" = 1 ]; then
  touch "$HOME/.bashrc.local"
  PROFILE="$HOME/.bashrc.local" curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  echo "then, in a NEW shell:  nvm install --lts"
fi
echo

cat <<'EOF'
=== Deliberately not installed ===

  aws-cli   -- pending confirmation of the team's standard install path
  docker    -- pending confirmation the team uses containers; Docker Desktop
               licensing is not free at this company size
  bash 5    -- NOT on the approved list. The shared .bashrc is bash-3.2 clean,
               so stock macOS bash runs it fine and this is optional. Note that
               `chsh -s /bin/bash` is NOT an install -- it is a preference on
               your own account, and it is required, because zsh never reads
               ~/.bashrc. Only 5.x needs asking:
                 brew install bash
                 # then in ~/.config/ghostty/config.local:
                 #   command = /opt/homebrew/bin/bash -l
               That avoids chsh and editing /etc/shells.

=== Next ===

  ./bootstrap.sh            # dry run the symlinks
  ./bootstrap.sh --apply

Then install the four work-only configs. These are copied rather than stowed
because they carry identity, or because Stow would swallow ~/.claude:

  ./setup-work-configs.sh            # prompts for email and name; dry run
  ./setup-work-configs.sh --apply    # prompts, then writes

Let it prompt rather than passing --email; an address on the command line lands
in ~/.bash_history. Key generation needs a real terminal.

It writes ~/.gitconfig, ~/.ssh/config, ~/.aws/config and ~/.claude/CLAUDE.md,
generates a fresh ed25519 key, backs up anything it would replace, and never
overwrites an existing private key. See reference/work/README.md.
EOF
