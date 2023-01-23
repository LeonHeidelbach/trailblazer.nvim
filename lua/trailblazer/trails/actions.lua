---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer.trails.actions
---@brief [[
--- This module is responsible for managing TrailBlazer trail actions.
---@brief ]]

local api = vim.api
local fn = vim.fn
local Actions = {}

local config = require("trailblazer.trails.config")
local common = require("trailblazer.trails.common")
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")

--- Add a new trail mark to the stack.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return table?
function Actions.new_trail_mark(win, buf, pos)
  local trail_mark_index, trail_mark = common.get_trail_mark_under_cursor(win, buf, pos)

  if trail_mark_index and trail_mark then
    api.nvim_buf_del_extmark(trail_mark.buf, config.nsid, trail_mark.mark_id)
    table.remove(common.trail_mark_stack, trail_mark_index)

    local newest_mark_index, oldest_mark_index = common.get_newest_and_oldest_mark_index_for_buf(
      buf)

    if trail_mark_index <= common.trail_mark_cursor and common.trail_mark_cursor
        >= oldest_mark_index and common.trail_mark_cursor <= newest_mark_index then
      common.trail_mark_cursor = common.trail_mark_cursor - 1
    elseif common.trail_mark_cursor - 1 <= oldest_mark_index then
      common.trail_mark_cursor = oldest_mark_index
    end

    common.reregister_trail_marks()
    return nil
  end

  local current_win = win or api.nvim_get_current_win()
  local current_buf = buf or api.nvim_get_current_buf()
  local current_cursor = (not pos or vim.tbl_isempty(pos)) and
      api.nvim_win_get_cursor(current_win) or pos

  if not current_win or not current_buf or not current_cursor or not current_cursor[1]
      or not current_cursor[2] then
    log.error("invalid_pos_for_new_trail_mark")
    return nil
  end

  local pos_text = helpers.get_utf8_char_under_cursor(current_buf, current_cursor)

  if not pos_text then
    log.error("invalid_pos_for_buf_lines")
    return nil
  end

  local new_mark = {
    timestamp = fn.reltimefloat(fn.reltime()),
    win = current_win, buf = current_buf,
    pos = current_cursor, mark_id = config.ucid + 1,
  }

  table.insert(common.trail_mark_stack, new_mark)

  config.ucid = config.ucid + 1
  common.sort_trail_mark_stack()
  common.trail_mark_cursor, _ = common.get_newest_and_oldest_mark_index_for_buf(buf)
  common.reregister_trail_marks()

  return common.trail_mark_stack[common.trail_mark_cursor]
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

    common.trail_mark_cursor, _ = common.get_newest_and_oldest_mark_index_for_buf(buf)
    common.reregister_trail_marks()

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
    for i = #common.trail_mark_stack, 1, -1 do
      if common.trail_mark_stack[i].buf == buf then
        common.paste_at_trail_mark(buf, i)
      end
    end
  else
    for i = #common.trail_mark_stack, 1, -1 do
      common.paste_at_trail_mark(buf, i)
    end
  end
end

--- Delete all trail marks from the stack and all or a specific buffer.
---@param buf? number
function Actions.delete_all_trail_marks(buf)
  if buf == nil then
    for _, mark in ipairs(common.trail_mark_stack) do
      pcall(api.nvim_buf_del_extmark, mark.buf, config.nsid, mark.mark_id)
      common.trail_mark_cursor = common.trail_mark_cursor - 1
    end

    common.trail_mark_cursor = common.trail_mark_cursor > 0 and common.trail_mark_cursor or 0
    common.trail_mark_stack = {}
    config.ucid = 0
  else
    local ext_marks = api.nvim_buf_get_extmarks(buf, config.nsid, 0, -1, {})

    for _, ext_mark in ipairs(ext_marks) do
      pcall(api.nvim_buf_del_extmark, buf, config.nsid, ext_mark[1])
    end

    common.trail_mark_stack = vim.tbl_filter(function(mark)
      return mark.buf ~= buf
    end, common.trail_mark_stack)

    common.trail_mark_cursor = #common.trail_mark_stack
  end
end

--- Set the trail mark selection mode to the given mode or toggle between the available modes.
---@param mode? string
function Actions.set_trail_mark_select_mode(mode)
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
    log.warn("invalid_trail_mark_select_mode",
      table.concat(config.custom.available_trail_mark_modes, ", "))
    return
  end

  common.update_all_trail_mark_positions()
  common.sort_trail_mark_stack()
  common.reregister_trail_marks()

  if config.custom.verbose_trail_mark_select then
    log.info("current_trail_mark_select_mode", config.custom.current_trail_mark_mode)
  end
end

return Actions
