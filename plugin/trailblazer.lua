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
api.nvim_create_user_command("TrailBlazerNewTrailMark", function() tb.new_trail_mark() end, {})
api.nvim_create_user_command("TrailBlazerTrackBack", function() tb.track_back() end, {})
api.nvim_create_user_command("TrailBlazerPeekMoveForward", function() tb.peek_move_forward() end, {})
api.nvim_create_user_command("TrailBlazerPeekMoveBackward", function() tb.peek_move_backward() end, {})
api.nvim_create_user_command("TrailBlazerDeleteAllTrailMarks", function() tb.delete_all_trail_marks() end, {})
api.nvim_create_user_command("TrailBlazerPasteAtLastTrailMark", function() tb.paste_at_last_trail_mark() end, {})
api.nvim_create_user_command("TrailBlazerPasteAtAllTrailMarks", function() tb.paste_at_all_trail_marks() end, {})
