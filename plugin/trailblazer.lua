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
  },
}

-- Global functions for autocommand completions
function GET_AVAILABLE_TRAIL_MARK_SELECTION_MODES()
  return require("trailblazer.trails").config.custom.available_trail_mark_modes
end

function GET_AVAILABLE_TRAIL_MARK_LIST_MODES()
  return require("trailblazer.trails").config.custom.available_trail_mark_lists
end

function GET_AVAILABLE_TRAIL_MARK_STACKS()
  return require("trailblazer.trails").stacks.get_sorted_stack_names()
end

function GET_AVAILABLE_TRAIL_MARK_STACK_SORT_MODES()
  return require("trailblazer.trails").config.custom.available_trail_mark_stack_sort_modes
end

-- User commands
api.nvim_create_user_command("TrailBlazerNewTrailMark",
  function(args)
    local pos = args.fargs[3] and args.fargs[4] and
        { tonumber(args.fargs[3]), tonumber(args.fargs[4]) } or nil
    tb.new_trail_mark(tonumber(args.fargs[1]), tonumber(args.fargs[2]), pos)
  end, { nargs = "*" })

api.nvim_create_user_command("TrailBlazerTrackBack", function(args) tb.track_back(args.args) end,
  { nargs = "?", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerPeekMovePreviousUp", function(args)
  tb.peek_move_previous_up(args.args)
end, { nargs = "?", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerPeekMoveNextDown", function(args)
  tb.peek_move_next_down(args.args)
end, { nargs = "?", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerMoveToNearest", function(args)
  tb.move_to_nearest(args.fargs[1], args.fargs[2], args.fargs[3])
end, { nargs = "*", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerMoveToTrailMarkCursor", tb.move_to_trail_mark_cursor,
  {})

api.nvim_create_user_command("TrailBlazerDeleteAllTrailMarks", function(args)
  tb.delete_all_trail_marks(args.args)
end, { nargs = "?", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerPasteAtLastTrailMark", function(args)
  tb.paste_at_last_trail_mark(args.args)
end, { nargs = "?", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerPasteAtAllTrailMarks", function(args)
  tb.paste_at_all_trail_marks(args.args)
end, { nargs = "?", complete = "buffer" })

api.nvim_create_user_command("TrailBlazerTrailMarkSelectMode", function(args)
  tb.set_trail_mark_select_mode(vim.tbl_contains(GET_AVAILABLE_TRAIL_MARK_SELECTION_MODES(),
    args.args) and args.args or nil)
end, { nargs = "?", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_SELECTION_MODES" })

api.nvim_create_user_command("TrailBlazerToggleTrailMarkList", function(args)
  tb.toggle_trail_mark_list(args.fargs[1], args.fargs[2])
end, { nargs = "*", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_LIST_MODES" })

api.nvim_create_user_command("TrailBlazerOpenTrailMarkList", function(args)
  tb.open_trail_mark_list(args.fargs[1], args.fargs[2], tonumber(args.fargs[3]))
end, { nargs = "*", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_LIST_MODES" })

api.nvim_create_user_command("TrailBlazerCloseTrailMarkList", function(args)
  tb.close_trail_mark_list(args.fargs[1])
end, { nargs = "*", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_LIST_MODES" })

api.nvim_create_user_command("TrailBlazerSwitchTrailMarkStack", function(args)
  tb.switch_trail_mark_stack(args.args)
end, { nargs = "?", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_STACKS" })

api.nvim_create_user_command("TrailBlazerAddTrailMarkStack", function(args)
  tb.add_trail_mark_stack(args.args)
end, { nargs = "?", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_STACKS" })

api.nvim_create_user_command("TrailBlazerDeleteTrailMarkStack", function(args)
  tb.delete_trail_mark_stack(args.fargs)
end, { nargs = "*", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_STACKS" })

api.nvim_create_user_command("TrailBlazerDeleteAllTrailMarkStacks", tb.delete_all_trail_mark_stacks,
  {})

api.nvim_create_user_command("TrailBlazerSwitchNextTrailMarkStack", function(args)
  tb.switch_to_next_trail_mark_stack(args.args)
end, { nargs = "?", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_STACK_SORT_MODES" })

api.nvim_create_user_command("TrailBlazerSwitchPreviousTrailMarkStack", function(args)
  tb.switch_to_previous_trail_mark_stack(args.args)
end, { nargs = "?", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_STACK_SORT_MODES" })

api.nvim_create_user_command("TrailBlazerSetTrailMarkStackSortMode", function(args)
  tb.set_trail_mark_stack_sort_mode(vim.tbl_contains(GET_AVAILABLE_TRAIL_MARK_STACK_SORT_MODES(),
    args.args) and args.args or nil)
end, { nargs = "?", complete = "customlist,v:lua.GET_AVAILABLE_TRAIL_MARK_STACK_SORT_MODES" })

api.nvim_create_user_command("TrailBlazerSaveSession", function(args)
  tb.save_trailblazer_state_to_file(args.args, nil, true)
end, { nargs = "?", complete = "file" })

api.nvim_create_user_command("TrailBlazerLoadSession", function(args)
  tb.load_trailblazer_state_from_file(args.args, true)
end, { nargs = "?", complete = "file" })

api.nvim_create_user_command("TrailBlazerDeleteSession", function(args)
  tb.delete_trailblazer_state_file(args.args, true)
end, { nargs = "?", complete = "file" })

-- Auto commands
api.nvim_create_autocmd("VimLeavePre", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = function()
    if tb.options.auto_save_trailblazer_state_on_exit and
        require("trailblazer.trails.config").runtime.should_auto_save then
      tb.save_trailblazer_state_to_file(nil, nil, false)
    end
  end
})

api.nvim_create_autocmd("BufEnter", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = function()
    require('trailblazer.trails.common').reregister_trail_marks(true)
    require('trailblazer.trails.list').update_trail_mark_list()
  end
})

api.nvim_create_autocmd("BufDelete", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = function()
    require('trailblazer.trails.common').reregister_trail_marks()
    require('trailblazer.trails.list').update_trail_mark_list()
  end
})

api.nvim_create_autocmd("BufWritePre", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = require('trailblazer.trails.common').update_all_trail_mark_positions
})

api.nvim_create_autocmd("BufWritePost", {
  group = cfg.auto_groups.trailblazer,
  pattern = "*",
  callback = function()
    require('trailblazer.trails.common').reregister_trail_marks()
    require('trailblazer.trails.list').update_trail_mark_list()
  end
})
