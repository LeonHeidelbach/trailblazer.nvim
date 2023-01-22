---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer.trails
---@brief [[
--- This module is responsible for managing trails.
---@brief ]]

local api = vim.api
local fn = vim.fn
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")
local Trails = {}

Trails.config = {}
Trails.config.custom = {}
Trails.config.custom.available_trail_mark_modes = {
  "global_chron",
  "global_buf_line_sorted",
  "global_chron_buf_line_sorted",
  "global_chron_buf_switch_group_chron",
  "global_chron_buf_switch_group_line_sorted",
  "buffer_local_chron",
  "buffer_local_line_sorted"
}
Trails.config.custom.current_trail_mark_mode = "global_chron"
Trails.config.custom.verbose_trail_mark_select = true
Trails.config.custom.newest_mark_symbol = "⬤"
Trails.config.custom.cursor_mark_symbol = "⬤"
Trails.config.custom.next_mark_symbol = "⬤"
Trails.config.custom.previous_mark_symbol = "⬤"
Trails.config.custom.number_line_color_enabled = true
Trails.config.custom.symbol_line_enabled = true

Trails.config.ns_name = "trailblazer"
Trails.config.ucid = 0
Trails.config.nsid = api.nvim_create_namespace(Trails.config.ns_name)

Trails.trail_mark_cursor = 0
Trails.trail_mark_stack = {}

--- Setup the TrailBlazer trails module.
---@param options? table
function Trails.setup(options)
  if options then
    Trails.config.custom = vim.tbl_deep_extend("force", Trails.config.custom, options)
  end
end

--- Add a new trail mark to the stack.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return table?
function Trails.new_trail_mark(win, buf, pos)
  local trail_mark_index, trail_mark = Trails.get_trail_mark_under_cursor(win, buf, pos)

  if trail_mark_index and trail_mark then
    api.nvim_buf_del_extmark(trail_mark.buf, Trails.config.nsid, trail_mark.mark_id)
    table.remove(Trails.trail_mark_stack, trail_mark_index)

    local newest_mark_index, oldest_mark_index = Trails.get_newest_and_oldest_mark_index_for_buf(
      buf)

    if trail_mark_index <= Trails.trail_mark_cursor and Trails.trail_mark_cursor
        >= oldest_mark_index and Trails.trail_mark_cursor <= newest_mark_index then
      Trails.trail_mark_cursor = Trails.trail_mark_cursor - 1
    elseif Trails.trail_mark_cursor - 1 <= oldest_mark_index then
      Trails.trail_mark_cursor = oldest_mark_index
    end

    Trails.reregister_trail_marks()
    return nil
  end

  local current_win = win or api.nvim_get_current_win()
  local current_buf = buf or api.nvim_get_current_buf()
  local current_cursor = pos or api.nvim_win_get_cursor(current_win)
  local pos_text = api.nvim_buf_get_lines(current_buf, current_cursor[1] - 1, current_cursor[1],
    false)[1]

  if not pos_text or not current_cursor[1] or not current_cursor[2] then
    log.error("invalid_pos_for_buf_lines")
    return nil
  end

  local new_mark = {
    timestamp = fn.reltimefloat(fn.reltime()),
    win = current_win, buf = current_buf,
    pos = current_cursor, mark_id = Trails.config.ucid + 1,
  }

  table.insert(Trails.trail_mark_stack, new_mark)

  Trails.config.ucid = Trails.config.ucid + 1
  Trails.sort_trail_mark_stack()
  Trails.trail_mark_cursor, _ = Trails.get_newest_and_oldest_mark_index_for_buf(buf)
  Trails.reregister_trail_marks()

  return Trails.trail_mark_stack[Trails.trail_mark_cursor]
end

