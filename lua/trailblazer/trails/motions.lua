---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.motions
---@mod trailblazer.trails.motions
---@brief [[
--- This module is responsible for managing TrailBlazer trail motions.
---@brief ]]

local api = vim.api

local config = require("trailblazer.trails.config")
local stacks = require("trailblazer.trails.stacks")
local common = require("trailblazer.trails.common")
local Motions = {}

--- Peek move to the previous trail mark if sorted chronologically or up if sorted by line.
---@param buf? number
---@return boolean
function Motions.peek_move_previous_up(buf)
  local current_mark_index, _ = common.get_trail_mark_at_pos()
  buf = common.default_buf_for_current_mark_select_mode(buf)
  if (not current_mark_index or current_mark_index ~= stacks.trail_mark_cursor)
      and config.custom.move_to_nearest_before_peek then
    Motions.move_to_nearest(buf, config.custom.move_to_nearest_before_peek_motion_directive_up,
      config.custom.move_to_nearest_before_peek_dist_type)
  else
    common.set_cursor_to_previous_mark(buf, current_mark_index)
  end
  return common.focus_win_and_buf_by_trail_mark_index(buf, stacks.trail_mark_cursor, false)
end

--- Peek move to the next trail mark if sorted chronologically or down if sorted by line.
---@param buf? number
---@return boolean
function Motions.peek_move_next_down(buf)
  local current_mark_index, _ = common.get_trail_mark_at_pos()
  buf = common.default_buf_for_current_mark_select_mode(buf)
  if (not current_mark_index or current_mark_index ~= stacks.trail_mark_cursor)
      and config.custom.move_to_nearest_before_peek then
    Motions.move_to_nearest(buf, config.custom.move_to_nearest_before_peek_motion_directive_down,
      config.custom.move_to_nearest_before_peek_dist_type)
  else
    common.set_cursor_to_next_mark(buf, current_mark_index)
  end
  return common.focus_win_and_buf_by_trail_mark_index(buf, stacks.trail_mark_cursor, false)
end

--- Move to the nearest trail mark by calculating either the Manhattan Distance or the linear
--- character distance from the current cursor position to each trail mark depending on dist_type.
--- If there is no "nearest trail mark" within the current or specified buffer, nothing happens.
---@param buf? number
---@param directive? string
---@param dist_type? string
---@return boolean
function Motions.move_to_nearest(buf, directive, dist_type)
  buf = buf or api.nvim_get_current_buf()
  local nearest_mark_index, nearest_mark = common.get_nearest_trail_mark_for_pos(buf, nil,
    directive, dist_type)
  if nearest_mark_index and nearest_mark then
    stacks.trail_mark_cursor = nearest_mark_index
    common.reregister_trail_marks(true)
    return common.focus_win_and_buf_by_trail_mark_index(nearest_mark.buf, stacks.trail_mark_cursor,
      false)
  end
  return false
end

return Motions
