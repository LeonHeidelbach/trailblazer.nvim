local api = vim.api
local fn = vim.fn
local tb = require("trailblazer")

if fn.has("nvim-0.8") == 0 then
  api.nvim_err_writeln("trailblazer requires at least nvim-0.8")
  return
end

if vim.g.trailblazer_loaded == 1 then
  return
end

vim.g.trailblazer_loaded = 1

local cfg = {
  auto_groups = {
    trailblazer = api.nvim_create_augroup('trailblazer', { clear = true })
  }
}

-- User commands
api.nvim_create_user_command("TrailblazerNewTrailMark", function() tb.new_trail_mark() end, {})
api.nvim_create_user_command("TrailblazerTrackBack", function() tb.track_back() end, {})