--- Remove the last global or buffer local trail mark from the stack.
---@param buf? number
---@return boolean
function Trails.track_back(buf)
  buf = Trails.default_buf_for_current_mark_select_mode(buf)

  local newest_mark_index, _ = Trails.get_newest_and_oldest_mark_index_for_buf(buf)

  if newest_mark_index then
    local trail_mark, ext_mark
    newest_mark_index, trail_mark, ext_mark = Trails.get_marks_for_trail_mark_index(buf,
      newest_mark_index, true)
    if newest_mark_index == nil or trail_mark == nil or ext_mark == nil then
      return false
    end

    Trails.focus_win_and_buf(trail_mark, ext_mark)
    api.nvim_buf_del_extmark(trail_mark.buf, Trails.config.nsid, trail_mark.mark_id)

    Trails.trail_mark_cursor, _ = Trails.get_newest_and_oldest_mark_index_for_buf(buf)
    Trails.reregister_trail_marks()

    return true
  end

  return false
end

--- Peek move to the next trail mark if sorted chronologically or up if sorted by line.
---@param buf? number
---@return boolean
function Trails.peek_move_next_up(buf)
  local current_mark_index, _ = Trails.get_trail_mark_under_cursor()

  buf = Trails.default_buf_for_current_mark_select_mode(buf)

  Trails.set_cursor_to_next_mark(buf, current_mark_index)

  return Trails.focus_win_and_buf_by_trail_mark_index(buf, Trails.trail_mark_cursor, false)
end

--- Peek move to the previous trail mark if sorted chronologically or down if sorted by line.
---@param buf? number
---@return boolean
function Trails.peek_move_previous_down(buf)
  local current_mark_index, _ = Trails.get_trail_mark_under_cursor()

  buf = Trails.default_buf_for_current_mark_select_mode(buf)

  Trails.set_cursor_to_previous_mark(buf, current_mark_index)

  return Trails.focus_win_and_buf_by_trail_mark_index(buf, Trails.trail_mark_cursor, false)
end

--- Paste the selected register contents at the last trail mark of all or a specific buffer.
---@param buf? number
---@return boolean
function Trails.paste_at_last_trail_mark(buf)
  buf = Trails.default_buf_for_current_mark_select_mode(buf)

  local newest_mark_index, _ = Trails.get_newest_and_oldest_mark_index_for_buf(buf)

  if newest_mark_index then
    return Trails.paste_at_trail_mark(buf, newest_mark_index)
  end

  return false
end

--- Paste the selected register contents at all trail marks of all or a specific buffer.
---@param buf? number
function Trails.paste_at_all_trail_marks(buf)
  buf = Trails.default_buf_for_current_mark_select_mode(buf)

  if buf ~= nil then
    for i = #Trails.trail_mark_stack, 1, -1 do
      if Trails.trail_mark_stack[i].buf == buf then
        Trails.paste_at_trail_mark(buf, i)
      end
    end
  else
    for i = #Trails.trail_mark_stack, 1, -1 do
      Trails.paste_at_trail_mark(buf, i)
    end
  end
end

--- Paste the selected register contents at a specifi trail mark.
---@param buf? number
---@param trail_mark_index? number
---@return boolean
function Trails.paste_at_trail_mark(buf, trail_mark_index)
  local trail_mark, ext_mark
  trail_mark_index, trail_mark, ext_mark = Trails.get_marks_for_trail_mark_index(buf,
    trail_mark_index, true)
  if trail_mark_index == nil or trail_mark == nil or ext_mark == nil then
    return false
  end

  local ok = Trails.focus_win_and_buf(trail_mark, ext_mark)
  if not ok then
    return false
  end

  api.nvim_paste(fn.getreg(api.nvim_get_vvar("register")), false, -1)
  api.nvim_buf_del_extmark(trail_mark.buf, Trails.config.nsid, trail_mark.mark_id)

  Trails.trail_mark_cursor = #Trails.trail_mark_stack
  Trails.reregister_trail_marks()

  return true
end

