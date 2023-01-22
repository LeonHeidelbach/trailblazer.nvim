---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer.trails.common
---@brief [[
--- This module is responsible for managing trails common functionality and runtime state.
---@brief ]]

local api = vim.api
local fn = vim.fn
local Common = {}

local config = require("trailblazer.trails.config")
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")

Common.trail_mark_cursor = 0
Common.trail_mark_stack = {}

--- Paste the selected register contents at a specifi trail mark.
---@param buf? number
---@param trail_mark_index? number
---@return boolean
function Common.paste_at_trail_mark(buf, trail_mark_index)
  local trail_mark, ext_mark
  trail_mark_index, trail_mark, ext_mark = Common.get_marks_for_trail_mark_index(buf,
    trail_mark_index, true)
  if trail_mark_index == nil or trail_mark == nil or ext_mark == nil then
    return false
  end

  local ok = Common.focus_win_and_buf(trail_mark, ext_mark)
  if not ok then
    return false
  end

  api.nvim_paste(fn.getreg(api.nvim_get_vvar("register")), false, -1)
  api.nvim_buf_del_extmark(trail_mark.buf, config.nsid, trail_mark.mark_id)

  Common.trail_mark_cursor = #Common.trail_mark_stack
  Common.reregister_trail_marks()

  return true
end

--- Set the cursor to the previous trail mark.
---@param buf? number
---@param current_mark_index? number
function Common.set_cursor_to_previous_mark(buf, current_mark_index)
  local marks, cursor = Common.get_relative_marks_and_cursor(buf, current_mark_index)

  if current_mark_index and current_mark_index == Common.trail_mark_cursor then
    cursor = cursor > 1 and cursor - 1 or #marks > 0 and 1 or 0
  end

  Common.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
end

--- Set the cursor to the next trail mark.
---@param buf? number
---@param current_mark_index? number
function Common.set_cursor_to_next_mark(buf, current_mark_index)
  local marks, cursor = Common.get_relative_marks_and_cursor(buf, current_mark_index)

  if current_mark_index and current_mark_index == Common.trail_mark_cursor then
    cursor = cursor + 1 <= #marks and cursor + 1 or #marks
  end

  Common.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
end

--- Sort the trail mark stack according to the current or provided trail mark mode.
---@param mode? string
function Common.sort_trail_mark_stack(mode)
  if mode == nil then
    mode = config.custom.current_trail_mark_mode
  end

  if mode == "global_chron" then
    table.sort(Common.trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)
  elseif mode == "global_buf_line_sorted" then
    table.sort(Common.trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        if a.pos[1] == b.pos[1] then
          return a.pos[2] < b.pos[2]
        else
          return a.pos[1] < b.pos[1]
        end
      else
        return a.buf < b.buf
      end
    end)
  elseif mode == "global_chron_buf_line_sorted" then
    table.sort(Common.trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)

    table.sort(Common.trail_mark_stack, function(a, b)
      return a.buf < b.buf
    end)

    table.sort(Common.trail_mark_stack, function(a, b)
      return a.pos[1] < b.pos[1] or (a.pos[1] == b.pos[1] and a.pos[2] < b.pos[2])
    end)
  elseif mode == "global_chron_buf_switch_group_chron" or
      mode == "global_chron_buf_switch_group_line_sorted" then
    local new_trail_mark_stack = {}
    local ordered_trail_mark_subsets = {}
    local current_subset = {}
    local current_buf = -1

    local function sort_current_subset_and_insert()
      table.sort(current_subset, function(a, b)
        return a.pos[1] < b.pos[1] or (a.pos[1] == b.pos[1] and a.pos[2] < b.pos[2])
      end)
      if mode == "global_chron_buf_switch_group_chron" then
        table.insert(ordered_trail_mark_subsets, 1, current_subset)
      elseif mode == "global_chron_buf_switch_group_line_sorted" then
        table.insert(ordered_trail_mark_subsets, current_subset)
      end
      current_subset = {}
    end

    table.sort(Common.trail_mark_stack, function(a, b)
      return a.timestamp > b.timestamp
    end)

    for _, mark in ipairs(Common.trail_mark_stack) do
      if current_buf ~= mark.buf then
        if current_buf > -1 then
          sort_current_subset_and_insert()
        end
        current_buf = mark.buf
      end
      table.insert(current_subset, mark)
    end

    if #current_subset > 0 then
      sort_current_subset_and_insert()
    end

    if mode == "global_chron_buf_switch_group_line_sorted" then
      table.sort(ordered_trail_mark_subsets, function(a, b)
        if a[1].buf == b[1].buf then
          return a[1].pos[1] < b[1].pos[1] or (a[1].pos[1] == b[1].pos[1]
              and a[1].pos[2] < b[1].pos[2])
        end
        return false
      end)
    end

    for _, subset in ipairs(ordered_trail_mark_subsets) do
      helpers.tbl_append(new_trail_mark_stack, subset)
    end

    Common.trail_mark_stack = new_trail_mark_stack
  elseif mode == "buffer_local_chron" then
    table.sort(Common.trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        return a.timestamp < b.timestamp
      else
        return a.buf < b.buf
      end
    end)
  elseif mode == "buffer_local_line_sorted" then
    table.sort(Common.trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        return a.pos[1] < b.pos[1] or (a.pos[1] == b.pos[1] and a.pos[2] < b.pos[2])
      else
        return a.buf < b.buf
      end
    end)
  end
