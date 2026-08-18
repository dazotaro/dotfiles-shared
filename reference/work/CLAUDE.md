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
