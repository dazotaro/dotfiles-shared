# macOS setup

Getting a fresh Mac from nothing to a working terminal, in the order things have to happen.

Complete as a procedure. Where a step depends on your employer's specifics — which tools are approved, which forge hosts the code, what training is mandatory — it says so and stops, rather than guessing on your behalf. Keep those answers in your own private notes; they do not belong in a public repo, and neither does a description of any particular company's security posture.

Phase 0 is not optional on a machine you do not own.

## 0. Before any of this, on a machine you don't own

None of these involve Homebrew. They are the reasons the rest is safe to do.

**Finish whatever security-awareness training is mandatory, first.** On many employment agreements, incomplete training is the tripwire that converts any other minor infraction into a formal process. It is usually an hour, and it removes a whole category of risk. Save the completion record.

**Confirm what is actually approved before installing anything.** Get it in writing from whoever approves it, and keep your install list identical to the list you sent. The diff between `install-macos.sh` and that message is your record that nothing extra went on. If there is no self-service software catalog on the machine, then approval plus admin rights *is* the sanctioned path — and adding anything to the list later needs the same approval.

**Turn on full-disk encryption** if it is not already on — System Settings → Privacy & Security → FileVault → Turn On. `fdesetup status` tells you where you stand.

Two things in that flow are easy to get wrong:

- macOS offers *"Allow my iCloud account to unlock my disk"* or *"Create a recovery key"*. **Take the recovery key** on any machine where you should not be signing in a personal Apple ID — a shared Apple ID enables Universal Clipboard and Handoff, which is a real data path between your devices and that machine.
- Store the key **off** the machine. If the disk will not unlock, a password manager living on that disk is worthless. Paper is fine, and better than nothing stored anywhere.

Ask whether your employer escrows the key. If the Mac was not enrolled via Automated Device Enrollment, it very likely does not — in which case your copy is the only one.

**Check for a corporate root certificate.** Keychain Access → System Keychains → **System** → View → Show Certificates. Anything that is not Apple's and not a recognizable public CA — corporate roots usually carry a company or security-vendor name. If one is present, HTTPS is decryptable in transit and the machine is not a place for anything you would not want read. `scutil --proxy` is a quick cross-check.

Record the answers privately. Do not publish them: a document naming a company alongside its endpoint tooling and the state of its disk encryption is a reconnaissance document, and an unlisted gist is not a private one.

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

## 9. A PC keyboard on a Mac

If you use an external PC keyboard, the modifiers are in the wrong physical places by default. This is one System Settings change and no install.

### Why Alt+Tab does nothing

macOS maps the key labelled **Win** to Command and the key labelled **Alt** to Option. The app switcher is Cmd+Tab, so on a PC keyboard it lands on Win+Tab.

Look at the physical order, left of the spacebar:

```
PC keyboard:   Ctrl   Win      Alt      [space]
Mac keyboard:  Ctrl   Option   Command  [space]
```

Win sits where Option belongs and Alt sits where Command belongs. macOS's default mapping preserves the *labels* and therefore inverts the *positions*.

### Do NOT remap the laptop's own keyboard

The built-in keyboard is already in Mac order — `Ctrl / Option / Command / space` — so Command already sits next to the spacebar. There is no mismatch to correct, and remapping it would *create* the one you just removed.

The principle: you are standardising on **position, not label**. After the swap, the key next to the spacebar is Command on both keyboards. The external keyboard's legends now lie — the key printed "Alt" is Command — but your thumb finds that key by position, never by reading it. Consistent position beats honest labelling.

### The fix: swap Option and Command, per keyboard

**System Settings → Keyboard → Keyboard Shortcuts… → Modifier Keys** (older macOS: System Preferences → Keyboard → Modifier Keys). Pick the external keyboard from the **Select keyboard** dropdown first — the setting is per-device, so the laptop's built-in keyboard keeps its normal behaviour.

Then set:

| Physical key | Change to |
|---|---|
| Option (⌥) | **Command** |
| Command (⌘) | **Option** |

Two things improve at once. Alt+Tab becomes the app switcher, and Command now sits next to the spacebar exactly where a Mac keyboard has it — so every `Cmd+C` / `Cmd+S` / `Cmd+Q` falls under the thumb where it is designed to.

### What this does not fix

**macOS is still macOS.** Copy stays Cmd+C, which is now the physical Alt key — it does **not** become Ctrl+C.

