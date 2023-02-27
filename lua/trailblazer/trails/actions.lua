---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.actions
---@mod trailblazer.trails.actions
---@brief [[
--- This module is responsible for managing TrailBlazer trail actions.
---@brief ]]

local api = vim.api
local Actions = {}

local config = require("trailblazer.trails.config")
local common = require("trailblazer.trails.common")
local helpers = require("trailblazer.helpers")
local stacks = require("trailblazer.trails.stacks")
local log = require("trailblazer.log")

--- Add a new trail mark to the stack.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return table?
function Actions.new_trail_mark(win, buf, pos)
  if common.delete_trail_mark_at_pos(win or -1, buf, pos) then return nil end

  local current_win = win or api.nvim_get_current_win()
  local current_buf = buf or api.nvim_get_current_buf()
  local current_cursor = (not pos or vim.tbl_isempty(pos)) and
      api.nvim_win_get_cursor(current_win) or pos

  if not current_win or not current_buf or not current_cursor or not current_cursor[1]
      or not current_cursor[2] then
    log.error("invalid_pos_for_new_trail_mark")
    return nil
  end

  local pos_text = helpers.buf_get_utf8_char_at_pos(current_buf, current_cursor)

  if not pos_text then
    log.error("invalid_pos_for_buf_lines")
    return nil
  end

  local new_mark = {
    timestamp = helpers.time(),
    win = current_win,
    buf = current_buf,
    pos = current_cursor,
    mark_id = stacks.ucid + 1,
  }

  table.insert(stacks.current_trail_mark_stack, new_mark)

  stacks.ucid = stacks.ucid + 1
  common.sort_trail_mark_stack()
  stacks.trail_mark_cursor, _ = common.get_newest_and_oldest_mark_index_for_buf(buf)
  common.reregister_trail_marks(true)

  return stacks.current_trail_mark_stack[stacks.trail_mark_cursor]
end

--- Remove the last global or buffer local trail mark from the stack.
---@param buf? number
---@return boolean
function Actions.track_back(buf)
  buf = common.default_buf_for_current_mark_select_mode(buf)

  local newest_mark_index, _ = common.get_newest_and_oldest_mark_index_for_buf(buf)

  if newest_mark_index then
    local trail_mark, ext_mark
    newest_mark_index, trail_mark, ext_mark = common.get_marks_for_trail_mark_index(buf,
      newest_mark_index, true)
    if newest_mark_index == nil or trail_mark == nil or ext_mark == nil then
      return false
    end

    common.focus_win_and_buf(trail_mark, ext_mark)
    api.nvim_buf_del_extmark(trail_mark.buf, config.nsid, trail_mark.mark_id)

    stacks.trail_mark_cursor, _ = common.get_newest_and_oldest_mark_index_for_buf(buf)
    common.reregister_trail_marks(true)

    return true
  end

  return false
end

--- Paste the selected register contents at the last trail mark of all or a specific buffer.
---@param buf? number
---@return boolean
function Actions.paste_at_last_trail_mark(buf)
  buf = common.default_buf_for_current_mark_select_mode(buf)

  local newest_mark_index, _ = common.get_newest_and_oldest_mark_index_for_buf(buf)

  if newest_mark_index then
    return common.paste_at_trail_mark(buf, newest_mark_index)
  end

  return false
end

--- Paste the selected register contents at all trail marks of all or a specific buffer.
---@param buf? number
function Actions.paste_at_all_trail_marks(buf)
  buf = common.default_buf_for_current_mark_select_mode(buf)

  if buf ~= nil then
    for i = #stacks.current_trail_mark_stack, 1, -1 do
      if stacks.current_trail_mark_stack[i].buf == buf then
        common.paste_at_trail_mark(buf, i)
      end
    end
  else
    for i = #stacks.current_trail_mark_stack, 1, -1 do
      common.paste_at_trail_mark(buf, i)
    end
  end
end

