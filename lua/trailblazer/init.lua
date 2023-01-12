---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer
---@brief [[
--- This is the init module of TrailBlazer.
---@brief ]]

-- local api = vim.api
local log = require("trailblazer.log")
local trails = require("trailblazer.trails")
local highlights = require("trailblazer.highlights")
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
    mappings = {
      nv = { -- Mode union: normal & visual mode
        motions = {
          new_trail_mark = '<A-l>',
          track_back = '<A-b>',
          peek_move_backward = '<A-J>',
          peek_move_forward = '<A-K>',
          -- open_trail_mark_list = '<A-m>',
        },
        actions = {
          delete_all_trail_marks = '<A-L>',
          paste_at_last_trail_mark = '<A-p>',
          paste_at_all_trail_marks = '<A-P>',
        },
      },
    },
    hl_groups = {
      TrailBlazerTrailMark = {
        guifg = "Black",
        guibg = "Red",
        gui = "bold",
      },
      TrailBlazerTrailMarkList = {
        guifg = "Black",
        guibg = "LightYellow",
        gui = "bold",
      },
      TrailBlazerTrailMarkListCurrent = {
        guifg = "Black",
        guibg = "LightGray",
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
  TrailBlazer.generated.hl_groups = highlights.register(TrailBlazer.options.hl_groups)
  log.setup(TrailBlazer.options.lang)
  keymaps.register(TrailBlazer.options.mappings)
end

--- Create a new trail mark at the current cursor or defined position and buffer.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
function TrailBlazer.new_trail_mark(win, buf, pos)
  if not TrailBlazer.is_configured() then return end
  trails.new_trail_mark(win, buf, pos)
end

--- Track back to the last trail mark.
---@param buf? number
function TrailBlazer.track_back(buf)
  if not TrailBlazer.is_configured() then return end
  trails.track_back(buf)
end

--- Peek move forward to the next trail mark.
---@param buf? number
function TrailBlazer.peek_move_forward(buf)
  if not TrailBlazer.is_configured() then return end
  trails.peek_move_forward(buf)
end

--- Peek move backward to the last trail mark.
---@param buf? number
function TrailBlazer.peek_move_backward(buf)
  if not TrailBlazer.is_configured() then return end
  trails.peek_move_backward(buf)
end

--- Delete all trail marks from all or a specific buffer.
---@param buf? number
function TrailBlazer.delete_all_trail_marks(buf)
  if not TrailBlazer.is_configured() then return end
  trails.delete_all_trail_marks(buf)
end

--- Paste the selected register contents at the last trail mark of all or a specific buffer.
---@param buf? number
function TrailBlazer.paste_at_last_trail_mark(buf)
  if not TrailBlazer.is_configured() then return end
  trails.paste_at_last_trail_mark(buf)
end

--- Paste the selected register contents at all trail marks of all or a specific buffer.
---@param buf? number
function TrailBlazer.paste_at_all_trail_marks(buf)
  if not TrailBlazer.is_configured() then return end
  trails.paste_at_all_trail_marks(buf)
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
