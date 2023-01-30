---@author: Leon Heidelbach 25.01.2023
---@version: 1.0
---@license: GPLv3
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
local stacks = require("trailblazer.trails.stacks")
local helpers = require("trailblazer.helpers")
local keymaps = require("trailblazer.keymaps")
local log = require("trailblazer.log")

List.config = {
  qf_title = "TrailBlazer Trail Mark Stack: ",
  qf_stack_name_separator = " ~ ",
  qf_buf_name_separator = " - ",
  quickfix_mappings = {
    nv = {
      motions = {
        qf_action_move_trail_mark_stack_cursor = "<CR>",
      },
      actions = {
        qf_action_delete_trail_mark_selection = "d",
        qf_action_save_visual_selection_start_line = "v",
      },
      alt_action_maps = {
        qf_action_save_visual_selection_start_line = "V",
      }
    }
  }
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
    if List.get_quickfix_buf() then
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

  if List.get_quickfix_buf() then
    vim.cmd("cclose")
    return
  end

  if trail_mark_list then
    List.populate_quickfix_list_with_trail_marks(buf, trail_mark_list)
  end

  vim.cmd("copen")
  List.register_quickfix_keybindings(List.config.quickfix_mappings)
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
    qf_title = List.config.qf_title .. stacks.current_trail_mark_stack_name ..
        List.config.qf_stack_name_separator .. config.custom.current_trail_mark_mode
        .. List.config.qf_buf_name_separator .. helpers.buf_get_relative_file_path(buf)
  else
    qf_title = List.config.qf_title .. stacks.current_trail_mark_stack_name ..
        List.config.qf_stack_name_separator .. config.custom.current_trail_mark_mode
  end

  local _, rel_cursor = common.get_relative_marks_and_cursor(buf, common.trail_mark_cursor)

  fn.setqflist({}, "r", {
    title = qf_title,
    idx = rel_cursor,
    items = quick_fix_list,
  })
end

--- Register quickfix list keybindings.
---@param mapping_table table
function List.register_quickfix_keybindings(mapping_table)
  local qf_buf = List.get_quickfix_buf()
  keymaps.register_for_buf(mapping_table, "trailblazer.trails.list", List, qf_buf)
end

--- Move the trail mark stack cursor on selecting a trail mark from the quickfix list.
function List.qf_action_move_trail_mark_stack_cursor()
  local qf = fn.getqflist({ id = 0, items = 1 })

  if qf and qf.items and #qf.items > 0 then
    local current_idx = api.nvim_win_get_cursor(0)[1]
    local item = qf.items[current_idx]
    local buf = item.bufnr
    local mark = common.get_first_trail_mark_index(nil, buf, { item.lnum, item.col - 1 })

    if fn.mode() == 'V' then api.nvim_command('normal! V') end

    common.focus_win_and_buf_by_trail_mark_index(buf, mark, false)
    List.update_trail_mark_list()
  end
end

--- Delete the selected trail marks from the trail mark stack.
function List.qf_action_delete_trail_mark_selection()
  local qf = fn.getqflist({ id = 0, items = 1 })

  if qf and qf.items and #qf.items > 0 then
    local current_idx = api.nvim_win_get_cursor(0)[1]
    local start_idx, end_idx = current_idx, current_idx

    if fn.mode() == 'V' and current_idx ~= List.config.visual_selection_start_line then
      start_idx = math.min(List.config.visual_selection_start_line, current_idx)
      end_idx = math.max(List.config.visual_selection_start_line, current_idx)
      api.nvim_command("normal! V")
    end

    for i = start_idx, end_idx do
      local item = qf.items[i]
      local buf = item.bufnr
      common.delete_trail_mark_at_pos(-1, buf, { item.lnum, item.col - 1 })
    end

    List.update_trail_mark_list()
  end
end

--- Save the visual selection start line number for the quickfix list.
function List.qf_action_save_visual_selection_start_line()
  List.config.visual_selection_start_line = api.nvim_win_get_cursor(0)[1]
  api.nvim_command("normal! V")
end

--- Check if a TrailBlazer quick fix list is currently visible and return its buffer number.
---@return number?
function List.get_quickfix_buf()
  for _, win in pairs(fn.getwininfo()) do
    if win["quickfix"] == 1 and win["variables"] and win["variables"]["quickfix_title"] and
        string.match(win["variables"]["quickfix_title"], "^" .. List.config.qf_title) then
      return win["bufnr"]
    end
  end

  return nil
end

return List