--- Delete all trail marks from the stack and all or a specific buffer.
---@param buf? number
function Actions.delete_all_trail_marks(buf)
  if buf == nil then
    for _, mark in ipairs(stacks.current_trail_mark_stack) do
      pcall(api.nvim_buf_del_extmark, mark.buf, config.nsid, mark.mark_id)
      stacks.trail_mark_cursor = stacks.trail_mark_cursor - 1
    end

    stacks.trail_mark_cursor = stacks.trail_mark_cursor > 0 and stacks.trail_mark_cursor or 0
    stacks.current_trail_mark_stack = {}
    stacks.ucid = 0
  else
    local ext_marks = api.nvim_buf_get_extmarks(buf, config.nsid, 0, -1, {})

    for _, ext_mark in ipairs(ext_marks) do
      pcall(api.nvim_buf_del_extmark, buf, config.nsid, ext_mark[1])
    end

    stacks.current_trail_mark_stack = vim.tbl_filter(function(mark)
      return mark.buf ~= buf
    end, stacks.current_trail_mark_stack)

    stacks.trail_mark_cursor = #stacks.current_trail_mark_stack
  end
end

--- Set the trail mark selection mode to the given mode or toggle between the available modes.
---@param mode? string
---@param verbose? boolean
function Actions.set_trail_mark_select_mode(mode, verbose)
  if mode == nil then
    config.custom.current_trail_mark_mode = config.custom.available_trail_mark_modes[
    (helpers.tbl_indexof(function(available_mode)
      return available_mode == config.custom.current_trail_mark_mode
    end, config.custom.available_trail_mark_modes)) %
    #config.custom.available_trail_mark_modes + 1
    ]
  elseif vim.tbl_contains(config.custom.available_trail_mark_modes, mode) then
    config.custom.current_trail_mark_mode = mode
  else
    if verbose == nil or verbose then
      log.warn("invalid_trail_mark_select_mode",
        table.concat(config.custom.available_trail_mark_modes, ", "))
    end
    return
  end

  common.update_all_trail_mark_positions()
  common.sort_trail_mark_stack()
  common.reregister_trail_marks(true)

  if config.custom.verbose_trail_mark_select and (verbose == nil or verbose) then
    log.info("current_trail_mark_select_mode", config.custom.current_trail_mark_mode)
  end
end

--- Switch to the given trail mark stack.
---@param name? string
function Actions.switch_trail_mark_stack(name)
  stacks.switch_current_stack(name)
  common.reregister_trail_marks()
end

--- Delete the specified trail mark stack or the current one if no name is supplied.
---@param name? string
function Actions.delete_trail_mark_stack(name)
  stacks.delete_stack(name)
  common.reregister_trail_marks()
end

--- Delete all trail mark stacks.
function Actions.delete_all_trail_mark_stacks()
  stacks.delete_all_stacks()
  common.reregister_trail_marks()
end

--- Add the current trail mark stack under the specified name or "default" if no name is supplied.
---@param name? string
function Actions.add_trail_mark_stack(name)
  stacks.add_stack(name)
end

--- Switch to the next trail mark stack using the given sort mode or the current one if no sort mode
--- is supplied.
---@param sort_mode? string
function Actions.switch_to_next_trail_mark_stack(sort_mode)
  stacks.switch_to_next_stack(sort_mode)
  common.reregister_trail_marks()
end

--- Switch to the previous trail mark stack using the given sort mode or the current one if no sort
--- mode is supplied.
---@param sort_mode? string
function Actions.switch_to_previous_trail_mark_stack(sort_mode)
  stacks.switch_to_previous_stack(sort_mode)
  common.reregister_trail_marks()
end

--- Set the trail mark stack sort mode to the given mode or toggle between the available modes.
---@param sort_mode? string
function Actions.set_trail_mark_stack_sort_mode(sort_mode)
  stacks.set_trail_mark_stack_sort_mode(sort_mode)
end

return Actions
