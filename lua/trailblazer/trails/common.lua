---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.common
---@mod trailblazer.trails.common
---@brief [[
--- This module is responsible for managing trails common functionality and runtime state.
---@brief ]]

local api = vim.api
local fn = vim.fn
local Common = {}

local config = require("trailblazer.trails.config")
local helpers = require("trailblazer.helpers")
local stacks = require("trailblazer.trails.stacks")
local log = require("trailblazer.log")

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

  stacks.trail_mark_cursor = #stacks.current_trail_mark_stack
  Common.reregister_trail_marks(true)

  return true
end

--- Set the cursor to the previous trail mark.
---@param buf? number
---@param current_mark_index? number
function Common.set_cursor_to_previous_mark(buf, current_mark_index)
  local marks, cursor = Common.get_relative_marks_and_cursor(buf, current_mark_index)

  if current_mark_index and current_mark_index == stacks.trail_mark_cursor then
    cursor = cursor > 1 and cursor - 1 or #marks > 0 and 1 or 0
  end

  Common.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
end

--- Set the cursor to the next trail mark.
---@param buf? number
---@param current_mark_index? number
function Common.set_cursor_to_next_mark(buf, current_mark_index)
  local marks, cursor = Common.get_relative_marks_and_cursor(buf, current_mark_index)

  if current_mark_index and current_mark_index == stacks.trail_mark_cursor then
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

  if mode == "custom_ord" then
    if stacks.custom_ord_local_buf ~= nil then
      table.sort(stacks.current_trail_mark_stack, function(a, b)
        if a.buf == stacks.custom_ord_local_buf then
          if b.buf == stacks.custom_ord_local_buf then
            return a.custom_ord and b.custom_ord and a.custom_ord < b.custom_ord
          else
            return true
          end
        elseif b.buf == stacks.custom_ord_local_buf then
          return false
        else
          return a.custom_ord and b.custom_ord and a.custom_ord < b.custom_ord
        end
      end)
    else
      table.sort(stacks.current_trail_mark_stack, function(a, b)
        return a.custom_ord and b.custom_ord and a.custom_ord < b.custom_ord
      end)
    end
  elseif mode == "global_chron" then
    table.sort(stacks.current_trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)
  elseif mode == "global_buf_line_sorted" then
    table.sort(stacks.current_trail_mark_stack, function(a, b)
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
  elseif mode == "global_fpath_line_sorted" then
    local buf_lookup_table = stacks.create_buf_file_lookup_table(true)
    table.sort(stacks.current_trail_mark_stack, function(a, b)
      if buf_lookup_table[a.buf] == buf_lookup_table[b.buf] then
        if a.pos[1] == b.pos[1] then
          return a.pos[2] < b.pos[2]
        else
          return a.pos[1] < b.pos[1]
        end
      else
        return (buf_lookup_table[a.buf] or "") < (buf_lookup_table[b.buf] or "")
      end
    end)
  elseif mode == "global_chron_buf_line_sorted" or mode == "global_chron_fpath_line_sorted" then
    table.sort(stacks.current_trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)

    if mode == "global_chron_buf_line_sorted" then
      table.sort(stacks.current_trail_mark_stack, function(a, b)
        return a.buf < b.buf
      end)
    else
      local buf_lookup_table = stacks.create_buf_file_lookup_table(true)
      table.sort(stacks.current_trail_mark_stack, function(a, b)
        return (buf_lookup_table[a.buf] or "") < (buf_lookup_table[b.buf] or "")
      end)
    end

    table.sort(stacks.current_trail_mark_stack, function(a, b)
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

    table.sort(stacks.current_trail_mark_stack, function(a, b)
      return a.timestamp > b.timestamp
    end)

    for _, mark in ipairs(stacks.current_trail_mark_stack) do
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

    stacks.current_trail_mark_stack = new_trail_mark_stack
  elseif mode == "buffer_local_chron" then
    table.sort(stacks.current_trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        return a.timestamp < b.timestamp
      else
        return a.buf < b.buf
      end
    end)
  elseif mode == "buffer_local_line_sorted" then
    table.sort(stacks.current_trail_mark_stack, function(a, b)
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
  local win_ids = api.nvim_list_wins()

  if trail_mark.win == nil or not vim.tbl_contains(win_ids, trail_mark.win) then
    trail_mark.win = win_ids[1] or api.nvim_get_current_win()
  end

  ok, _ = pcall(api.nvim_set_current_win, trail_mark.win)
  if not ok then
    api.nvim_set_current_win(0)
  end

  if trail_mark.buf == nil or not api.nvim_buf_is_loaded(trail_mark.buf) or
      not api.nvim_buf_is_valid(trail_mark.buf) then
    return false
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
  local old_trail_mark_cursor = stacks.trail_mark_cursor

  if trail_mark_index and trail_mark_index > 0 then
    local trail_mark, ext_mark
    trail_mark_index, trail_mark, ext_mark = Common.get_marks_for_trail_mark_index(buf,
      trail_mark_index, remove_trail_mark)
    if trail_mark_index == nil or trail_mark == nil or ext_mark == nil or
        buf and trail_mark.buf ~= buf then
      return false
    end

    stacks.trail_mark_cursor = trail_mark_index

    if Common.focus_win_and_buf(trail_mark, ext_mark) then
      return true
    end
  end

  stacks.trail_mark_cursor = old_trail_mark_cursor
  return false
end

--- Returns the trail mark and its index in the trail mark stack at the specified location.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return number?
---@return table?
function Common.get_trail_mark_at_pos(win, buf, pos)
  local trail_mark_index
  local current_win = win or api.nvim_get_current_win()
  local current_buffer = buf or api.nvim_get_current_buf()
  local current_pos = pos or api.nvim_win_get_cursor(0)
  local ext_marks = api.nvim_buf_get_extmarks(current_buffer, config.nsid, 0, -1, {})

  local current_ext_mark = helpers.tbl_find(function(ext_mark)
    return ext_mark[2] + 1 == current_pos[1] and ext_mark[3] == current_pos[2]
  end, ext_marks)

  Common.update_all_trail_mark_positions()
  Common.remove_duplicate_pos_trail_marks()

  if current_ext_mark ~= nil then
    trail_mark_index = helpers.tbl_indexof(function(trail_mark)
      return (current_win == -1 or current_win == trail_mark.win)
          and current_buffer == trail_mark.buf and trail_mark.mark_id == current_ext_mark[1]
    end, stacks.current_trail_mark_stack)
  end

  if trail_mark_index ~= nil then
    if stacks.trail_mark_cursor > #stacks.current_trail_mark_stack then
      stacks.trail_mark_cursor = trail_mark_index
    end

    Common.reregister_trail_marks(true)
    return trail_mark_index, stacks.current_trail_mark_stack[trail_mark_index]
  end

  Common.reregister_trail_marks(true)

  return nil, nil
end

--- Returns the trail mark nearest to the provided position (or the current cursor position if pos
--- is omitted) and its index within the trail mark stack. The minimum distance is found by
--- calculating the Manhattan Distance between the provided pos and the respective trail mark
--- positions. If buf is omitted the minimum distance of pos in all buffers will be returned.
---@param buf? number
---@param pos? table<number, number>
---@param directive? string
---@return number?
---@return table?
function Common.get_nearest_trail_mark_for_pos(buf, pos, directive)
  local nearest_mark_index = nil
  local nearest_mark = nil
  local nearest_mark_distance = math.huge
  local buf_file_path_lookup = nil
  local file_paths = nil

  pos = pos or api.nvim_win_get_cursor(0)
  buf = buf and buf > 0 and buf or api.nvim_get_current_buf()

  if directive and not vim.tbl_contains(config.custom.available_move_to_nearest_directives,
        directive) then
    log.warn("invalid_move_to_nearest_directive", table.concat(
      config.custom.available_move_to_nearest_directives, ", "))
  elseif directive == "fpath_up" or directive == "fpath_down" then
    buf_file_path_lookup = stacks.create_buf_file_lookup_table(true,
      { stacks.current_trail_mark_stack_name })
    buf_file_path_lookup[buf] = fn.expand(api.nvim_buf_get_name(buf))
    file_paths = vim.tbl_values(buf_file_path_lookup)

    table.sort(file_paths, function(a, b)
      return a < b
    end)
  end

  if directive == "fpath_up" then
    if helpers.tbl_min(stacks.current_trail_mark_stack, function(trail_mark)
          return trail_mark.buf == buf and trail_mark.pos[1] or math.huge
        end) < pos[1] then
      directive = "up"
    else
      local previous_fpath = file_paths[math.max((helpers.tbl_indexof(function(file_path)
        return file_path == buf_file_path_lookup[buf]
      end, file_paths) or 0) - 1, 1)]

      local previous_buf = helpers.tbl_find(function(bufnr)
        return buf_file_path_lookup[bufnr] == previous_fpath
      end, vim.tbl_keys(buf_file_path_lookup))

      if previous_buf == buf then return nil, nil end

      for i = #stacks.current_trail_mark_stack, 1, -1 do
        if stacks.current_trail_mark_stack[i].buf == previous_buf then
          nearest_mark_index = i
          break
        end
      end

      return nearest_mark_index, stacks.current_trail_mark_stack[nearest_mark_index]
    end
  elseif directive == "fpath_down" then
    if helpers.tbl_max(stacks.current_trail_mark_stack, function(trail_mark)
          return trail_mark.buf == buf and trail_mark.pos[1] or -1
        end) > pos[1] then
      directive = "down"
    else
      local next_fpath = file_paths[math.min((helpers.tbl_indexof(function(file_path)
        return file_path == buf_file_path_lookup[buf]
      end, file_paths) or #file_paths) + 1, #file_paths)]

      local next_buf = helpers.tbl_find(function(bufnr)
        return buf_file_path_lookup[bufnr] == next_fpath
      end, vim.tbl_keys(buf_file_path_lookup))

      if next_buf == buf then return nil, nil end

      nearest_mark_index = helpers.tbl_indexof(function(trail_mark)
            return trail_mark.buf == next_buf
          end, stacks.current_trail_mark_stack) or #stacks.current_trail_mark_stack

      return nearest_mark_index, stacks.current_trail_mark_stack[nearest_mark_index]
    end
  end

  for i, trail_mark in ipairs(stacks.current_trail_mark_stack) do
    if not buf or trail_mark.buf == buf then
      if not directive or (directive == "up" and trail_mark.pos[1] < pos[1] or directive == "down"
          and trail_mark.pos[1] > pos[1]) then
        local manhattan_distance = helpers.manhattan_distance(trail_mark.pos, pos)
        if manhattan_distance < nearest_mark_distance then
          nearest_mark_distance = manhattan_distance
          nearest_mark_index = i
          nearest_mark = trail_mark
        end
      end
    end
  end

  return nearest_mark_index, nearest_mark
end

--- Return the trail mark at the given position as well as the corresponding extmark.
---@param buf? number
---@param newest_mark_index? number
---@return number?
---@return table?
---@return table?
function Common.get_marks_for_trail_mark_index(buf, newest_mark_index, remove_trail_mark)
  local ok, extracted_ext_mark, last_mark

  while #stacks.current_trail_mark_stack > 0 do
    if newest_mark_index then
      last_mark = stacks.current_trail_mark_stack[newest_mark_index]

      if last_mark and last_mark.buf and api.nvim_buf_is_loaded(last_mark.buf)
          and api.nvim_buf_is_valid(last_mark.buf) then
        ok, extracted_ext_mark = pcall(api.nvim_buf_get_extmarks, last_mark.buf,
          config.nsid, last_mark.mark_id, last_mark.mark_id, {})

        if remove_trail_mark then
          table.remove(stacks.current_trail_mark_stack, newest_mark_index)
        end

        if ok then
          break
        else
          log.error("unable_to_get_extmarks", "[" .. last_mark.buf .. " | " .. newest_mark_index
          .. "]")
          return nil, nil, nil
        end
      else
        return nil, nil, nil
      end
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

  for i, trail_mark in ipairs(stacks.current_trail_mark_stack) do
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

  return newest_mark_index or #stacks.current_trail_mark_stack, oldest_mark_index or 0
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
    end, stacks.current_trail_mark_stack)
    cursor = helpers.tbl_indexof(function(mark)
          return mark.buf == buf and stacks.current_trail_mark_stack[current_mark_index] and
              stacks.current_trail_mark_stack[current_mark_index].mark_id == mark.mark_id
        end, marks) or helpers.tbl_indexof(function(mark)
          return mark.buf == buf and stacks.current_trail_mark_stack[stacks.trail_mark_cursor] and
              mark.timestamp == stacks.current_trail_mark_stack[stacks.trail_mark_cursor].timestamp
        end, marks) or #marks
  else
    marks = stacks.current_trail_mark_stack
    cursor = stacks.trail_mark_cursor or #stacks.current_trail_mark_stack
  end

  return marks, cursor
end

--- Get the index of the first trail mark that matches the given window, buffer and position.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return integer?
function Common.get_first_trail_mark_index(win, buf, pos)
  return helpers.tbl_indexof(function(mark)
    return (not win or win and mark.win == win) and
        (not win or buf and mark.buf == buf) and
        (not pos or pos and mark.pos[1] == pos[1] and mark.pos[2] == pos[2])
  end, stacks.current_trail_mark_stack)
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

  stacks.trail_mark_cursor = helpers.tbl_indexof(function(mark)
        return marks[cursor] and mark.timestamp == marks[cursor].timestamp
      end, stacks.current_trail_mark_stack) or newest_mark_index

  Common.reregister_trail_marks(true)
end

--- Return the default buffer for the currently selected trail mark selection mode or the given
--- buffer if it is not nil.
---@param buf? number
---@return number?
function Common.default_buf_for_current_mark_select_mode(buf)
  if config.custom.current_trail_mark_mode == "custom_ord" then
    buf = stacks.custom_ord_local_buf
  elseif buf == nil and (config.custom.current_trail_mark_mode == "buffer_local_chron" or
      config.custom.current_trail_mark_mode == "buffer_local_line_sorted") then
    buf = api.nvim_get_current_buf()
  end

  return buf
end

--- Remove duplicate trail marks from the stack.
function Common.remove_duplicate_pos_trail_marks()
  local trail_count = #stacks.current_trail_mark_stack
  stacks.current_trail_mark_stack = helpers.dedupe(function(item, dedupe_tbl)
    return helpers.tbl_find(function(dedupe_item)
          return item.win == dedupe_item.win and item.buf == dedupe_item.buf and
              item.pos[1] == dedupe_item.pos[1] and item.pos[2] == dedupe_item.pos[2]
        end, dedupe_tbl) ~= nil
  end, stacks.current_trail_mark_stack, function(item)
    api.nvim_buf_del_extmark(item.buf, config.nsid, item.mark_id)
  end)
  if trail_count ~= #stacks.current_trail_mark_stack then
    stacks.trail_mark_cursor = #stacks.current_trail_mark_stack - 1
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

  for i = #stacks.current_trail_mark_stack, 1, -1 do
    local trail_mark = stacks.current_trail_mark_stack[i]
    if ext_marks[trail_mark.buf] then
      local ext_mark = helpers.tbl_find(function(ext_mark)
        return ext_mark[1] == trail_mark.mark_id
      end, ext_marks[trail_mark.buf])

      if ext_mark ~= nil and (ext_mark[3] > 0 or trail_mark.pos[2] == 0 and ext_mark[3] == 0) then
        trail_mark.pos = { ext_mark[2] + 1, ext_mark[3] }
      elseif ext_mark ~= nil and trail_mark.pos[2] ~= 0 then
        api.nvim_buf_del_extmark(trail_mark.buf, config.nsid, trail_mark.mark_id)
        table.remove(stacks.current_trail_mark_stack, i)
      end
    end
  end
end

--- Delete the trail mark at the provided position.
---@param win? number
---@param buf? number
---@param pos? table<number,number>
---@return boolean
function Common.delete_trail_mark_at_pos(win, buf, pos)
  local trail_mark_index, trail_mark = Common.get_trail_mark_at_pos(win, buf, pos)

  if trail_mark_index and trail_mark then
    api.nvim_buf_del_extmark(trail_mark.buf, config.nsid, trail_mark.mark_id)
    table.remove(stacks.current_trail_mark_stack, trail_mark_index)

    local newest_mark_index, oldest_mark_index = Common.get_newest_and_oldest_mark_index_for_buf(
      buf)

    if trail_mark_index <= stacks.trail_mark_cursor and stacks.trail_mark_cursor
        >= oldest_mark_index and stacks.trail_mark_cursor <= newest_mark_index then
      stacks.trail_mark_cursor = stacks.trail_mark_cursor - 1
    elseif stacks.trail_mark_cursor - 1 <= oldest_mark_index then
      stacks.trail_mark_cursor = oldest_mark_index
    end

    Common.reregister_trail_marks()
    return true
  end

  return false
end

--- Delete extmarks from all buffers.
---@param buf? number | table
function Common.delete_all_ext_marks(buf)
  if type(buf) == "number" then
    api.nvim_buf_clear_namespace(buf, config.nsid, 0, -1)
    return
  end

  local buf_list = type(buf) == "table" and buf or api.nvim_list_bufs()

  for _, b in ipairs(buf_list) do
    api.nvim_buf_clear_namespace(b, config.nsid, 0, -1)
  end
end

--- Returns a list of buffers and a list of trail marks that are currently visible in any window
--- and have to be reregistered.
---@return table
---@return table
function Common.get_reregister_buf_list_and_trail_marks()
  local buf_list = vim.tbl_map(function(win)
    return api.nvim_win_get_buf(win)
  end, api.nvim_list_wins())

  local trail_marks = vim.tbl_filter(function(mark)
    return vim.tbl_contains(buf_list, mark.buf)
  end, stacks.current_trail_mark_stack)

  return buf_list, trail_marks
end

--- Reregister all or only currently visible trail marks on the stack. This function can also be
--- used to restore trail marks after calling `vim.lsp.formatting` which currently causes extmarks
--- to be moved out of the buffer range.
---@param visible_only? boolean
function Common.reregister_trail_marks(visible_only)
  local buf_list, trail_marks
  local buf_line_counts = {}

  if visible_only then
    buf_list, trail_marks = Common.get_reregister_buf_list_and_trail_marks()
  else
    trail_marks = stacks.current_trail_mark_stack
  end

  Common.delete_all_ext_marks(buf_list)

  if #stacks.current_trail_mark_stack <= 0 then return end

  local ok, hl_group
  local newest_mark_index, _ = Common.get_newest_and_oldest_mark_index_for_buf(
    Common.default_buf_for_current_mark_select_mode(nil))
  local current_cursor_mark = stacks.current_trail_mark_stack[stacks.trail_mark_cursor] or
      stacks.current_trail_mark_stack[#stacks.current_trail_mark_stack]
  local special_marks = {}

  for i, mark in ipairs(trail_marks) do
    if api.nvim_buf_is_loaded(mark.buf) and api.nvim_buf_is_valid(mark.buf) then
      buf_line_counts[mark.buf] = buf_line_counts[mark.buf] or api.nvim_buf_line_count(mark.buf)
      mark.pos[1] = mark.pos[1] > buf_line_counts[mark.buf] and buf_line_counts[mark.buf] or
          mark.pos[1]
      local char, char_w = helpers.buf_get_utf8_char_at_pos(mark.buf, mark.pos)

      local mark_options = {
        id = mark.mark_id,
        virt_text_pos = "overlay",
        hl_mode = "combine",
        strict = true,
        priority = config.custom.trail_mark_priority,
      }

      if mark.mark_id == stacks.current_trail_mark_stack[newest_mark_index].mark_id then
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

        if stacks.current_trail_mark_stack[stacks.trail_mark_cursor + 1] and
            mark.mark_id == stacks.current_trail_mark_stack[stacks.trail_mark_cursor + 1].mark_id
        then
          mark_options["sign_text"] = config.custom.next_mark_symbol
          mark_options["sign_hl_group"] = "TrailBlazerTrailMarkNext"
          table.insert(special_marks[mark.buf], mark.pos[1])
        elseif stacks.current_trail_mark_stack[stacks.trail_mark_cursor - 1] and
            mark.mark_id == stacks.current_trail_mark_stack[stacks.trail_mark_cursor - 1].mark_id
        then
          mark_options["sign_text"] = config.custom.previous_mark_symbol
          mark_options["sign_hl_group"] = "TrailBlazerTrailMarkPrevious"
          table.insert(special_marks[mark.buf], mark.pos[1])
        end

        if mark.mark_id == stacks.current_trail_mark_stack[newest_mark_index].mark_id then
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

        if config.custom.multiple_mark_symbol_counters_enabled and mark_options["sign_text"]
            and mark_options["sign_text"] ~= "" then
          local count = helpers.tbl_count(function(a) return a == mark.pos[1] end,
            special_marks[mark.buf])

          if count > 1 then
            mark_options["sign_text"] = helpers.sub(tostring(count) .. mark_options["sign_text"],
              1, 2)
          end

          special_marks[mark.buf] = special_marks[mark.buf]
        end

        if config.custom.trail_mark_symbol_line_indicators_enabled and
            (mark_options["sign_text"] == nil or mark_options["sign_text"] == "") then
          mark_options["sign_text"] = config.custom.mark_symbol
          mark_options["sign_hl_group"] = "TrailBlazerTrailMark"
        end
      end

      if config.custom.trail_mark_in_text_highlights_enabled then
        local curr_line = api.nvim_buf_get_lines(mark.buf, mark.pos[1] - 1, mark.pos[1], false)[1]
        if char == "" and curr_line and #curr_line - 1 <= 0 then
          mark_options["virt_text"] = { { " ", hl_group } }
          mark.pos[2] = 0
        else
          mark.pos[2] = mark.pos[2] >= #curr_line and #curr_line - 1 or mark.pos[2]
          mark_options["hl_group"] = hl_group
          mark_options["end_col"] = mark.pos[2] + char_w
        end
      end

      ok, mark.mark_id = pcall(api.nvim_buf_set_extmark, mark.buf, config.nsid,
        mark.pos[1] - 1, mark.pos[2], mark_options)
    else
      ok = false
    end

    if not ok then
      table.remove(stacks.current_trail_mark_stack, i)
    end
  end
end

--- Returns a subset of the trail mark stack for a given buffer or the whole stack if no buffer is
--- given.
---@param buf? number
---@return table?
function Common.get_trail_mark_stack_subset_for_buf(buf)
  if buf then
    if fn.getbufvar(buf, "current_syntax") == "qf" then
      return nil
    end

    return vim.tbl_filter(function(mark)
      return mark.buf == buf
    end, stacks.current_trail_mark_stack)
  else
    return stacks.current_trail_mark_stack
  end
end

return Common