end

--- Focus a specific window and buffer and set the cursor to the position of the trail mark.
---@param trail_mark table
---@param ext_mark table
---@return boolean
function Common.focus_win_and_buf(trail_mark, ext_mark)
  local ok
  ok, _ = pcall(api.nvim_set_current_win, trail_mark.win)
  if not ok then
    api.nvim_set_current_win(0)
  end

  ok, _ = pcall(api.nvim_set_current_buf, trail_mark.buf)
  if ok then
    ok, _ = pcall(api.nvim_win_set_cursor, 0, { ext_mark[1][2] + 1, ext_mark[1][3] })
    if ok then
      return true
    end
  end

  return false
end

--- Focus a specific window and buffer and set the cursor to the position of the trail mark by
--- providing its index.
---@param buf? number
---@param trail_mark_index? number
---@param remove_trail_mark boolean
---@return boolean
function Common.focus_win_and_buf_by_trail_mark_index(buf, trail_mark_index, remove_trail_mark)
  if trail_mark_index > 0 then
    local trail_mark, ext_mark
    trail_mark_index, trail_mark, ext_mark = Common.get_marks_for_trail_mark_index(buf,
      trail_mark_index, remove_trail_mark)
    if trail_mark_index == nil or trail_mark == nil or ext_mark == nil or
        buf and trail_mark.buf ~= buf then
      return false
    end

    return Common.focus_win_and_buf(trail_mark, ext_mark)
  end

  return false
end

--- Return the trail mark and its index in the trail mark stack under the current cursor location.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return number?
---@return table?
function Common.get_trail_mark_under_cursor(win, buf, pos)
  local trail_mark_index
  local current_win = win or api.nvim_get_current_win()
  local current_buffer = buf or api.nvim_get_current_buf()
  local current_cursor = pos or api.nvim_win_get_cursor(0)
  local ext_marks = api.nvim_buf_get_extmarks(current_buffer, config.nsid, 0, -1, {})

  local current_ext_mark = helpers.tbl_find(function(ext_mark)
    return ext_mark[2] + 1 == current_cursor[1] and ext_mark[3] == current_cursor[2]
  end, ext_marks)

  Common.update_all_trail_mark_positions()
  Common.remove_duplicate_pos_trail_marks()

  if current_ext_mark ~= nil then
    trail_mark_index = helpers.tbl_indexof(function(trail_mark)
      return current_win == trail_mark.win and current_buffer == trail_mark.buf and
          trail_mark.mark_id == current_ext_mark[1]
    end, Common.trail_mark_stack)
  end

  if trail_mark_index ~= nil then
    if Common.trail_mark_cursor > #Common.trail_mark_stack then
      Common.trail_mark_cursor = trail_mark_index
    end

    Common.reregister_trail_marks()
    return trail_mark_index, Common.trail_mark_stack[trail_mark_index]
  end

  Common.reregister_trail_marks()

  return nil, nil
end

--- Return the trail mark at the given position as well as the corresponding extmark.
---@param buf? number
---@param newest_mark_index? number
---@return number?
---@return table?
---@return table?
function Common.get_marks_for_trail_mark_index(buf, newest_mark_index, remove_trail_mark)
  local ok, extracted_ext_mark, last_mark

  while #Common.trail_mark_stack > 0 do
    if newest_mark_index then
      last_mark = Common.trail_mark_stack[newest_mark_index]

      if last_mark then
        ok, extracted_ext_mark, _ = pcall(api.nvim_buf_get_extmarks, last_mark.buf,
          config.nsid, last_mark.mark_id, last_mark.mark_id, {})
      end

      if remove_trail_mark then
        table.remove(Common.trail_mark_stack, newest_mark_index)
      end

      if ok then break end
    else
      return nil, nil, nil
    end
    newest_mark_index, _ = Common.get_newest_and_oldest_mark_index_for_buf(buf)
  end

  return newest_mark_index, last_mark, extracted_ext_mark
