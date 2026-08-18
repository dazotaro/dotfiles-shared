# dotfiles-shared

Portable terminal and editor configuration, shared across Linux and macOS via [GNU Stow](https://www.gnu.org/software/stow/).

This repo is **public on purpose**. Being public is what lets a machine clone it with no SSH key, no GitHub account, and no token — which is the point when one of the machines is not yours to put credentials on. The tradeoff is that everything here is world-readable, so it contains only editor, terminal, prompt, and shell-alias configuration.

Identity-bearing configuration — git identity, SSH, AWS profiles, Claude Code project context — lives in a separate private repo and is never stowed on a work machine.

## Layout

Each top-level directory is an independent Stow package. Stow's default target is the parent of the current directory, so running it from a checkout in `$HOME` puts symlinks in the right place.

| Package | Installs to |
|---|---|
| `bash` | `~/.bashrc`, `~/.bash_profile` |
| `nvim` | `~/.config/nvim/` |
| `ghostty` | `~/.config/ghostty/config` |
| `starship` | `~/.config/starship.toml` |
| `tmux` | `~/.tmux.conf` |

`reference/` is documentation and templates, not a Stow package. Don't stow it.

**Neovim only.** There is deliberately no package for legacy vim, Alacritty, or WezTerm — Ghostty and Neovim are the whole toolchain here. Anything older stays in the private repo.

## Install

Setting up a fresh Mac from nothing? Follow **[MACOS-SETUP.md](MACOS-SETUP.md)** — it covers Xcode CLT, Homebrew, the toolchain, Node, Ghostty's config-path trap, and Claude Code, in order.

Already have the tools:

```sh
git clone https://github.com/dazotaro/dotfiles-shared.git ~/dotfiles-shared
cd ~/dotfiles-shared
./bootstrap.sh          # prints what it would do
./bootstrap.sh --apply  # actually does it
```

Or by hand:

```sh
stow -n -v bash nvim ghostty starship tmux   # dry run first, always
stow bash nvim ghostty starship tmux
```

## Work machines: four configs that are copied, not stowed

`~/.gitconfig`, `~/.ssh/config`, `~/.aws/config`, and `~/.claude/CLAUDE.md` are **not** Stow packages. Two reasons:

- **Three of them carry identity.** A stowed `~/.gitconfig` would be one file serving both machines, and the entire point is that a work identity and a personal identity never share a file.
- **`~/.claude` would swallow this repo.** Claude Code writes settings, history, and project state into it. If the directory doesn't exist when you stow, Stow folds and symlinks the *whole directory* into this checkout — and Claude Code would then be writing session data into a public git repo.

Install them with:

```sh
./setup-work-configs.sh            # prompts for email and name; dry run
./setup-work-configs.sh --apply    # prompts, then writes
```

**Let it prompt.** Passing `--email` puts the address in `~/.bash_history`; answering a prompt leaves no trace on disk. The flags exist for scripted use.

No address is committed here either. The templates in `reference/work/` carry `__WORK_EMAIL__` / `__WORK_NAME__` placeholders substituted at install time, so a work address never lands in a public repo.

Key generation **requires a terminal**. With stdin redirected, `ssh-keygen` reads EOF as an empty passphrase and silently writes an unprotected private key, so the script refuses rather than guessing — the other three configs still install.

The script backs up anything it would replace with a timestamped suffix, and **never overwrites an existing SSH private key**. Details and the reasoning behind each template are in [`reference/work/README.md`](reference/work/README.md).

## Per-machine differences go in local files, never in this repo

Both shared configs point at an untracked local file that is loaded **last**, so it overrides everything above it:

| Shared file | Local override | Loaded |
|---|---|---|
| `~/.bashrc` | `~/.bashrc.local` | sourced at end of `.bashrc` |
| `~/.config/ghostty/config` | `~/.config/ghostty/config.local` | Ghostty processes `config-file` at end-of-file |

That is where a per-host `PATH`, a larger `font-size` for a Retina panel, or an `AWS_PROFILE` belongs.

## AI plugins are off by default

`nvim` ships three AI integrations. Two of them send buffer contents to a third-party inference endpoint, and both are **disabled unless you opt in per machine**:

| Plugin | Sends code to | Default | Gate |
|---|---|---|---|
| `avante.nvim` | `api.deepseek.com` | **off** | `NVIM_AI_EXTERNAL=1` |
| `copilot.vim` | GitHub / Microsoft, and needs an account signed in inside the editor | **off** | none — off unconditionally, also costs ~600MB/session |
| `claudecode.nvim` | drives the local Claude Code CLI — no independent egress | on | — |

To enable `avante` on a machine where the code in your buffers is yours to send:

```sh
echo 'export NVIM_AI_EXTERNAL=1' >> ~/.bashrc.local
```

The gate is deliberately **fail-safe**: with the variable unset the plugins don't load, so a machine that was never configured is protected rather than exposed. Getting this backwards — default on, disable per machine — means one forgotten step leaks source code.

## What must never land here

- **Any credential** — keys, tokens, `.netrc`, `credentials` files
- **Git identity** — a personal email in `.gitconfig` stamps every commit on every machine, permanently
- **`AWS_PROFILE` defaults** — on a machine holding more than one account's credentials, a stale default is how you write to the wrong account. Prefix each invocation instead: `AWS_PROFILE=x aws ...`
- **Claude Code `project-memories/`** — personal project context by definition
- **Absolute home paths** — use `$HOME`. A hardcoded `/home/<user>` breaks on macOS, where home is `/Users/<user>`
- **Unguarded `source` of an optional tool's env** — it errors on every shell start on the machine that lacks it

## Platform notes

**Homebrew prefix** is the single fact most divergence keys off: `/opt/homebrew` on Apple Silicon, `/usr/local` on Intel Macs, `/home/linuxbrew/.linuxbrew` on Linux. `.bashrc` detects it into `$BREW_PREFIX` and everything downstream uses that.

**macOS starts login shells**, so `~/.bash_profile` runs and `~/.bashrc` would never load without the source line in it. Keep `.bash_profile` thin.

**macOS ships bash 3.2** and defaults to zsh. For bash 5, `brew install bash` and point the terminal at it — in Ghostty, `command = /opt/homebrew/bin/bash -l` in `config.local`. That avoids editing `/etc/shells` or running `chsh`, which is worth avoiding on a managed machine.

**Ghostty on macOS reads two config paths**: `~/.config/ghostty/config` and `~/Library/Application Support/com.mitchellh.ghostty/config`. The Application Support one loads **after**, so it wins. If Ghostty wrote one on first launch, delete it or the stowed config is silently ignored.

**`~/.profile` is deliberately not in this repo.** Bash never reads it when `~/.bash_profile` exists, so its contents were dead. What mattered from it now lives in `.bashrc`. It stays in the private repo on Linux, where display managers do read it for session environment.

## Stow gotchas

**Never use `--adopt`.** It moves existing target files *into* the repo. On a machine you don't own, that pulls that machine's files into this working tree. Dry-run with `-n -v` instead.

**Folding**: when a target directory doesn't exist, Stow symlinks the whole directory rather than each file. So `~/.config/nvim` becomes a symlink into this repo, and LazyVim writes `lazy-lock.json` in here. That file is gitignored, which is why folding is fine.

**Case-insensitive filesystems** (APFS default) collide on files differing only by case. Nothing here does.

To remove: `stow -D <package>`. To re-link after moving the checkout: `stow -R <package>`.
