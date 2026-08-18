#!/usr/bin/env bash
# Link the shared config into $HOME with GNU Stow.
#
# Dry-run by default. Pass --apply to actually create symlinks.
#
# Deliberately does NOT use `stow --adopt`, which moves existing target files
# INTO this repo. On a machine that is not yours, that pulls that machine's
# files into a public repo's working tree.

set -euo pipefail

PACKAGES=(bash nvim ghostty starship tmux)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

case "$(uname -s)" in
Darwin) OS=macos ;;
Linux) OS=linux ;;
*) OS=unknown ;;
esac

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

say "repo:     $REPO_DIR"
say "target:   $HOME"
say "platform: $OS"
say ""

# --- preflight -------------------------------------------------------------

if ! command -v stow >/dev/null 2>&1; then
  say "stow is not installed."
  [ "$OS" = macos ] && say "  brew install stow"
  [ "$OS" = linux ] && say "  sudo dnf install stow"
  exit 1
fi

# Stow's default target is the PARENT of the current directory. That is only
# $HOME if this checkout sits directly in $HOME.
if [ "$(dirname "$REPO_DIR")" != "$HOME" ]; then
  warn "checkout is not directly under \$HOME, so stow's default target is wrong."
  warn "either move it to $HOME/$(basename "$REPO_DIR") or pass --target=\"$HOME\" yourself."
  exit 1
fi

# --- macOS-specific traps --------------------------------------------------

if [ "$OS" = macos ]; then
  GHOSTTY_APPSUPPORT="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  if [ -e "$GHOSTTY_APPSUPPORT" ]; then
    warn "an Application Support Ghostty config exists:"
    warn "  $GHOSTTY_APPSUPPORT"
    warn "it is loaded AFTER ~/.config/ghostty/config and therefore WINS."
    warn "delete or empty it, or the stowed config is silently ignored."
    say ""
  fi

  # The bash package links ~/.bash_profile and ~/.bashrc. zsh -- the macOS
  # default -- never opens either, so on a stock Mac these links are made
  # successfully and do nothing at all. Warn rather than let that pass silently.
  case "${SHELL:-}" in
  *bash) ;;
  *)
    warn "login shell is ${SHELL:-unset}, not bash."
    warn "zsh does not read ~/.bash_profile or ~/.bashrc, so those links would be inert."
    warn "  chsh -s /bin/bash    # then open a NEW terminal; \$SHELL updates on next login"
    say ""
    ;;
  esac

  if [ ! -d /opt/homebrew ] && [ ! -d /usr/local/Homebrew ]; then
    warn "Homebrew not found — most tools these configs reference will be missing."
    say ""
  fi
fi

# --- report existing non-symlink targets -----------------------------------
# These are what stow will refuse to overwrite. Better to see them named than
# to read a wall of stow conflict output.

CONFLICTS=0
for f in .bashrc .bash_profile .tmux.conf; do
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    warn "$HOME/$f exists and is a real file, not a symlink — stow will refuse."
    warn "  move it aside:  mv \"$HOME/$f\" \"$HOME/$f.pre-stow\""
    CONFLICTS=1
  fi
done
[ "$CONFLICTS" = 1 ] && say ""

# --- stow ------------------------------------------------------------------

if [ "$APPLY" = 1 ]; then
  say "linking: ${PACKAGES[*]}"
  stow --verbose "${PACKAGES[@]}"
  say ""
  say "done. next steps:"
  say "  - put per-machine settings in ~/.bashrc.local (never in this repo)"
  say "  - put per-machine Ghostty settings in ~/.config/ghostty/config.local"
  say "  - open a new shell to pick up ~/.bashrc"
else
  say "DRY RUN — nothing will be written. re-run with --apply to link."
  say ""
  stow -n --verbose "${PACKAGES[@]}"
fi
