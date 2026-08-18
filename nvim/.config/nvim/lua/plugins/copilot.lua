-- github/copilot.vim
--
-- OFF unconditionally. Two independent reasons, and either alone is sufficient:
--   1. RAM — roughly 600MB per nvim session. This was the original reason and it
--      applies on every machine, personal ones included.
--   2. It authenticates a GitHub account inside the editor and sends buffer
--      contents to that provider. On a machine where neither the account nor the
--      code is yours to use that way, both halves are a problem.
--
-- Note this is NOT gated on NVIM_AI_EXTERNAL. That variable opts in to external
-- inference on a personal machine, and reason 1 still says no there. Flip this
-- to true by hand if you ever actually want it.
return {
  "github/copilot.vim",
  enabled = false,
}
