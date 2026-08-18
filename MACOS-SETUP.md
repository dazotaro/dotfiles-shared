# macOS setup

Getting a fresh Mac from nothing to a working terminal, in the order things have to happen.

This is the machine-generic half. If you are setting up a work machine, the policy-specific steps — security training, disk encryption, certificate checks, and whatever your employer requires — live in your own private notes and come **first**. Nothing here substitutes for them.

## 1. Xcode Command Line Tools

```sh
xcode-select --install
```

Opens a GUI installer and returns immediately. Wait for it to finish — this is the slowest step by a wide margin.

```sh
xcode-select -p        # expect /Library/Developer/CommandLineTools
git --version
```

The `git` you get here is Apple's. Homebrew's is newer and will shadow it in step 3; that is intended, since `git-delta` as a pager wants a current git.

## 2. Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

It will ask for your password and then tell you to add itself to your PATH. **Skip that.** `.bashrc` in this repo detects the Homebrew prefix itself, so adding it manually just creates a duplicate. For the current session only:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"     # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"        # Intel
```

## 3. The toolchain

```sh
brew install git neovim tmux ripgrep fd fzf bat eza git-delta starship zoxide stow btop uv
brew install --cask ghostty font-jetbrains-mono-nerd-font
```

`stow` installs the config in step 5. `uv` is the Python toolchain.

**The Nerd Font cask is not optional.** Both the Ghostty config and the Starship prompt use its glyphs; without it you get tofu boxes everywhere.

On a managed machine, install only what has actually been approved. `install-macos.sh` in this repo carries the same list and runs it for you, dry-run by default.

## 4. Node, via nvm

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

Then open a **new** shell:

```sh
nvm install --lts
```

Deliberately not `brew install node` — the formula fights version managers, and `.bashrc` here already wires up `$NVM_DIR`.

## 5. Clone and link this repo

```sh
git clone https://github.com/dazotaro/dotfiles-shared.git ~/dotfiles-shared
cd ~/dotfiles-shared
./bootstrap.sh              # dry run — prints every symlink it would make
./bootstrap.sh --apply
```

Clone to `~/dotfiles-shared` exactly. Stow's target is the checkout's parent directory, and `bootstrap.sh` refuses to run if that is not `$HOME`.

Anonymous HTTPS, no credential of any kind — no SSH key, no account, no token. That is deliberate: it means this machine cannot push, so config can never flow from here back into the repo.

If the dry run names a real file blocking a link, move it aside rather than letting Stow near it:

```sh
mv ~/.bashrc ~/.bashrc.pre-stow
```

Open a new shell. You should get the Starship prompt, `ll` aliased to `eza`, and `cat` to `bat`.

## 6. Ghostty first run

### The trap that silently eats your config

macOS Ghostty reads **both** `~/.config/ghostty/config` (the stowed one) and `~/Library/Application Support/com.mitchellh.ghostty/config` — and the Application Support one loads **after**, so it wins. If Ghostty wrote one on first launch, your config looks installed and does nothing.

```sh
ls -la ~/Library/Application\ Support/com.mitchellh.ghostty/config
```

Delete it if it exists.

### Font size

10.5pt is tuned for Linux fractional scaling and reads tiny on a Retina panel. Don't edit the shared config — use the local override, which loads last and wins:

```sh
printf 'font-size = 14\n' >> ~/.config/ghostty/config.local
```

`config.local` is gitignored, so it stays machine-specific. It is also where `command = /opt/homebrew/bin/bash -l` goes if you want Homebrew's bash 5 without touching `/etc/shells` or running `chsh`.

### Keybindings

Splits are `ctrl+shift+\` and `ctrl+shift+-`; navigation is `ctrl+shift+arrow`. These deliberately override Ghostty's defaults.

## 7. The four copied-not-stowed configs

```sh
cd ~/dotfiles-shared
./setup-work-configs.sh            # prompts for email and name; dry run
./setup-work-configs.sh --apply
```

**Let it prompt.** Passing `--email` puts the address in `~/.bash_history` for no benefit.

Writes `~/.gitconfig`, `~/.ssh/config`, `~/.aws/config`, and `~/.claude/CLAUDE.md`; generates a fresh ed25519 key; backs up anything it replaces; never overwrites an existing private key. See [`reference/work/README.md`](reference/work/README.md) for why each is copied rather than stowed.

**Key generation needs a real terminal.** With stdin redirected, `ssh-keygen` reads EOF as an empty passphrase and silently writes an unprotected key. The script refuses in that case — run it by hand:

```sh
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519_work
```

Upload only the `.pub` half:

```sh
cat ~/.ssh/id_ed25519_work.pub
```

## 8. Claude Code

Use the native installer, not npm — it is self-contained and needs no Node:

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

It installs to `~/.local/share/claude/versions/<version>` and symlinks `~/.local/bin/claude`. The `.bashrc` in this repo already puts `~/.local/bin` on PATH, so it resolves in a new shell with no extra wiring.

```sh
claude --version
```

The installer accepts an optional target — `stable`, `latest`, or an exact version — if you need to pin.

`~/.claude/CLAUDE.md` comes from step 7. **Do not stow `~/.claude`**: Claude Code writes settings, history, and project state into that directory, and if it does not already exist Stow will fold and symlink the whole thing into this checkout.

On a managed machine, install this only if it is approved, and sign in with the account your employer provides — never a personal one, and never a personal GitHub inside it.

## Verification

- [ ] `xcode-select -p` returns a path
- [ ] `brew --version` works
- [ ] `starship eza rg fd fzf bat delta zoxide stow uv` all resolve on PATH
- [ ] `node --version` reports the nvm-installed version
- [ ] `nvim` opens and installs plugins with no errors
- [ ] New Ghostty window: Starship prompt, no tofu glyphs, readable font size
- [ ] No `~/Library/Application Support/com.mitchellh.ghostty/config`
- [ ] `git config --global user.email` shows the address you intended
- [ ] `git config --global credential.helper` shows `osxkeychain`
- [ ] `~/.ssh/id_ed25519_work` exists **with a passphrase**
- [ ] `~/.aws/config` has no profiles, and no default `AWS_PROFILE` is set anywhere
- [ ] `echo $NVIM_AI_EXTERNAL` is empty on any machine whose code is not yours to send

## One thing to get right on a machine that isn't yours

`NVIM_AI_EXTERNAL` gates `avante.nvim`, which ships buffer contents to a third-party inference endpoint. **Leave it unset** on any machine where the code in your buffers is not yours to send onward. The gate is fail-safe — unset means the plugin does not load — so the correct action is simply to never set it. `copilot.vim` is off unconditionally.