--- Delete all trail marks from the stack and all or a specific buffer.
---@param buf? number
function Trails.delete_all_trail_marks(buf)
  if buf == nil then
    for _, mark in ipairs(Trails.trail_mark_stack) do
      pcall(api.nvim_buf_del_extmark, mark.buf, Trails.config.nsid, mark.mark_id)
      Trails.trail_mark_cursor = Trails.trail_mark_cursor - 1
    end

    Trails.trail_mark_cursor = Trails.trail_mark_cursor > 0 and Trails.trail_mark_cursor or 0
    Trails.trail_mark_stack = {}
    Trails.config.ucid = 0
  else
    local ext_marks = api.nvim_buf_get_extmarks(buf, Trails.config.nsid, 0, -1, {})

    for _, ext_mark in ipairs(ext_marks) do
      pcall(api.nvim_buf_del_extmark, buf, Trails.config.nsid, ext_mark[1])
    end

    Trails.trail_mark_stack = vim.tbl_filter(function(mark)
      return mark.buf ~= buf
    end, Trails.trail_mark_stack)

    Trails.trail_mark_cursor = #Trails.trail_mark_stack
  end
end

--- Set the trail mark selection mode to the given mode or toggle between the available modes.
---@param mode? string
function Trails.set_trail_mark_select_mode(mode)
  if mode == nil then
    Trails.config.custom.current_trail_mark_mode = Trails.config.custom.available_trail_mark_modes[
        (helpers.tbl_indexof(function(available_mode)
          return available_mode == Trails.config.custom.current_trail_mark_mode
        end, Trails.config.custom.available_trail_mark_modes)) %
            #Trails.config.custom.available_trail_mark_modes + 1
        ]
  elseif vim.tbl_contains(Trails.config.custom.available_trail_mark_modes, mode) then
    Trails.config.custom.current_trail_mark_mode = mode
  else
    log.warn("invalid_trail_mark_select_mode",
      table.concat(Trails.config.custom.available_trail_mark_modes, ", "))
    return
  end

  Trails.update_all_trail_mark_positions()
  Trails.sort_trail_mark_stack()
  Trails.reregister_trail_marks()

  if Trails.config.custom.verbose_trail_mark_select then
    log.info("current_trail_mark_select_mode", Trails.config.custom.current_trail_mark_mode)
  end
end

--- Set the cursor to the next trail mark.
---@param buf? number
---@param current_mark_index? number
function Trails.set_cursor_to_next_mark(buf, current_mark_index)
  local marks, cursor = Trails.get_relative_marks_and_cursor(buf, current_mark_index)

  if current_mark_index and current_mark_index == Trails.trail_mark_cursor then
    cursor = cursor + 1 <= #marks and cursor + 1 or #marks
  end

  Trails.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
end

--- Set the cursor to the previous trail mark.
---@param buf? number
---@param current_mark_index? number
function Trails.set_cursor_to_previous_mark(buf, current_mark_index)
  local marks, cursor = Trails.get_relative_marks_and_cursor(buf, current_mark_index)

  if current_mark_index and current_mark_index == Trails.trail_mark_cursor then
    cursor = cursor > 1 and cursor - 1 or #marks > 0 and 1 or 0
  end

  Trails.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
end

