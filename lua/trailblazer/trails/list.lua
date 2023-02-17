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
local actions = require("trailblazer.trails.actions")
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
        qf_motion_move_trail_mark_stack_cursor = "<CR>",
      },
      actions = {
        qf_action_delete_trail_mark_selection = "d",
        qf_action_save_visual_selection_start_line = "v",
      },
      alt_actions = {
        qf_action_save_visual_selection_start_line = "V",
      }
    },
    v = {
      actions = {
        qf_action_move_selected_trail_marks_down = "<C-j>",
        qf_action_move_selected_trail_marks_up = "<C-k>",
      }
    }
  }
}

--- Setup the list module.
---@param options? table
function List.setup(options)
  if options.force_quickfix_mappings then
    List.config.quickfix_mappings = options.force_quickfix_mappings
  elseif options.quickfix_mappings then
    helpers.tbl_deep_extend(List.config.quickfix_mappings, options.quickfix_mappings)
  end
end

--- Toggle a list of all trail marks for the specified buffer in the specified list type.
---@param type? string
---@param buf? number
function List.toggle_trail_mark_list(type, buf)
  type = type or config.custom.current_trail_mark_list_type
  buf = common.default_buf_for_current_mark_select_mode(buf)

  if type == "quickfix" then
    List.toggle_quick_fix_list(buf, common.get_trail_mark_stack_subset_for_buf(buf))
    return
  end

  log.warn("invalid_trailblazer_list_type",
    table.concat(config.custom.available_trail_mark_lists, ", "))
end

--- Open a list of all trail marks for the specified buffer in the specified list type.
---@param type? string
---@param buf? number
function List.open_trail_mark_list(type, buf)
  type = type or config.custom.current_trail_mark_list_type
  buf = common.default_buf_for_current_mark_select_mode(buf)

  if type == "quickfix" then
    List.open_quick_fix_list(buf, common.get_trail_mark_stack_subset_for_buf(buf))
    return
  end

  log.warn("invalid_trailblazer_list_type",
    table.concat(config.custom.available_trail_mark_lists, ", "))
end

--- Close a list of all trail marks for the specified buffer in the specified list type.
---@param type? string
function List.close_trail_mark_list(type)
  type = type or config.custom.current_trail_mark_list_type

  if type == "quickfix" then
    List.close_quick_fix_list()
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
    if List.get_trailblazer_quickfix_buf() then
      List.populate_quickfix_list_with_trail_marks(buf,
        common.get_trail_mark_stack_subset_for_buf(buf))
    end
    return
  end

  log.warn("invalid_trailblazer_list_type",
    table.concat(config.custom.available_trail_mark_lists, ", "))
end

--- Toggle a quick fix list with the specified trail mark list.
---@param buf? number
---@param trail_mark_list? table
function List.toggle_quick_fix_list(buf, trail_mark_list)
  if List.close_quick_fix_list() then return end
  List.open_quick_fix_list(buf, trail_mark_list)
end

--- Open a quick fix list with the specified trail mark list.
---@param buf? number
---@param trail_mark_list? table
---@return number?
function List.open_quick_fix_list(buf, trail_mark_list)
  if trail_mark_list then
    List.populate_quickfix_list_with_trail_marks(buf, trail_mark_list)
  end

  vim.cmd("copen")
  List.register_quickfix_keybindings(List.config.quickfix_mappings)

  return List.get_trailblazer_quickfix_buf()
end

--- Close a trail mark quick fix list.
---@return boolean
function List.close_quick_fix_list()
  local qf_buf = List.get_trailblazer_quickfix_buf()
  if qf_buf then
    pcall(api.nvim_command, "bdelete! " .. qf_buf)
    return true
  end

  return false
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

  local _, rel_cursor = common.get_relative_marks_and_cursor(buf, stacks.trail_mark_cursor)

  fn.setqflist({}, "r", {
    title = qf_title,
    idx = rel_cursor,
    items = quick_fix_list,
  })
