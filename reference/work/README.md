# Work-machine configs

The four configs that are **copied, never stowed**, and that carry identity or credentials so they are not part of any Stow package.

| Template here | Installs to | Contains |
|---|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | generic engineering practice only |
| `gitconfig` | `~/.gitconfig` | work email and name, substituted at install time |
| `ssh_config` | `~/.ssh/config` | points at a freshly generated key |
| `aws_config` | `~/.aws/config` | no profiles, deliberately |

Install them with the script at the repo root:

```sh
./setup-work-configs.sh            # prompts for email and name; dry run
./setup-work-configs.sh --apply    # prompts, then writes
```

**Prefer the prompt over `--email`.** An address on the command line lands in `~/.bash_history`. A prompted answer never touches disk.

No address is committed here — the templates carry `__WORK_EMAIL__` and `__WORK_NAME__` placeholders that the script substitutes on the machine.

## Why copied and not stowed

**`~/.claude/` would swallow the repo.** Claude Code writes constantly into it — settings, history, project state. If `~/.claude` doesn't already exist when you stow, Stow folds and symlinks the *whole directory* into this checkout, so Claude Code would then be writing session data into a public git repo. The script creates `~/.claude` as a real directory first and copies one file in.

**The other three carry identity.** A stowed `~/.gitconfig` would mean one file serving both machines, and the whole point is that the work identity and the personal identity never share a file.

## Why not the personal `~/.claude/` at all

It carries `project-memories/`, a global `CLAUDE.md` full of side-project context, and an 11 KB `settings.json` of plugins. Personal project context on a company machine is one direction of the problem; company source landing in a session that also touches side-project work is the worse direction.

## What was stripped from the personal CLAUDE.md

- **Beads / `bd` task tracking** — depends on a `.beads/` workspace and a Dolt remote that don't exist here.
- **Worktree + beads redirect mechanics** — same reason.
- **Plugin instructions** (`pr-review-toolkit`, `security-guidance`, `feature-dev`, `vercel`, `pyright-lsp`, `typescript-lsp`) — those plugins aren't installed here, and the generic intent is covered by the type-check and test sections that remain.
- **`AGENTS.md` handling** — specific to repos initialised by `bd init`.
- **Session-log and memory-directory conventions** — personal project continuity.
- **Every named side project** — the personal file names specific repos and their commit statistics. None of that belongs on a work machine.
- **The `AWS_PROFILE` prefix rule** — kept in spirit in `aws_config` and the shared `.bashrc`, but the personal version names personal account profiles.

## The two lines that must never cross

From the personal `~/.gitconfig`:

- **a personal email** — it would stamp every work commit, permanently, in their history.
- **`credential.helper = store`** — writes credentials in **plaintext** to `~/.git-credentials`. On a managed machine with endpoint agents holding Full Disk Access, that is the wrong place for a plaintext secret. The template uses `osxkeychain`.

From the personal `~/.ssh/config`:

- **`StrictHostKeyChecking no`** — disables host-key verification, which is the check that protects against a man-in-the-middle. Worth removing on personal machines too.
- **any private key.** Never copy one between machines. Generate fresh, upload only the `.pub`.