--- Sort the trail mark stack according to the current or provided trail mark mode.
---@param mode? string
function Trails.sort_trail_mark_stack(mode)
  if mode == nil then
    mode = Trails.config.custom.current_trail_mark_mode
  end

  if mode == "global_chron" then
    table.sort(Trails.trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)
  elseif mode == "global_buf_line_sorted" then
    table.sort(Trails.trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        if a.pos[1] == b.pos[1] then
          return a.pos[2] > b.pos[2]
        else
          return a.pos[1] > b.pos[1]
        end
      else
        return a.buf < b.buf
      end
    end)
  elseif mode == "global_chron_buf_line_sorted" then
    table.sort(Trails.trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)

    table.sort(Trails.trail_mark_stack, function(a, b)
      return a.buf < b.buf
    end)

    table.sort(Trails.trail_mark_stack, function(a, b)
      return a.pos[1] > b.pos[1] or (a.pos[1] == b.pos[1] and a.pos[2] > b.pos[2])
    end)
  elseif mode == "global_chron_buf_switch_group_chron" or
      mode == "global_chron_buf_switch_group_line_sorted" then
    local new_trail_mark_stack = {}
    local ordered_trail_mark_subsets = {}
    local current_subset = {}
    local current_buf = -1

    local function sort_current_subset_and_insert()
      table.sort(current_subset, function(a, b)
        return a.pos[1] > b.pos[1] or (a.pos[1] == b.pos[1] and a.pos[2] > b.pos[2])
      end)
      if mode == "global_chron_buf_switch_group_chron" then
        table.insert(ordered_trail_mark_subsets, 1, current_subset)
      elseif mode == "global_chron_buf_switch_group_line_sorted" then
        table.insert(ordered_trail_mark_subsets, current_subset)
      end
      current_subset = {}
    end

    table.sort(Trails.trail_mark_stack, function(a, b)
      return a.timestamp < b.timestamp
    end)

    for _, mark in ipairs(Trails.trail_mark_stack) do
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
          return a[1].pos[1] > b[1].pos[1] or (a[1].pos[1] == b[1].pos[1]
              and a[1].pos[2] > b[1].pos[2])
        end
        return false
      end)
    end

    for _, subset in ipairs(ordered_trail_mark_subsets) do
      helpers.tbl_append(new_trail_mark_stack, subset)
    end

    Trails.trail_mark_stack = new_trail_mark_stack
  elseif mode == "buffer_local_chron" then
    table.sort(Trails.trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        return a.timestamp < b.timestamp
      else
        return a.buf < b.buf
      end
    end)
  elseif mode == "buffer_local_line_sorted" then
    table.sort(Trails.trail_mark_stack, function(a, b)
      if a.buf == b.buf then
        return a.pos[1] > b.pos[1] or (a.pos[1] == b.pos[1] and a.pos[2] > b.pos[2])
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
function Trails.focus_win_and_buf(trail_mark, ext_mark)
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
function Trails.focus_win_and_buf_by_trail_mark_index(buf, trail_mark_index, remove_trail_mark)
  if trail_mark_index > 0 then
    local trail_mark, ext_mark
    trail_mark_index, trail_mark, ext_mark = Trails.get_marks_for_trail_mark_index(buf,
      trail_mark_index, remove_trail_mark)
    if trail_mark_index == nil or trail_mark == nil or ext_mark == nil or
        buf and trail_mark.buf ~= buf then
      return false
    end

    return Trails.focus_win_and_buf(trail_mark, ext_mark)
  end

  return false
end

--- Return the trail mark and its index in the trail mark stack under the current cursor location.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return number?
---@return table?
function Trails.get_trail_mark_under_cursor(win, buf, pos)
  local trail_mark_index
  local current_win = win or api.nvim_get_current_win()
  local current_buffer = buf or api.nvim_get_current_buf()
  local current_cursor = pos or api.nvim_win_get_cursor(0)
  local ext_marks = api.nvim_buf_get_extmarks(current_buffer, Trails.config.nsid, 0, -1, {})

  local current_ext_mark = helpers.tbl_find(function(ext_mark)
    return ext_mark[2] + 1 == current_cursor[1] and ext_mark[3] == current_cursor[2]
  end, ext_marks)

  Trails.update_all_trail_mark_positions()
  Trails.remove_duplicate_pos_trail_marks()

  if current_ext_mark ~= nil then
    trail_mark_index = helpers.tbl_indexof(function(trail_mark)
      return current_win == trail_mark.win and current_buffer == trail_mark.buf and
          trail_mark.mark_id == current_ext_mark[1]
    end, Trails.trail_mark_stack)
  end

  if trail_mark_index ~= nil then
    if Trails.trail_mark_cursor > #Trails.trail_mark_stack then
      Trails.trail_mark_cursor = trail_mark_index
    end

    Trails.reregister_trail_marks()
    return trail_mark_index, Trails.trail_mark_stack[trail_mark_index]
  end

  Trails.reregister_trail_marks()

  return nil, nil
end

--- Return the trail mark at the given position as well as the corresponding extmark.
---@param buf? number
---@param newest_mark_index? number
---@return number?
---@return table?
---@return table?
function Trails.get_marks_for_trail_mark_index(buf, newest_mark_index, remove_trail_mark)
  local ok, extracted_ext_mark, last_mark

  while #Trails.trail_mark_stack > 0 do
    if newest_mark_index then
      last_mark = Trails.trail_mark_stack[newest_mark_index]

      if last_mark then
        ok, extracted_ext_mark, _ = pcall(api.nvim_buf_get_extmarks, last_mark.buf,
          Trails.config.nsid, last_mark.mark_id, last_mark.mark_id, {})
      end

      if remove_trail_mark then
        table.remove(Trails.trail_mark_stack, newest_mark_index)
      end

      if ok then break end
    else
      return nil, nil, nil
    end
    newest_mark_index, _ = Trails.get_newest_and_oldest_mark_index_for_buf(buf)
  end

  return newest_mark_index, last_mark, extracted_ext_mark
end

--- Find the newest and oldest trail mark in the stack that belongs to the given buffer.
---@param buf? number
---@return number?
---@return number?
function Trails.get_newest_and_oldest_mark_index_for_buf(buf)
  local max_time = 0
  local min_time = math.huge
  local newest_mark_index = nil
  local oldest_mark_index = nil

  for i, trail_mark in ipairs(Trails.trail_mark_stack) do
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

  return newest_mark_index or #Trails.trail_mark_stack, oldest_mark_index or 0
end

--- Get a mark selection depending on the current mark selection mode and the corresponding
--- relative current cursor position within it.
---@param buf? number
---@param current_mark_index? number
---@return table
---@return number
function Trails.get_relative_marks_and_cursor(buf, current_mark_index)
  local marks, cursor

  if buf then
    marks = vim.tbl_filter(function(mark)
      return mark.buf == buf
    end, Trails.trail_mark_stack)
    cursor = helpers.tbl_indexof(function(mark)
      return mark.buf == buf and Trails.trail_mark_stack[current_mark_index] and
          Trails.trail_mark_stack[current_mark_index].mark_id == mark.mark_id
    end, marks) or helpers.tbl_indexof(function(mark)
      return mark.buf == buf and Trails.trail_mark_stack[Trails.trail_mark_cursor] and
          mark.timestamp == Trails.trail_mark_stack[Trails.trail_mark_cursor].timestamp
    end, marks) or #marks
  else
    marks = Trails.trail_mark_stack
    cursor = Trails.trail_mark_cursor or #Trails.trail_mark_stack
  end

  return marks, cursor
end

--- Returns the corresponding highlight group for the provided or global trail mark selection mode.
---@param mode? string
---@return string
function Trails.get_hl_group_for_current_trail_mark_select_mode(mode)
  if mode == nil then
    mode = Trails.config.custom.current_trail_mark_mode
  end

  local hl_group = "TrailBlazerTrailMark" .. string.gsub(mode, "_%l", string.upper):gsub("_", "")
  if vim.tbl_contains(Trails.config.custom.available_trail_mark_modes, mode) then
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
function Trails.translate_actual_cursor_from_relative_marks_and_cursor(buf, marks, cursor)
  local newest_mark_index, _ = Trails.get_newest_and_oldest_mark_index_for_buf(buf)

  Trails.trail_mark_cursor = helpers.tbl_indexof(function(mark)
    return marks[cursor] and mark.timestamp == marks[cursor].timestamp
  end, Trails.trail_mark_stack) or newest_mark_index

  Trails.reregister_trail_marks()
end

--- Return the default buffer for the currently selected trail mark selection mode or the given
--- buffer if it is not nil.
---@param buf? number
---@return number?
function Trails.default_buf_for_current_mark_select_mode(buf)
  if buf == nil and (Trails.config.custom.current_trail_mark_mode == "buffer_local_chron" or
      Trails.config.custom.current_trail_mark_mode == "buffer_local_line_sorted") then
    buf = api.nvim_get_current_buf()
  end

  return buf
end

--- Remove duplicate trail marks from the stack.
function Trails.remove_duplicate_pos_trail_marks()
  local trail_count = #Trails.trail_mark_stack
  Trails.trail_mark_stack = helpers.dedupe(function(item, dedupe_tbl)
    return helpers.tbl_find(function(dedupe_item)
      return item.win == dedupe_item.win and item.buf == dedupe_item.buf and
          item.pos[1] == dedupe_item.pos[1] and item.pos[2] == dedupe_item.pos[2]
    end, dedupe_tbl) ~= nil
  end, Trails.trail_mark_stack, function(item)
    api.nvim_buf_del_extmark(item.buf, Trails.config.nsid, item.mark_id)
  end)
  if trail_count ~= #Trails.trail_mark_stack then
    Trails.trail_mark_cursor = #Trails.trail_mark_stack - 1
  end
end

--- Update the positions of all trail marks in the stack by loading all extmarks for each loaded
--- buffer and updating the trail mark stack.
function Trails.update_all_trail_mark_positions()
  local buf_list = helpers.tbl_flatmap(function(buf)
    return { [buf] = api.nvim_buf_line_count(buf) }
  end, vim.tbl_filter(function(buf)
    return api.nvim_buf_is_loaded(buf)
  end, api.nvim_list_bufs()), true)
  local ext_marks = helpers.tbl_flatmap(function(buf)
    return { [buf] = api.nvim_buf_get_extmarks(buf, Trails.config.nsid, 0, -1, {}) }
  end, vim.tbl_keys(buf_list), true)

  for _, trail_mark in ipairs(Trails.trail_mark_stack) do
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
function Trails.reregister_trail_marks()
  if #Trails.trail_mark_stack <= 0 then return end

  local ok, hl_group
  local newest_mark_index, _ = Trails.get_newest_and_oldest_mark_index_for_buf(
    Trails.default_buf_for_current_mark_select_mode(nil))
  local current_cursor_mark = Trails.trail_mark_stack[Trails.trail_mark_cursor] or
      Trails.trail_mark_stack[#Trails.trail_mark_stack]
  local special_marks = {}

  for i, mark in ipairs(Trails.trail_mark_stack) do
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
      hl_group = Trails.get_hl_group_for_current_trail_mark_select_mode()
    end

    if Trails.config.custom.number_line_color_enabled then
      mark_options["number_hl_group"] = hl_group .. "Inverted"
    end

    if Trails.config.custom.symbol_line_enabled then
      if special_marks[mark.buf] == nil then
        special_marks[mark.buf] = {}
      end

      if i == Trails.trail_mark_cursor + 1 then
        mark_options["sign_text"] = Trails.config.custom.next_mark_symbol
        mark_options["sign_hl_group"] = "TrailBlazerTrailMarkNext"
        table.insert(special_marks[mark.buf], mark.pos[1])
      elseif i == Trails.trail_mark_cursor - 1 then
        mark_options["sign_text"] = Trails.config.custom.previous_mark_symbol
        mark_options["sign_hl_group"] = "TrailBlazerTrailMarkPrevious"
        table.insert(special_marks[mark.buf], mark.pos[1])
      end

      if i == newest_mark_index then
        mark_options["sign_text"] = Trails.config.custom.newest_mark_symbol
        mark_options["sign_hl_group"] = hl_group .. "Inverted"
        table.insert(special_marks[mark.buf], mark.pos[1])
      end

      if current_cursor_mark and current_cursor_mark.pos[1] == mark.pos[1]
          and current_cursor_mark.pos[2] == mark.pos[2] then
        mark_options["sign_text"] = Trails.config.custom.cursor_mark_symbol
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

    pcall(api.nvim_buf_del_extmark, mark.buf, Trails.config.nsid, mark.mark_id)

    ok, mark.mark_id = pcall(api.nvim_buf_set_extmark, mark.buf, Trails.config.nsid,
      mark.pos[1] - 1, mark.pos[2], mark_options)

    if not ok then
      table.remove(Trails.trail_mark_stack, i)
    end
  end
end

return Trails
