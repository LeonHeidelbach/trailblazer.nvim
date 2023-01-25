---@author: Leon Heidelbach 25.01.2023
---@version: 1.0
---@license: MIT
---@tag trails.list
---@mod trailblazer.trails.list
---@brief [[
--- This module is responsible for handling TrailBlazer trail list view.
---@brief ]]

local api = vim.api
local fn = vim.fn
local List = {}

local config = require("trailblazer.trails.config")
local common = require("trailblazer.trails.common")
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")

List.config = {
  qf_title = "TrailBlazer Trail Mark Stack: ",
  qf_buf_name_separator = " - "
}

--- Toggle a list of all trail marks for the specified buffer in the specified list type.
---@param type? string
---@param buf? number
function List.toggle_trail_mark_list(type, buf)
  type = type or config.custom.current_trail_mark_list_type
  buf = common.default_buf_for_current_mark_select_mode(buf)

  if type == "quickfix" then
    List.toggle_quick_fix_list(buf,
      common.get_trail_mark_stack_subset_for_buf(buf))
    return
  end

  log.warn("invalid_trailblazer_list_type",
    table.concat(config.custom.available_trail_mark_lists, ", "))
end

--- Update the specified list type with the trail marks for the specified buffer.
---@param type? string
---@param buf? number
function List.update_trail_mark_list(type, buf)
  type = type or config.custom.current_trail_mark_list_type
  buf = common.default_buf_for_current_mark_select_mode(buf)

  if type == "quickfix" then
    if List.quick_fix_list_is_visible() then
      List.populate_quickfix_list_with_trail_marks(buf,
        common.get_trail_mark_stack_subset_for_buf(buf))
    end
    return
  end

  log.warn("invalid_trailblazer_list_type",
    table.concat(config.custom.available_trail_mark_lists, ", "))
end

--- Toggle a quick fix list with specified trail mark list.
---@param buf? number
---@param trail_mark_list? table
function List.toggle_quick_fix_list(buf, trail_mark_list)

  if List.quick_fix_list_is_visible() then
    vim.cmd("cclose")
    return
  end

  if trail_mark_list then
    List.populate_quickfix_list_with_trail_marks(buf, trail_mark_list)
  end

  vim.cmd("copen")
end

--- Populate the quick fix list with the specified trail mark list.
---@param buf? number
---@param trail_mark_list? table
function List.populate_quickfix_list_with_trail_marks(buf, trail_mark_list)
  if trail_mark_list == nil then
    return
  end

  local quick_fix_list = {}
  local qf_title

  for _, trail_mark in ipairs(trail_mark_list) do
    local quick_fix_list_item = {
      bufnr = trail_mark.buf,
      filename = helpers.buf_get_absolute_file_path(trail_mark.buf),
      lnum = trail_mark.pos[1],
      col = trail_mark.pos[2] + 1,
      text = api.nvim_buf_get_lines(trail_mark.buf, trail_mark.pos[1] - 1, trail_mark.pos[1],
        false)[1],
    }

    table.insert(quick_fix_list, quick_fix_list_item)
  end

  if buf then
    qf_title = List.config.qf_title .. config.custom.current_trail_mark_mode ..
        List.config.qf_buf_name_separator .. helpers.buf_get_relative_file_path(buf)
  else
    qf_title = List.config.qf_title .. config.custom.current_trail_mark_mode
  end

  fn.setqflist({}, "r", {
    title = qf_title,
    items = quick_fix_list,
  })
end

--- Check if a TrailBlazer quick fix list is currently visible.
---@return boolean
function List.quick_fix_list_is_visible()
  for _, win in pairs(fn.getwininfo()) do
    if win["quickfix"] == 1 and win["variables"] and win["variables"]["quickfix_title"] and
        string.match(win["variables"]["quickfix_title"], "^" .. List.config.qf_title) then
      return true
    end
  end

  return false
end

return List
