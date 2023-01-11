---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer.trails
---@brief [[
--- This module is responsible for managing trails.
---@brief ]]

local api = vim.api
local Trails = {}

Trails.config = {}
Trails.config.ns_name = "trailblazer"
Trails.config.ns_id = api.nvim_create_namespace(Trails.config.ns_name)

Trails.trail_mark_stack = {}

--- Add a new trail mark to the stack.
---@param win? number
---@param buf? number
---@param pos? table<number, number>
function Trails.new_trail_mark(win, buf, pos)
  if not win then
    win = api.nvim_get_current_win()
  end

  if not buf then
    buf = api.nvim_get_current_buf()
  end

  if not pos then
    pos = api.nvim_win_get_cursor(0)
  end

  local pos_text = api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1]
      :sub(pos[2] + 1, pos[2] + 1)

  local mark_id = api.nvim_buf_set_extmark(buf, Trails.config.ns_id, pos[1] - 1, pos[2], {
    virt_text = { { pos_text ~= "" and pos_text or " ", "TrailBlazerTrailMark" } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
  })

  table.insert(Trails.trail_mark_stack, { win = win, buf = buf, mark_id = mark_id })
end

--- Remove the last global or buffer local trail mark from the stack.
---@param buf? number
---@return boolean
function Trails.track_back(buf)
  local last_mark_index = Trails.get_last_mark_for_buf(buf)

  if last_mark_index then
    local ok, extracted_ext_mark, last_mark

    while not ok do
      last_mark_index = Trails.get_last_mark_for_buf(buf)
      if last_mark_index then
        last_mark = Trails.trail_mark_stack[last_mark_index]
        table.remove(Trails.trail_mark_stack, last_mark_index)
        ok, extracted_ext_mark, _ = pcall(api.nvim_buf_get_extmarks, last_mark.buf,
          Trails.config.ns_id, last_mark.mark_id, last_mark.mark_id, {})
      else
        return false
      end
    end

    ok, _ = pcall(api.nvim_set_current_win, last_mark.win)
    if not ok then
      api.nvim_set_current_win(0)
    end

    ok, _ = pcall(api.nvim_set_current_buf, last_mark.buf)
    if ok then
      api.nvim_win_set_cursor(0, { extracted_ext_mark[1][2] + 1, extracted_ext_mark[1][3] })
      api.nvim_buf_del_extmark(last_mark.buf, Trails.config.ns_id, last_mark.mark_id)
      return true
    end
  end

  return false
end

--- Find the last trail mark in the stack that belongs to the given buffer.
---@param buf? number
---@return number | nil
function Trails.get_last_mark_for_buf(buf)
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

return Trails
