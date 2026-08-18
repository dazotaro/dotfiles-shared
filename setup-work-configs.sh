#!/usr/bin/env bash
# Install the four work-machine configs that are copied rather than stowed.
#
# These carry identity (git email, SSH key) or would be swallowed by Stow
# (~/.claude), so they are deliberately not part of any Stow package. See
# reference/work/README.md.
#
# Dry-run by default. Pass --apply to write.
#
# Existing files are NEVER silently overwritten — they are backed up with a
# timestamp suffix. An existing SSH private key is never touched at all.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$REPO_DIR/reference/work"
APPLY=0
EMAIL=""
NAME=""
KEY="$HOME/.ssh/id_ed25519_work"

usage() {
  cat <<EOF
usage: $(basename "$0") --email <addr> --name <"Full Name"> [--apply]

  --email   work email address, written into ~/.gitconfig
  --name    full name, written into ~/.gitconfig
  --apply   actually write files (default is a dry run)
EOF
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
  --email)
    EMAIL="${2:-}"
    shift 2
    ;;
  --name)
    NAME="${2:-}"
    shift 2
    ;;
  --apply)
    APPLY=1
    shift
    ;;
  -h | --help) usage ;;
  *)
    echo "unknown argument: $1" >&2
    usage
    ;;
  esac
done

[ -n "$EMAIL" ] || { echo "--email is required" >&2; usage; }
[ -n "$NAME" ] || { echo "--name is required" >&2; usage; }

case "$EMAIL" in
*@*.*) ;;
*)
  echo "--email does not look like an address: $EMAIL" >&2
  exit 1
  ;;
esac

[ -d "$TPL" ] || { echo "template dir missing: $TPL" >&2; exit 1; }

STAMP="$(date +%Y%m%d%H%M%S)"
say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

# Back up an existing real file, then report the action.
backup_if_present() {
  local dest="$1"
  [ -e "$dest" ] || [ -L "$dest" ] || return 0
  if [ "$APPLY" = 1 ]; then
    mv "$dest" "$dest.pre-work.$STAMP"
    warn "existing $dest moved to $dest.pre-work.$STAMP"
  else
    warn "$dest exists — would be moved to $dest.pre-work.$STAMP"
  fi
}

install_tpl() {
  local src="$1" dest="$2" mode="$3"
  backup_if_present "$dest"
  if [ "$APPLY" = 1 ]; then
    sed -e "s|__WORK_EMAIL__|$EMAIL|g" -e "s|__WORK_NAME__|$NAME|g" "$src" >"$dest"
    chmod "$mode" "$dest"
    say "wrote $dest (mode $mode)"
  else
    say "would write $dest (mode $mode) from $(basename "$src")"
  fi
}

say "email:  $EMAIL"
say "name:   $NAME"
say "mode:   $([ "$APPLY" = 1 ] && echo APPLY || echo 'DRY RUN — nothing will be written')"
say ""

# --- 1. ~/.gitconfig --------------------------------------------------------
say "=== 1. ~/.gitconfig ==="
install_tpl "$TPL/gitconfig" "$HOME/.gitconfig" 644
say ""

# --- 2. ~/.ssh --------------------------------------------------------------
say "=== 2. ~/.ssh/config and a fresh key ==="
if [ "$APPLY" = 1 ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
fi
install_tpl "$TPL/ssh_config" "$HOME/.ssh/config" 600

if [ -f "$KEY" ]; then
  warn "$KEY already exists — NOT touching it. A private key is never overwritten."
elif [ "$APPLY" = 1 ]; then
  say "generating a fresh ed25519 keypair (you will be prompted for a passphrase)"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY"
  chmod 600 "$KEY"
  chmod 644 "$KEY.pub"
else
  say "would generate: ssh-keygen -t ed25519 -C \"$EMAIL\" -f \"$KEY\""
fi
say ""

# --- 3. ~/.aws/config -------------------------------------------------------
say "=== 3. ~/.aws/config ==="
if [ "$APPLY" = 1 ]; then mkdir -p "$HOME/.aws"; fi
install_tpl "$TPL/aws_config" "$HOME/.aws/config" 600
say ""

# --- 4. ~/.claude/CLAUDE.md -------------------------------------------------
say "=== 4. ~/.claude/CLAUDE.md ==="
# ~/.claude MUST be a real directory. If it does not exist and something later
# stows a package targeting it, Stow folds and symlinks the whole directory into
# this repo — and Claude Code would then write session data into a git checkout.
if [ -L "$HOME/.claude" ]; then
  warn "$HOME/.claude is a SYMLINK. Claude Code would write session state through it."
  warn "unstow whatever owns it before continuing."
elif [ "$APPLY" = 1 ]; then
  mkdir -p "$HOME/.claude"
  say "ensured $HOME/.claude is a real directory"
else
  say "would ensure $HOME/.claude is a real directory"
fi
install_tpl "$TPL/CLAUDE.md" "$HOME/.claude/CLAUDE.md" 644
say ""

# --- verify -----------------------------------------------------------------
if [ "$APPLY" = 1 ]; then
  say "=== verify ==="
  say "git identity: $(git config --global user.name) <$(git config --global user.email)>"
  say "credential helper: $(git config --global credential.helper)"
  if [ -f "$KEY.pub" ]; then
    say ""
    say "public key to upload to the work forge (the .pub half ONLY):"
    cat "$KEY.pub"
  fi
  say ""
  say "left to do by hand:"
  say "  - add work forge Host blocks to ~/.ssh/config"
  say "  - add profiles to ~/.aws/config when credentials arrive"
  say "  - do NOT set a default AWS_PROFILE; prefix each call instead"
else
  say "re-run with --apply to write."
fi