end

--- Register quickfix list keybindings.
---@param mapping_table table
function List.register_quickfix_keybindings(mapping_table)
  local qf_buf = List.get_trailblazer_quickfix_buf()
  keymaps.register_for_buf(mapping_table, "trailblazer.trails.list", List, qf_buf)
end

--- Move the trail mark stack cursor on selecting a trail mark from the quickfix list.
function List.qf_motion_move_trail_mark_stack_cursor()
  if List.restore_default_quickfix_keybindings_if_needed(function()
        api.nvim_feedkeys(api.nvim_replace_termcodes(
          List.config.quickfix_mappings.nv.motions.qf_motion_move_trail_mark_stack_cursor, true,
          true, true), "n", true)
      end) then
    return
  end

  local qf = fn.getqflist({ id = 0, items = 1 })

  if qf and qf.items and #qf.items > 0 then
    local current_idx = api.nvim_win_get_cursor(0)[1]
    local item = qf.items[current_idx]
    local buf = item.bufnr
    local mark = common.get_first_trail_mark_index(nil, buf, { item.lnum, item.col - 1 })

    if fn.mode() == 'V' then api.nvim_command('normal! V') end

    if mark and not common.focus_win_and_buf_by_trail_mark_index(buf, mark, false) then
      helpers.open_file(api.nvim_buf_get_name(item.bufnr), api.nvim_get_current_win())
      common.focus_win_and_buf_by_trail_mark_index(buf, mark, false)
      common.reregister_trail_marks()
    end

    List.update_trail_mark_list()
  end
end

--- Delete the selected trail marks from the trail mark stack.
function List.qf_action_delete_trail_mark_selection()
  if List.restore_default_quickfix_keybindings_if_needed() then return end

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
      common.delete_trail_mark_at_pos( -1, buf, { item.lnum, item.col - 1 })
    end

    List.update_trail_mark_list()
  end
end

--- Save the visual selection start line number for the quickfix list.
function List.qf_action_save_visual_selection_start_line()
  if List.restore_default_quickfix_keybindings_if_needed() then return end
  List.config.visual_selection_start_line = api.nvim_win_get_cursor(0)[1]
  api.nvim_command("normal! V")
end

--- Move the selected trail marks up in the current stack order. This automatically switches to
--- the `custom_ord` trail mark sort mode if it was not already selected and overrides the previous
--- custom order.
function List.qf_action_move_selected_trail_marks_up()
  if List.restore_default_quickfix_keybindings_if_needed() then return end

  local qf = fn.getqflist({ id = 0, items = 1 })

  if qf and qf.items and #qf.items > 0 then
    local current_cursor = api.nvim_win_get_cursor(0)
    local current_idx = current_cursor[1]
    local start_idx, end_idx = current_idx, current_idx

    if fn.mode() == 'V' and current_idx ~= List.config.visual_selection_start_line then
      start_idx = math.min(List.config.visual_selection_start_line, current_idx)
      end_idx = math.max(List.config.visual_selection_start_line, current_idx)
    end

    for i, trail_mark in ipairs(stacks.current_trail_mark_stack) do
      if i >= start_idx and i <= end_idx then
        trail_mark.custom_ord = i - 1
      elseif i == start_idx - 1 then
        trail_mark.custom_ord = end_idx
      else
        trail_mark.custom_ord = i
      end
    end

    if not vim.tbl_contains(config.custom.available_trail_mark_modes, "custom_ord") then
      table.insert(config.custom.available_trail_mark_modes, 1, "custom_ord")
    end

    if config.custom.current_trail_mark_mode ~= "custom_ord" then
      actions.set_trail_mark_select_mode("custom_ord")
    end

    common.sort_trail_mark_stack("custom_ord")

    if stacks.trail_mark_cursor >= start_idx and stacks.trail_mark_cursor <= end_idx then
      stacks.trail_mark_cursor = math.max(stacks.trail_mark_cursor - 1, 1)
    elseif stacks.trail_mark_cursor == start_idx - 1 then
      stacks.trail_mark_cursor = end_idx
    end

    List.update_trail_mark_list()

    local selection_start = helpers.signum(current_idx - start_idx) == 1 and start_idx or end_idx
    helpers.set_visual_line_selection(
      { math.max(selection_start - 1, 1), current_cursor[2] },
      { math.max(current_idx - 1, 1), current_cursor[2] })

    List.config.visual_selection_start_line = math.max(selection_start - 1, 1)
  end
