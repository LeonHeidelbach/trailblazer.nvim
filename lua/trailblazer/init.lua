---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: GPLv3
---@tag init
---@mod trailblazer.init
---@brief [[
--- This is the init module of TrailBlazer. It contains all API functions and is the entry point for
--- the plugin.
---@brief ]]

local log = require("trailblazer.log")
local trails = require("trailblazer.trails")
local highlights = require("trailblazer.highlights")
local helpers = require("trailblazer.helpers")
local keymaps = require("trailblazer.keymaps")

local TrailBlazer = {}
TrailBlazer.options = {}
TrailBlazer.generated = {}

--- Setup function for TrailBlazer.
---@param opts? table
---@return table
local function set_defaults(opts)
  local defaults = {
    lang = "en",
    trail_options = {
      available_trail_mark_modes = { -- available modes to cycle through
        "global_chron",
        "global_buf_line_sorted",
        "global_chron_buf_line_sorted",
        "global_chron_buf_switch_group_chron",
        "global_chron_buf_switch_group_line_sorted",
        "buffer_local_chron",
        "buffer_local_line_sorted"
      },
      current_trail_mark_mode = "global_chron", -- current / initial mode
      current_trail_mark_list_type = "quickfix", -- currently only quickfix lists are supported
      verbose_trail_mark_select = true, -- print current mode notification on mode change
      mark_symbol = "•",
      newest_mark_symbol = "⬤",
      cursor_mark_symbol = "⬤",
      next_mark_symbol = "⬤",
      previous_mark_symbol = "⬤",
      multiple_mark_symbol_counters_enabled = true,
      number_line_color_enabled = true,
      trail_mark_in_text_highlights_enabled = true,
      trail_mark_symbol_line_indicators_enabled = false,
      symbol_line_enabled = true,
      available_trail_mark_stack_sort_modes = {
        "alpha_asc",
        "alpha_dsc",
        "chron_asc",
        "chron_dsc",
      },
      current_trail_mark_stack_sort_mode = "alpha_asc"
    },
    mappings = {
      nv = { -- Mode union: normal & visual mode
        motions = {
          new_trail_mark = '<A-l>',
          track_back = '<A-b>',
          peek_move_next_down = '<A-J>',
          peek_move_previous_up = '<A-K>',
          toggle_trail_mark_list = '<A-m>',
        },
        actions = {
          delete_all_trail_marks = '<A-L>',
          paste_at_last_trail_mark = '<A-p>',
          paste_at_all_trail_marks = '<A-P>',
          set_trail_mark_select_mode = '<A-t>',
          switch_to_next_trail_mark_stack = '<A-.>',
          switch_to_previous_trail_mark_stack = '<A-,>',
          set_trail_mark_stack_sort_mode = '<A-s>',
        },
      },
    },
    hl_groups = {
      TrailBlazerTrailMark = {
        guifg = "White",
        guibg = "none",
        gui = "bold",
      },
      TrailBlazerTrailMarkNext = {
        guifg = "Green",
        guibg = "none",
        gui = "bold",
      },
      TrailBlazerTrailMarkPrevious = {
        guifg = "Red",
        guibg = "none",
        gui = "bold",
      },
      TrailBlazerTrailMarkCursor = {
        guifg = "Black",
        guibg = "Orange",
        gui = "bold",
      },
      TrailBlazerTrailMarkNewest = {
        guifg = "Black",
        guibg = "LightBlue",
        gui = "bold",
      },
      TrailBlazerTrailMarkGlobalChron = {
        guifg = "Black",
        guibg = "Red",
        gui = "bold",
      },
      TrailBlazerTrailMarkGlobalBufLineSorted = {
        guifg = "Black",
        guibg = "LightRed",
        gui = "bold",
      },
      TrailBlazerTrailMarkGlobalChronBufLineSorted = {
        guifg = "Black",
        guibg = "Olive",
        gui = "bold",
      },
      TrailBlazerTrailMarkGlobalChronBufSwitchGroupChron = {
        guifg = "Black",
        guibg = "VioletRed",
        gui = "bold",
      },
      TrailBlazerTrailMarkGlobalChronBufSwitchGroupLineSorted = {
        guifg = "Black",
        guibg = "MediumSpringGreen",
        gui = "bold",
      },
      TrailBlazerTrailMarkBufferLocalChron = {
        guifg = "Black",
        guibg = "Green",
        gui = "bold",
      },
      TrailBlazerTrailMarkBufferLocalLineSorted = {
        guifg = "Black",
        guibg = "LightGreen",
        gui = "bold",
      },
    },
  }

  if opts then
    return vim.tbl_deep_extend("force", defaults, opts)
  end

  return defaults
end

--- Setup TrailBlazer.
---@param options? table
function TrailBlazer.setup(options)
  TrailBlazer.options = set_defaults(options)
  TrailBlazer.generated.hl_groups = highlights.register(TrailBlazer.options.hl_groups, true)
  trails.setup(TrailBlazer.options.trail_options)
  log.setup(TrailBlazer.options.lang)
  keymaps.register_api_maps(TrailBlazer.options.mappings, TrailBlazer)
end

