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
api.nvim_create_user_command("TrailBlazerNewTrailMark",
  function(args) tb.new_trail_mark(tonumber(args.fargs[1]), tonumber(args.fargs[2]),
      { tonumber(args.fargs[3]), tonumber(args.fargs[4]) })
  end, { nargs = "*" })
api.nvim_create_user_command("TrailBlazerTrackBack", function(args) tb.track_back(args.args) end,
  { nargs = "?", complete = "buffer" })
api.nvim_create_user_command("TrailBlazerPeekMoveForward", function(args) tb.peek_move_forward(args.args) end,
  { nargs = "?", complete = "buffer" })
api.nvim_create_user_command("TrailBlazerPeekMoveBackward", function(args) tb.peek_move_backward(args.args) end,
  { nargs = "?", complete = "buffer" })
api.nvim_create_user_command("TrailBlazerDeleteAllTrailMarks", function(args) tb.delete_all_trail_marks(args.args) end,
  { nargs = "?", complete = "buffer" })
api.nvim_create_user_command("TrailBlazerPasteAtLastTrailMark", function(args) tb.paste_at_last_trail_mark(args.args) end
  , { nargs = "?", complete = "buffer" })
api.nvim_create_user_command("TrailBlazerPasteAtAllTrailMarks", function(args) tb.paste_at_all_trail_marks(args.args) end
  , { nargs = "?", complete = "buffer" })

-- Auto commands
api.nvim_create_autocmd("BufWritePre", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = require('trailblazer.trails').update_all_trail_mark_positions
})
api.nvim_create_autocmd("BufWritePost", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = require('trailblazer.trails').reregister_trail_marks
})