end

--- Move the selected trail marks down in the current stack order. This automatically switches to
--- the `custom_ord` trail mark sort mode if it was not already selected and overrides the previous
--- custom order.
function List.qf_action_move_selected_trail_marks_down()
  if List.restore_default_quickfix_keybindings_if_needed() then return end

  local qf = fn.getqflist({ id = 0, items = 1 })

  if qf and qf.items and #qf.items > 0 then
    local current_cursor = api.nvim_win_get_cursor(0)
    local current_idx = current_cursor[1]
    local start_idx, end_idx = current_idx, current_idx

    if fn.mode() == 'V' and current_idx ~= List.config.visual_selection_start_line then
      start_idx = math.min(List.config.visual_selection_start_line, current_idx)
      end_idx = math.max(List.config.visual_selection_start_line, current_idx)
    end

    for i, trail_mark in ipairs(stacks.current_trail_mark_stack) do
      if i >= start_idx and i <= end_idx then
        trail_mark.custom_ord = i + 1
      elseif i == end_idx + 1 then
        trail_mark.custom_ord = start_idx
      else
        trail_mark.custom_ord = i
      end
    end

    if not vim.tbl_contains(config.custom.available_trail_mark_modes, "custom_ord") then
      table.insert(config.custom.available_trail_mark_modes, 1, "custom_ord")
    end

    if config.custom.current_trail_mark_mode ~= "custom_ord" then
      actions.set_trail_mark_select_mode("custom_ord")
    end

    common.sort_trail_mark_stack("custom_ord")

    if stacks.trail_mark_cursor >= start_idx and stacks.trail_mark_cursor <= end_idx then
      stacks.trail_mark_cursor = math.min(stacks.trail_mark_cursor + 1, #stacks.current_trail_mark_stack)
    elseif stacks.trail_mark_cursor == end_idx + 1 then
      stacks.trail_mark_cursor = start_idx
    end

    List.update_trail_mark_list()

    local selection_start = helpers.signum(current_idx - start_idx) == 1 and start_idx or end_idx
    helpers.set_visual_line_selection(
      { math.min(selection_start + 1, #qf.items), current_cursor[2] },
      { math.min(current_idx + 1, #qf.items), current_cursor[2] })

    List.config.visual_selection_start_line = math.min(selection_start + 1, #qf.items)
  end
end

--- Restore the default quickfix list behavior if the current quickfix list is not a TrailBlazer
--- quickfix list.
---@param callback? function
---@return boolean
function List.restore_default_quickfix_keybindings_if_needed(callback)
  if List.get_trailblazer_quickfix_buf() == nil then
    keymaps.unregister_for_buf(List.config.quickfix_mappings, "trailblazer.trails.list", List,
      List.get_trailblazer_quickfix_buf(true))

    if callback then callback() end

    return true
  end
  return false
end

--- Check if a TrailBlazer quick fix list is currently visible and return its buffer number.
---@param any_qf? boolean
---@return number?
function List.get_trailblazer_quickfix_buf(any_qf)
  for _, win in pairs(fn.getwininfo()) do
    if win["quickfix"] == 1 and (any_qf or win["variables"] and win["variables"]["quickfix_title"]
        and string.match(win["variables"]["quickfix_title"], "^" .. List.config.qf_title)) then
      return win["bufnr"]
    end
  end

  return nil
end

return List
