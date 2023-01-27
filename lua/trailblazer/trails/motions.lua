---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.motions
---@mod trailblazer.trails.motions
---@brief [[
--- This module is responsible for managing TrailBlazer trail motions.
---@brief ]]

local common = require("trailblazer.trails.common")
local Motions = {}

--- Peek move to the previous trail mark if sorted chronologically or up if sorted by line.
---@param buf? number
---@return boolean
function Motions.peek_move_previous_up(buf)
  local current_mark_index, _ = common.get_trail_mark_under_cursor()
  buf = common.default_buf_for_current_mark_select_mode(buf)
  common.set_cursor_to_previous_mark(buf, current_mark_index)
  return common.focus_win_and_buf_by_trail_mark_index(buf, common.trail_mark_cursor, false)
end

--- Peek move to the next trail mark if sorted chronologically or down if sorted by line.
---@param buf? number
---@return boolean
function Motions.peek_move_next_down(buf)
  local current_mark_index, _ = common.get_trail_mark_under_cursor()
  buf = common.default_buf_for_current_mark_select_mode(buf)
  common.set_cursor_to_next_mark(buf, current_mark_index)
  return common.focus_win_and_buf_by_trail_mark_index(buf, common.trail_mark_cursor, false)
end

return Motions
