---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: MIT
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
      verbose_trail_mark_select = true, -- print current mode notification on mode change
      next_mark_symbol = "⬤",
      previous_mark_symbol = "⬤",
      number_line_color_enabled = true,
      symbol_line_enabled = true,
    },
    mappings = {
      nv = { -- Mode union: normal & visual mode
        motions = {
          new_trail_mark = '<A-l>',
          track_back = '<A-b>',
          peek_move_previous_down = '<A-J>',
          peek_move_next_up = '<A-K>',
          -- open_trail_mark_list = '<A-m>',
        },
        actions = {
          delete_all_trail_marks = '<A-L>',
          paste_at_last_trail_mark = '<A-p>',
          paste_at_all_trail_marks = '<A-P>',
          set_trail_mark_select_mode = '<A-t>',
        },
      },
    },
    hl_groups = {
      TrailBlazerTrailMarkNext = {
        guifg = "Red",
        guibg = "none",
        gui = "bold",
      },
      TrailBlazerTrailMarkPrevious = {
        guifg = "Green",
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
  keymaps.register(TrailBlazer.options.mappings, TrailBlazer)
end

--- Create a new trail mark at the current cursor or defined position and buffer.
---@param win? number
---@param buf? number | string
---@param pos? table<number, number>
function TrailBlazer.new_trail_mark(win, buf, pos)
  if not TrailBlazer.is_configured() then return end
  trails.new_trail_mark(win, helpers.get_buf_nr(buf), pos)
end

--- Track back to the last trail mark.
---@param buf? number | string
function TrailBlazer.track_back(buf)
  if not TrailBlazer.is_configured() then return end
  trails.track_back(helpers.get_buf_nr(buf))
end

--- Peek move to the next trail mark if sorted chronologically or up if sorted by line.
---@param buf? number | string
function TrailBlazer.peek_move_next_up(buf)
  if not TrailBlazer.is_configured() then return end
  trails.peek_move_next_up(helpers.get_buf_nr(buf))
end

--- Peek move to the previous trail mark if sorted chronologically or down if sorted by line.
---@param buf? number | string
function TrailBlazer.peek_move_previous_down(buf)
  if not TrailBlazer.is_configured() then return end
  trails.peek_move_previous_down(helpers.get_buf_nr(buf))
end

--- Delete all trail marks from all or a specific buffer.
---@param buf? number | string
function TrailBlazer.delete_all_trail_marks(buf)
  if not TrailBlazer.is_configured() then return end
  trails.delete_all_trail_marks(helpers.get_buf_nr(buf))
end

--- Paste the selected register contents at the last trail mark of all or a specific buffer.
---@param buf? number | string
function TrailBlazer.paste_at_last_trail_mark(buf)
  if not TrailBlazer.is_configured() then return end
  trails.paste_at_last_trail_mark(helpers.get_buf_nr(buf))
end

--- Paste the selected register contents at all trail marks of all or a specific buffer.
---@param buf? number | string
function TrailBlazer.paste_at_all_trail_marks(buf)
  if not TrailBlazer.is_configured() then return end
  trails.paste_at_all_trail_marks(helpers.get_buf_nr(buf))
end

--- Set the trail mark selection mode to the given mode or toggle between the available modes.
---@param mode any
function TrailBlazer.set_trail_mark_select_mode(mode)
  if not TrailBlazer.is_configured() then return end
  trails.set_trail_mark_select_mode(mode)
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

-- TODO: Trail mark preview on top and bottom of buffer with marks that are out of view (Preview the next x jumps)
