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
Trails.config.ns_name = "trailblazer"
Trails.config.ns_id = api.nvim_create_namespace(Trails.config.ns_name)

Trails.trail_mark_cursor = 0
Trails.trail_mark_stack = {}

--- Add a new trail mark to the stack.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
---@return table?
function Trails.new_trail_mark(win, buf, pos)
  if not win then
    win = api.nvim_get_current_win()
  end

  if not buf then
    buf = api.nvim_get_current_buf()
  end

  if not pos or not pos[1] or not pos[2] then
    pos = api.nvim_win_get_cursor(0)
  end

  local pos_text = api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1],
    false)[1]

  if not pos_text or not pos[1] or not pos[2] then
    log.error("invalid_pos_for_buf_lines")
    return nil
  end

  pos_text = pos_text:sub(pos[2] + 1, pos[2] + 1)

  local mark_id = api.nvim_buf_set_extmark(buf, Trails.config.ns_id, pos[1] - 1, pos[2], {
    virt_text = { { pos_text ~= "" and pos_text or " ", "TrailBlazerTrailMark" } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
  })

  table.insert(Trails.trail_mark_stack, { win = win, buf = buf, pos = pos, mark_id = mark_id })
  Trails.trail_mark_cursor = Trails.trail_mark_cursor + 1

  return Trails.trail_mark_stack[Trails.trail_mark_cursor]
end

--- Remove the last global or buffer local trail mark from the stack.
---@param buf? number
---@return boolean
function Trails.track_back(buf)
  local last_mark_index = Trails.get_newest_mark_index_for_buf(buf)

  if last_mark_index then
    local trail_mark, ext_mark
    last_mark_index, trail_mark, ext_mark = Trails.get_marks_for_trail_mark_index(buf, last_mark_index, true)
    if last_mark_index == nil or trail_mark == nil or ext_mark == nil then
      return false
    end

    Trails.focus_win_and_buf(trail_mark, ext_mark)
    api.nvim_buf_del_extmark(trail_mark.buf, Trails.config.ns_id, trail_mark.mark_id)

    Trails.trail_mark_cursor = #Trails.trail_mark_stack

    return true
  end

  return false
end

--- Peek move forward to the next trail mark.
---@param buf? number
---@return boolean
function Trails.peek_move_forward(buf)
  local current_mark_index, _ = Trails.get_trail_mark_under_cursor()

  if current_mark_index and current_mark_index == Trails.trail_mark_cursor then
    Trails.trail_mark_cursor = Trails.trail_mark_cursor + 1 <= #Trails.trail_mark_stack
        and Trails.trail_mark_cursor + 1 or #Trails.trail_mark_stack
  end

  return Trails.focus_win_and_buf_by_trail_mark_index(buf, Trails.trail_mark_cursor, false)
end

--- Peek move backward to the next trail mark.
---@param buf? number
---@return boolean
function Trails.peek_move_backward(buf)
  local current_mark_index, _ = Trails.get_trail_mark_under_cursor()

  if current_mark_index and current_mark_index == Trails.trail_mark_cursor then
    Trails.trail_mark_cursor = Trails.trail_mark_cursor > 1 and Trails.trail_mark_cursor - 1
        or #Trails.trail_mark_stack > 0 and 1 or 0
  end

  return Trails.focus_win_and_buf_by_trail_mark_index(buf, Trails.trail_mark_cursor, false)
end

--- Paste the selected register contents at the last trail mark of all or a specific buffer.
---@param buf? number
---@return boolean
function Trails.paste_at_last_trail_mark(buf)
  local last_mark_index = Trails.get_newest_mark_index_for_buf(buf)

  if last_mark_index then
    return Trails.paste_at_trail_mark(buf, last_mark_index)
  end

  return false
end

--- Paste the selected register contents at all trail marks of all or a specific buffer.
---@param buf any
function Trails.paste_at_all_trail_marks(buf)
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
  api.nvim_buf_del_extmark(trail_mark.buf, Trails.config.ns_id, trail_mark.mark_id)

  Trails.trail_mark_cursor = #Trails.trail_mark_stack

  return true
end

--- Delete all trail marks from the stack and all or a specific buffer.
---@param buf? number
function Trails.delete_all_trail_marks(buf)
  if buf == nil then
    for _, mark in ipairs(Trails.trail_mark_stack) do
      pcall(api.nvim_buf_del_extmark, mark.buf, Trails.config.ns_id, mark.mark_id)
      Trails.trail_mark_cursor = Trails.trail_mark_cursor - 1
    end

    Trails.trail_mark_cursor = Trails.trail_mark_cursor > 0 and Trails.trail_mark_cursor or 0
    Trails.trail_mark_stack = {}
  else
    local ext_marks = api.nvim_buf_get_extmarks(buf, Trails.config.ns_id, 0, -1, {})

    for _, ext_mark in ipairs(ext_marks) do
      pcall(api.nvim_buf_del_extmark, buf, Trails.config.ns_id, ext_mark[1])
    end

    Trails.trail_mark_stack = vim.tbl_filter(function(mark)
      return mark.buf ~= buf
    end, Trails.trail_mark_stack)

    Trails.trail_mark_cursor = #Trails.trail_mark_stack
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
---@param buf? any
---@param trail_mark_index any
---@param remove_trail_mark any
---@return boolean
function Trails.focus_win_and_buf_by_trail_mark_index(buf, trail_mark_index, remove_trail_mark)
  if trail_mark_index > 0 then
    local trail_mark, ext_mark
    trail_mark_index, trail_mark, ext_mark = Trails.get_marks_for_trail_mark_index(buf,
      trail_mark_index, remove_trail_mark)
    if trail_mark_index == nil or trail_mark == nil or ext_mark == nil then
      return false
    end

    return Trails.focus_win_and_buf(trail_mark, ext_mark)
  end

  return false
end

--- Return the trail mark and its index in the trail mark stack under the current cursor location.
---@return number?
---@return table?
function Trails.get_trail_mark_under_cursor()
  local trail_mark_index
  local current_cursor = api.nvim_win_get_cursor(0)
  local ext_marks = api.nvim_buf_get_extmarks(0, Trails.config.ns_id, 0, -1, {})

  local current_ext_mark = helpers.tbl_find(function(ext_mark)
    return ext_mark[2] + 1 == current_cursor[1] and ext_mark[3] == current_cursor[2]
  end, ext_marks)

  if current_ext_mark ~= nil then
    Trails.remove_duplicate_pos_trail_marks()
    trail_mark_index = helpers.tbl_indexof(function(trail_mark)
      return trail_mark.mark_id == current_ext_mark[1]
    end, Trails.trail_mark_stack)
  end

  if trail_mark_index ~= nil then
    Trails.trail_mark_stack[trail_mark_index].pos = current_cursor
    Trails.trail_mark_cursor = trail_mark_index
    Trails.reregister_trail_marks()
    return trail_mark_index, Trails.trail_mark_stack[trail_mark_index]
  end

  if Trails.clean_trail_mark_stack() > 0 then
    Trails.reregister_trail_marks()
    return Trails.trail_mark_cursor, Trails.trail_mark_stack[Trails.trail_mark_cursor]
  end

  return nil, nil
end

--- Return the trail mark at the given position as well as the corresponding extmark.
---@param buf? number
---@param last_mark_index? number
---@return number?
---@return table?
---@return table?
function Trails.get_marks_for_trail_mark_index(buf, last_mark_index, remove_trail_mark)
  local ok, extracted_ext_mark, last_mark

  while #Trails.trail_mark_stack > 0 do
    if last_mark_index then
      last_mark = Trails.trail_mark_stack[last_mark_index]

      if last_mark then
        ok, extracted_ext_mark, _ = pcall(api.nvim_buf_get_extmarks, last_mark.buf,
          Trails.config.ns_id, last_mark.mark_id, last_mark.mark_id, {})
      end

      if remove_trail_mark then
        table.remove(Trails.trail_mark_stack, last_mark_index)
      end

      if ok then break end
    else
      return nil, nil, nil
    end
    last_mark_index = Trails.get_newest_mark_index_for_buf(buf)
  end

  return last_mark_index, last_mark, extracted_ext_mark
end

--- Find the newest trail mark in the stack that belongs to the given buffer.
---@param buf? number
---@return number?
function Trails.get_newest_mark_index_for_buf(buf)
  if buf == nil then
    return #Trails.trail_mark_stack > 0 and #Trails.trail_mark_stack or nil
  end

  for i = #Trails.trail_mark_stack, 1, -1 do
    if Trails.trail_mark_stack[i].buf == buf then
      return i
    end
  end

  return nil
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
    api.nvim_buf_del_extmark(item.buf, Trails.config.ns_id, item.mark_id)
  end)
  if trail_count ~= #Trails.trail_mark_stack then
    Trails.trail_mark_cursor = #Trails.trail_mark_stack - 1
  end
