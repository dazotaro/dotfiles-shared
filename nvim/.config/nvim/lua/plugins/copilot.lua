-- github/copilot.vim
--
-- OFF unless explicitly opted in, for two independent reasons:
--   1. RAM — roughly 600MB per nvim session, which is why it was already off.
--   2. It requires authenticating a GitHub account inside the editor and sends
--      buffer contents to that provider. On a machine where neither the account
--      nor the code is yours to use that way, both halves are a problem.
--
-- Same fail-safe gate as avante.lua: unset means off.
--     echo 'export NVIM_AI_EXTERNAL=1' >> ~/.bashrc.local
return {
  "github/copilot.vim",
  enabled = function()
    return os.getenv("NVIM_AI_EXTERNAL") == "1"
  end,
}
