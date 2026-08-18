# Reference: work-machine `~/.claude/CLAUDE.md`

**Copy this file's body to `~/.claude/CLAUDE.md` on the work machine. Do not stow it.**

Why copied rather than stowed: Claude Code writes constantly into `~/.claude/` — settings, history, project state. If `~/.claude` doesn't already exist, Stow folds and symlinks the *whole directory* into this repo, so Claude Code would then be writing session data into a public git checkout. Copying one file avoids the question entirely.

Why not the personal `~/.claude/` at all: it carries `project-memories/`, a global `CLAUDE.md` full of side-project context, and an 11 KB `settings.json` of plugins. Personal project context on a company machine is one direction of the problem; company source landing in a session that also touches side-project work is the worse direction.

---

## Body — copy from here down

```markdown
- Write simple commit messages. Keep them brief.
- Never include references to Claude or AI assistance in commit messages.
- Use an education style — explain the reasoning, not just the change.
- Never use `git push --force` or `git push --force-with-lease`.

## Bash command style

- **Never use compound commands** like `cd /path && command`. Permission matching
  reads only the first token, so `cd /path && rm -rf /` matches a `cd` rule and
  slips past deny rules. Run `cd /path` as its own call — the working directory
  persists between calls — then run the real command.
- **Never use multi-line commands** with `\` continuations. Wildcards in
  permission patterns do not match across newlines, so a split `git add \` on one
  line with files on the next won't match `Bash(git add *)`. One line per command.
- **Stage in a separate call, then commit.** Hooks that inspect the index run
  before the command does, so `git add X; git commit` in a single call shows them
  an empty index.

## Branching

- Pull the default branch before starting new work.
- Never commit directly to the default branch — branch first, with a descriptive
  name.
- Never push without explicit approval.
- Never merge into the default branch without approval for that specific merge.
  Approval for one merge is not approval for the next.

## Tests

Consider all three levels and propose which fit:

- **Unit** — individual functions and modules in isolation
- **Integration** — components together: database queries, service interactions
- **E2E** — full request/response flows through the running system

Default to unit plus integration. Ask whether e2e is wanted when the change
touches an API endpoint or a user-facing flow.

Prefer black-box tests: assert on observable behaviour through public interfaces,
not on internal state or implementation details.

## Type and lint checks

After editing Python, run the type checker before committing. After editing
TypeScript, do the same. Skip for non-code files.

## Verification

Report outcomes as they are. If tests fail, say so and show the output. If a step
was skipped, say which. Do not describe work as done until it is verified.
```

---

## What was deliberately stripped

Removed from the personal version, and why:

- **Beads / `bd` task tracking** — depends on a `.beads/` workspace and a Dolt remote that don't exist here.
- **Worktree + beads redirect mechanics** — same reason.
- **Plugin instructions** (`pr-review-toolkit`, `security-guidance`, `feature-dev`, `vercel`, `pyright-lsp`, `typescript-lsp`) — those plugins aren't installed on this machine, and the generic intent is covered by the type-check and test sections above.
- **`AGENTS.md` handling** — specific to repos initialised by `bd init`.
- **Session-log and memory-directory conventions** — personal project continuity.
- **Every named side project** — the personal file references specific repos and their commit statistics by name. None of that belongs on a work machine.
- **`AWS_PROFILE` prefix rule** — kept in spirit in the shared `.bashrc` comment, but the personal version names personal account profiles.

## The three sibling configs, also hand-written not stowed

`~/.gitconfig` — work email, `credential.helper = osxkeychain` (never `store`, which writes plaintext to `~/.git-credentials`). The full sanitized version is in the day-1 audit doc, §10d.

`~/.ssh/config` — generate a fresh keypair, `ssh-keygen -t ed25519`. Never copy a private key across machines. Do not carry over `StrictHostKeyChecking no`, which disables the host-key check that protects against MITM.

`~/.aws/config` — start empty. Add profiles when work credentials arrive.