end

--- Clean up the trail mark stack and remove all trail marks that are no longer valid.
---@return integer
function Trails.clean_trail_mark_stack()
  local current_buffer = api.nvim_get_current_buf()
  local ext_marks = api.nvim_buf_get_extmarks(0, Trails.config.ns_id, 0, -1, {})

  Trails.trail_mark_stack = vim.tbl_filter(function(trail_mark)
    return helpers.tbl_find(function(ext_mark)
      return current_buffer ~= trail_mark.win or ext_mark[1] == trail_mark.mark_id
    end, ext_marks) ~= nil
  end, Trails.trail_mark_stack)

  Trails.trail_mark_cursor = #Trails.trail_mark_stack
  return Trails.trail_mark_cursor
end

--- Reregister all trail marks on the stack. This function can be used to restore trail marks
--- after calling `vim.lsp.formatting` which currently causes extmarks to be moved out of the
--- buffer range.
function Trails.reregister_trail_marks()
  local ok
  for i, mark in ipairs(Trails.trail_mark_stack) do
    local pos_text = api.nvim_buf_get_lines(mark.buf, mark.pos[1] - 1, mark.pos[1], false)[1]
        :sub(mark.pos[2] + 1, mark.pos[2] + 1)

    pcall(api.nvim_buf_del_extmark, mark.buf, Trails.config.ns_id, mark.mark_id)

    ok, mark.mark_id, _ = pcall(api.nvim_buf_set_extmark, mark.buf, Trails.config.ns_id,
      mark.pos[1] - 1, mark.pos[2], {
      virt_text = { { pos_text ~= "" and pos_text or " ", "TrailBlazerTrailMark" } },
      virt_text_pos = "overlay",
      hl_mode = "combine",
    })

    if not ok then
      table.remove(Trails.trail_mark_stack, i)
    end
  end
end

return Trails