end

--- Find the newest and oldest trail mark in the stack that belongs to the given buffer.
---@param buf? number
---@return number?
---@return number?
function Common.get_newest_and_oldest_mark_index_for_buf(buf)
  local max_time = 0
  local min_time = math.huge
  local newest_mark_index = nil
  local oldest_mark_index = nil

  for i, trail_mark in ipairs(Common.trail_mark_stack) do
    if (not buf or trail_mark.buf == buf) then
      if trail_mark.timestamp > max_time then
        max_time = trail_mark.timestamp
        newest_mark_index = i
      end

      if trail_mark.timestamp < min_time then
        min_time = trail_mark.timestamp
        oldest_mark_index = i
      end
    end
  end

  return newest_mark_index or #Common.trail_mark_stack, oldest_mark_index or 0
end

--- Get a mark selection depending on the current mark selection mode and the corresponding
--- relative current cursor position within it.
---@param buf? number
---@param current_mark_index? number
---@return table
---@return number
function Common.get_relative_marks_and_cursor(buf, current_mark_index)
  local marks, cursor

  if buf then
    marks = vim.tbl_filter(function(mark)
      return mark.buf == buf
    end, Common.trail_mark_stack)
    cursor = helpers.tbl_indexof(function(mark)
      return mark.buf == buf and Common.trail_mark_stack[current_mark_index] and
          Common.trail_mark_stack[current_mark_index].mark_id == mark.mark_id
    end, marks) or helpers.tbl_indexof(function(mark)
      return mark.buf == buf and Common.trail_mark_stack[Common.trail_mark_cursor] and
          mark.timestamp == Common.trail_mark_stack[Common.trail_mark_cursor].timestamp
    end, marks) or #marks
  else
    marks = Common.trail_mark_stack
    cursor = Common.trail_mark_cursor or #Common.trail_mark_stack
  end

  return marks, cursor
end

--- Returns the corresponding highlight group for the provided or global trail mark selection mode.
---@param mode? string
---@return string
function Common.get_hl_group_for_current_trail_mark_select_mode(mode)
  if mode == nil then
    mode = config.custom.current_trail_mark_mode
  end

  local hl_group = "TrailBlazerTrailMark" .. string.gsub(mode, "_%l", string.upper):gsub("_", "")
  if vim.tbl_contains(config.custom.available_trail_mark_modes, mode) then
    return hl_group
  end

  log.warn("hl_group_does_not_exist", hl_group)

  return "TrailBlazerTrailMarkGlobal"
end

--- Translate a relative cursor position within the provided marks selection to the absolute
--- cursor position within the trail mark stack.
---@param buf? number
---@param marks table
---@param cursor number
function Common.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
  local newest_mark_index, _ = Common.get_newest_and_oldest_mark_index_for_buf(buf)

  Common.trail_mark_cursor = helpers.tbl_indexof(function(mark)
    return marks[cursor] and mark.timestamp == marks[cursor].timestamp
  end, Common.trail_mark_stack) or newest_mark_index

  Common.reregister_trail_marks()
end

--- Return the default buffer for the currently selected trail mark selection mode or the given
--- buffer if it is not nil.
---@param buf? number
---@return number?
function Common.default_buf_for_current_mark_select_mode(buf)
  if buf == nil and (config.custom.current_trail_mark_mode == "buffer_local_chron" or
      config.custom.current_trail_mark_mode == "buffer_local_line_sorted") then
    buf = api.nvim_get_current_buf()
  end

  return buf
end

--- Remove duplicate trail marks from the stack.
function Common.remove_duplicate_pos_trail_marks()
  local trail_count = #Common.trail_mark_stack
  Common.trail_mark_stack = helpers.dedupe(function(item, dedupe_tbl)
    return helpers.tbl_find(function(dedupe_item)
      return item.win == dedupe_item.win and item.buf == dedupe_item.buf and
          item.pos[1] == dedupe_item.pos[1] and item.pos[2] == dedupe_item.pos[2]
    end, dedupe_tbl) ~= nil
  end, Common.trail_mark_stack, function(item)
    api.nvim_buf_del_extmark(item.buf, config.nsid, item.mark_id)
  end)
  if trail_count ~= #Common.trail_mark_stack then
    Common.trail_mark_cursor = #Common.trail_mark_stack - 1
  end
end