--- Create a new trail mark at the current cursor or defined position and buffer.
---@param win? number
---@param buf? number | string
---@param pos? table<number, number>
function TrailBlazer.new_trail_mark(win, buf, pos)
  if not TrailBlazer.is_configured() then return end
  trails.actions.new_trail_mark(win, helpers.get_buf_nr(buf), pos)
  trails.list.update_trail_mark_list()
end

--- Track back to the last trail mark.
---@param buf? number | string
function TrailBlazer.track_back(buf)
  if not TrailBlazer.is_configured() then return end
  trails.actions.track_back(helpers.get_buf_nr(buf))
  trails.list.update_trail_mark_list()
end

--- Peek move to the previous trail mark if sorted chronologically or up if sorted by line.
---@param buf? number | string
function TrailBlazer.peek_move_previous_up(buf)
  if not TrailBlazer.is_configured() then return end
  trails.motions.peek_move_previous_up(helpers.get_buf_nr(buf))
  trails.list.update_trail_mark_list()
end

--- Peek move to the next trail mark if sorted chronologically or down if sorted by line.
---@param buf? number | string
function TrailBlazer.peek_move_next_down(buf)
  if not TrailBlazer.is_configured() then return end
  trails.motions.peek_move_next_down(helpers.get_buf_nr(buf))
  trails.list.update_trail_mark_list()
end

--- Delete all trail marks from all or a specific buffer.
---@param buf? number | string
function TrailBlazer.delete_all_trail_marks(buf)
  if not TrailBlazer.is_configured() then return end
  trails.actions.delete_all_trail_marks(helpers.get_buf_nr(buf))
  trails.list.update_trail_mark_list()
end

--- Paste the selected register contents at the last trail mark of all or a specific buffer.
---@param buf? number | string
function TrailBlazer.paste_at_last_trail_mark(buf)
  if not TrailBlazer.is_configured() then return end
  trails.actions.paste_at_last_trail_mark(helpers.get_buf_nr(buf))
  trails.list.update_trail_mark_list()
end

--- Paste the selected register contents at all trail marks of all or a specific buffer.
---@param buf? number | string
function TrailBlazer.paste_at_all_trail_marks(buf)
  if not TrailBlazer.is_configured() then return end
  trails.actions.paste_at_all_trail_marks(helpers.get_buf_nr(buf))
  trails.list.update_trail_mark_list()
end

--- Set the trail mark selection mode to the given mode or toggle between the available modes.
---@param mode? string
function TrailBlazer.set_trail_mark_select_mode(mode)
  if not TrailBlazer.is_configured() then return end
  trails.actions.set_trail_mark_select_mode(mode)
  trails.list.update_trail_mark_list()
end

--- Toggle a list of all trail marks for the specified buffer in the specified list type.
---@param type string
---@param buf? number | string
function TrailBlazer.toggle_trail_mark_list(type, buf)
  if not TrailBlazer.is_configured() then return end
  trails.list.toggle_trail_mark_list(type, helpers.get_buf_nr(buf))
end

--- Switch the trail mark stack to the specified stack.
---@param name? string
function TrailBlazer.switch_trail_mark_stack(name)
  if not TrailBlazer.is_configured() then return end
  trails.actions.switch_trail_mark_stack(name)
  trails.list.update_trail_mark_list()
end

--- Delete the specified trail mark stack or the current one if no name is supplied.
---@param name? string
function TrailBlazer.delete_trail_mark_stack(name)
  if not TrailBlazer.is_configured() then return end
  trails.actions.delete_trail_mark_stack(name)
  trails.list.update_trail_mark_list()
end

--- Delete all trail mark stacks.
function TrailBlazer.delte_all_trail_mark_stacks()
  if not TrailBlazer.is_configured() then return end
  trails.actions.delete_all_trail_mark_stacks()
  trails.list.update_trail_mark_list()
end

--- Add the current trail mark stack under the specified name or "default" if no name is supplied.
---@param name? string
function TrailBlazer.add_trail_mark_stack(name)
  if not TrailBlazer.is_configured() then return end
  trails.actions.add_trail_mark_stack(name)
  trails.list.update_trail_mark_list()
end

--- Switch to the next trail mark stack using the given sort mode or the current one if no sort mode
--- is supplied.
---@param sort_mode? string
function TrailBlazer.switch_to_next_trail_mark_stack(sort_mode)
  if not TrailBlazer.is_configured() then return end
  trails.actions.switch_to_next_trail_mark_stack(sort_mode)
  trails.list.update_trail_mark_list()
end

--- Switch to the previous trail mark stack using the given sort mode or the current one if no sort
--- mode is supplied.
---@param sort_mode? string
function TrailBlazer.switch_to_previous_trail_mark_stack(sort_mode)
  if not TrailBlazer.is_configured() then return end
  trails.actions.switch_to_previous_trail_mark_stack(sort_mode)
  trails.list.update_trail_mark_list()
end

--- Set the trail mark stack sort mode to the given mode or toggle between the available modes.
---@param sort_mode? string
function TrailBlazer.set_trail_mark_stack_sort_mode(sort_mode)
  if not TrailBlazer.is_configured() then return end
  trails.actions.set_trail_mark_stack_sort_mode(sort_mode)
end

--- Check if TrailBlazer is configured.
---@return boolean
function TrailBlazer.is_configured()
  if TrailBlazer.options == nil then
    log.error("not_configured")
    return false
  end
  return true
end

return TrailBlazer