Resist the temptation to remap Ctrl→Command to get Linux-style copy/paste. It breaks Ctrl+C as SIGINT, Ctrl+D, Ctrl+R, and Ctrl+A/E line editing — everything a terminal depends on. For anyone who lives in a shell, that trade is not close. Ghostty's bindings here are all `ctrl+shift+*` and are unaffected by the Option/Command swap.

**Cmd+Tab switches applications, not windows.** That is a real behavioural difference from Alt+Tab, not a configuration problem. `Cmd+`` ` (backtick) cycles windows *within* the front application, and Mission Control shows everything. If you want a single window-level switcher, rebind **Move focus to next window** under Keyboard Shortcuts → Keyboard.

**Home/End** scroll the document rather than jumping to line start/end. In a shell, Ctrl+A and Ctrl+E do what you want.

### Don't fight the platform beyond this

The swap fixes a physical mismatch. Converting macOS wholesale into Linux is a different and worse project.

The Ctrl/Cmd split is genuinely *better* for terminal work, not just different. macOS reserves Cmd for application shortcuts and leaves Ctrl entirely to the shell, so Ctrl+C means SIGINT always and everywhere with no collision. Linux overloads Ctrl+C — interrupt in a terminal, copy everywhere else — which is exactly why Linux terminals need Ctrl+Shift+C as a workaround. macOS never needed the workaround.

A half-converted machine is the worst state to be in: neither muscle memory becomes reliable. Two platforms with two clear idioms is easier to hold than two platforms bent halfway into each other.

**The one exception worth making is the terminal**, since that is where the muscle memory actually lives. The Ghostty config here binds `ctrl+shift+c` / `ctrl+shift+v` explicitly on both platforms — a no-op on Linux where it is already the default, and additive on macOS where Cmd+C keeps working too. So copy and paste use the identical chord on both machines while nothing system-wide is touched.

### If you share one keyboard between two machines

Worth noticing what the swap buys in that setup: `Alt+Tab` becomes the switcher on **both** hosts — windows on Linux, applications on macOS — so your most-used chord stops depending on which machine the monitor is showing. Combined with the terminal bindings above, the two chords you hit most often are now the same on both.

### Karabiner-Elements: capable, and the wrong tool on a managed machine

Karabiner is what everyone recommends, and it does far more than the built-in panel. Do not reach for it here without asking first. It installs a **DriverKit system extension** that presents a virtual HID device, which means it (a) needs a third-party install and an explicit system-extension approval, and (b) is by design an input interceptor that sees every keystroke. On a centrally managed machine that is precisely the software profile endpoint tooling is built to flag. The built-in Modifier Keys panel solves the actual problem with no install at all.

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
- [ ] If using a PC keyboard: Option/Command swapped **for that keyboard only**, and Alt+Tab switches apps

## Rules for a machine that isn't yours

The setup above is only safe if these hold.

**Leave `NVIM_AI_EXTERNAL` unset.** It gates `avante.nvim`, which ships buffer contents to a third-party inference endpoint. On a machine where the code in your buffers is not yours to send onward, that is a confidentiality problem rather than a preference — and typically a policy violation on its own. The gate is fail-safe: unset means the plugin never loads, so the correct action is to do nothing. `copilot.vim` is off unconditionally.

**No personal accounts of any kind.** Not an Apple ID, not GitHub, not a password manager, not a cloud-sync client, not the AI tool you use personally. A shared Apple ID silently enables Universal Clipboard and Handoff, which is a real host-to-host data path.

**No cloud sync pointed at personal files.** The sanctioned sync client on a managed Mac usually holds Full Disk Access. Never sign a personal account into it and never let it sync anything of your own — that is how personal source ends up inside a company's backups and on the drive they image when you leave.

**No screen mirroring from a personal phone.** `iPhone Mirroring` ships with macOS. Using it bridges a personal device to a machine that is centrally managed.

**Clone only what belongs there.** Not your private dotfiles repo — it needs a personal key and a personal account, which is the same rule. Not your personal notes. This repo is public precisely so it needs neither.

**No removable media** without whatever prior approval your policy requires, and nothing that mounts left parked in a hub shared between two machines.

**Lock the screen whenever you leave it.**

Keep the company-specific version of this list — names, products, clause references — in private notes, not here.