--- Update the positions of all trail marks in the stack by loading all extmarks for each loaded
--- buffer and updating the trail mark stack.
function Common.update_all_trail_mark_positions()
  local buf_list = helpers.tbl_flatmap(function(buf)
    return { [buf] = api.nvim_buf_line_count(buf) }
  end, vim.tbl_filter(function(buf)
    return api.nvim_buf_is_loaded(buf)
  end, api.nvim_list_bufs()), true)
  local ext_marks = helpers.tbl_flatmap(function(buf)
    return { [buf] = api.nvim_buf_get_extmarks(buf, config.nsid, 0, -1, {}) }
  end, vim.tbl_keys(buf_list), true)

  for _, trail_mark in ipairs(Common.trail_mark_stack) do
    if ext_marks[trail_mark.buf] then
      local ext_mark = helpers.tbl_find(function(ext_mark)
        return ext_mark[1] == trail_mark.mark_id
      end, ext_marks[trail_mark.buf])

      if ext_mark ~= nil and buf_list[trail_mark.buf] > ext_mark[2] + 1 then
        trail_mark.pos = { ext_mark[2] + 1, ext_mark[3] }
      end
    end
  end
end

--- Reregister all trail marks on the stack. This function can also be used to restore trail marks
--- after calling `vim.lsp.formatting` which currently causes extmarks to be moved out of the
--- buffer range.
function Common.reregister_trail_marks()
  if #Common.trail_mark_stack <= 0 then return end

  local ok, hl_group
  local newest_mark_index, _ = Common.get_newest_and_oldest_mark_index_for_buf(
    Common.default_buf_for_current_mark_select_mode(nil))
  local current_cursor_mark = Common.trail_mark_stack[Common.trail_mark_cursor] or
      Common.trail_mark_stack[#Common.trail_mark_stack]
  local special_marks = {}

  for i, mark in ipairs(Common.trail_mark_stack) do
    local pos_text = api.nvim_buf_get_lines(mark.buf, mark.pos[1] - 1, mark.pos[1], false)[1]
        :sub(mark.pos[2] + 1, mark.pos[2] + 1)

    local mark_options = {
      id = mark.mark_id,
      virt_text_pos = "overlay",
      hl_mode = "combine",
      strict = true,
      priority = i,
    }

    if i == newest_mark_index then
      hl_group = "TrailBlazerTrailMarkNewest"
    elseif current_cursor_mark and current_cursor_mark.pos[1] == mark.pos[1]
        and current_cursor_mark.pos[2] == mark.pos[2] then
      hl_group = "TrailBlazerTrailMarkCursor"
    else
      hl_group = Common.get_hl_group_for_current_trail_mark_select_mode()
    end

    if config.custom.number_line_color_enabled then
      mark_options["number_hl_group"] = hl_group .. "Inverted"
    end

    if config.custom.symbol_line_enabled then
      if special_marks[mark.buf] == nil then
        special_marks[mark.buf] = {}
      end

      if i == Common.trail_mark_cursor + 1 then
        mark_options["sign_text"] = config.custom.next_mark_symbol
        mark_options["sign_hl_group"] = "TrailBlazerTrailMarkNext"
        table.insert(special_marks[mark.buf], mark.pos[1])
      elseif i == Common.trail_mark_cursor - 1 then
        mark_options["sign_text"] = config.custom.previous_mark_symbol
        mark_options["sign_hl_group"] = "TrailBlazerTrailMarkPrevious"
        table.insert(special_marks[mark.buf], mark.pos[1])
      end

      if i == newest_mark_index then
        mark_options["sign_text"] = config.custom.newest_mark_symbol
        mark_options["sign_hl_group"] = hl_group .. "Inverted"
        table.insert(special_marks[mark.buf], mark.pos[1])
      end

      if current_cursor_mark and current_cursor_mark.pos[1] == mark.pos[1]
          and current_cursor_mark.pos[2] == mark.pos[2] then
        mark_options["sign_text"] = config.custom.cursor_mark_symbol
        mark_options["sign_hl_group"] = hl_group .. "Inverted"
        table.insert(special_marks[mark.buf], mark.pos[1])
      end

      if mark_options["sign_text"] and mark_options["sign_text"] ~= "" then
        local count = helpers.tbl_count(function(a) return a == mark.pos[1] end,
          special_marks[mark.buf])

        if count > 1 then
          mark_options["sign_text"] = helpers.sub(tostring(count) .. mark_options["sign_text"],
            1, 2)
        end

        special_marks[mark.buf] = special_marks[mark.buf]
      end
    end

    mark_options["virt_text"] = { { pos_text ~= "" and pos_text or " ", hl_group } }

    ok, mark.mark_id = pcall(api.nvim_buf_set_extmark, mark.buf, config.nsid,
      mark.pos[1] - 1, mark.pos[2], mark_options)

    if not ok then
      table.remove(Common.trail_mark_stack, i)
    end
  end
end

return Common
