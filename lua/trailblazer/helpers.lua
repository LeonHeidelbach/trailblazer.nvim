---@author: Leon Heidelbach 12.01.2023
---@version: 1.0
---@license: GPLv3
---@tag helpers
---@mod trailblazer.helpers
---@brief [[
--- This module is responsible for providing helper functions.
---@brief ]]

local api = vim.api
local fn = vim.fn
local log = require("trailblazer.log")
local Helpers = {}

--- Returns the buffer number of the supplied value. If the value is a number, it is assumed to be
--- a buffer number. If the value is a string, it is assumed to be a buffer name.
---@param input? string | number
---@return number?
function Helpers.get_buf_nr(input)
  if not input or fn.empty(input) == 1 then return nil end
  if type(tonumber(input)) == "number" then return tonumber(input) end
  local buf = api.nvim_call_function("bufnr", { input })
  if buf == -1 then
    log.error("invalid_buf_name")
    return nil
  end
  return buf
end

--- Returns a mapped and flattended table using the supplied predicate.
---@param lambda function
---@param tbl table
---@param flatten_by_key? boolean
---@return table
function Helpers.tbl_flatmap(lambda, tbl, flatten_by_key)
  local result = {}
  for _, v in ipairs(tbl) do
    local mapped = lambda(v)
    for k2, v2 in pairs(mapped) do
      if flatten_by_key then
        if result[k2] == nil then
          result[k2] = v2
        else
          log.error("duplicate_key_in_flatmap")
        end
      else
        table.insert(result, v2)
      end
    end
  end
  return result
end

--- Returns the first item in the supplied table that matches the supplied predicate.
---@param lambda function
---@param tbl table
---@return any?
function Helpers.tbl_find(lambda, tbl)
  for _, v in ipairs(tbl) do
    if lambda(v) then
      return v
    end
  end
  return nil
end

--- Returns the index of the first item in the supplied table that matches the supplied predicate.
---@param lambda function
---@param tbl table
---@return integer?
function Helpers.tbl_indexof(lambda, tbl)
  for i, v in ipairs(tbl) do
    if lambda(v) then
      return i
    end
  end
  return nil
end

--- Append the supplied src table to the given dst table.
---@param tbl_dst table
---@param tbl_src table
function Helpers.tbl_append(tbl_dst, tbl_src)
  for _, v in ipairs(tbl_src) do
    table.insert(tbl_dst, v)
  end
end

--- Prepend the supplied src table to the given dst table.
---@param tbl_dst table
---@param tbl_src table
function Helpers.tbl_prepend(tbl_dst, tbl_src)
  for _, v in ipairs(tbl_src) do
    table.insert(tbl_dst, 1, v)
  end
end

--- Returns a table containing the supplied table's values in reverse order.
---@param tbl table
---@return table
function Helpers.tbl_reverse(tbl)
  local result = {}
  for i = #tbl, 1, -1 do
    table.insert(result, tbl[i])
  end
  return result
end

--- Returns the number of items that match the supplied predicate.
---@param lambda function
---@param tbl table
---@return integer
function Helpers.tbl_count(lambda, tbl)
  local counter = 0
  for _, v in ipairs(tbl) do
    if lambda(v) then
      counter = counter + 1
    end
  end
  return counter
end

--- Returns the maximum value of the supplied table using the supplied predicate. If no predicate is
--- supplied, the table's values are used.
---@param tbl table
---@param lambda? function
---@return any?
function Helpers.tbl_max(tbl, lambda)
  local max = nil
  for _, v in ipairs(tbl) do
    local c_val = lambda and lambda(v) or v
    if max == nil or c_val > max then
      max = c_val
    end
  end
  return max
end

--- Returns the minimum value of the supplied table using the supplied predicate. If no predicate is
--- supplied, the table's values are used.
---@param tbl table
---@param lambda? function
---@return any?
function Helpers.tbl_min(tbl, lambda)
  local min = nil
  for _, v in ipairs(tbl) do
    local c_val = lambda and lambda(v) or v
    if min == nil or c_val < min then
      min = c_val
    end
  end
  return min
end

--- Remove duplicates from the supplied table using the supplied predicate and calling the
--- optionally supplied action on each duplicate.
---@param lambda function<any> @return function
---@param tbl table
---@param action? function
---@return table
function Helpers.dedupe(lambda, tbl, action)
  local res = {}
  for _, v in ipairs(tbl) do
    if not lambda(v, res) then
      table.insert(res, v)
    elseif action then
      action(v)
    end
  end
  return res
end

--- Returns the substring of s that starts at `i` and continues until `j` taking unicode and utf-8
--- double length chars into account.
---@param s string
---@param i number
---@param j number
---@return string
function Helpers.sub(s, i, j)
  local length = vim.str_utfindex(s)

  if i < 0 then i = i + length + 1 end
  if (j and j < 0) then j = j + length + 1 end

  local u = (i > 0) and i or 1
  local v = (j and j <= length) and j or length

  if (u > v) then return "" end

  local str = vim.str_byteindex(s, u - 1)
  local e = vim.str_byteindex(s, v)

  return s:sub(str + 1, e)
end

--- Returns the character and its byte width at the provided position. This function will return the
--- correct value as long as the character has a maximum width of 4 bytes as per the utf-8 standard.
---@param buf number
---@param pos table<number, number>
---@return string?
---@return number?
function Helpers.buf_get_utf8_char_at_pos(buf, pos)
  local line = api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1]
  if not line then return nil, nil end

  local col = vim.str_utfindex(line:sub(1, pos[2])) + 1

  local char
  local char_w = 1
  local i = 1

  while i <= #line do
    local byte = line:byte(i)

    if byte >= 240 then
      char = line:sub(i, i + 3)
      char_w = 4
      i = i + char_w
    elseif byte >= 225 then
      char = line:sub(i, i + 2)
      char_w = 3
      i = i + char_w
    elseif byte >= 192 then
      char = line:sub(i, i + 1)
      char_w = 2
      i = i + char_w
    else
      char = line:sub(i, i)
      char_w = 1
      i = i + char_w
    end

    if col == 1 then
      return char, char_w
    end

    col = col - 1
  end

  return "", char_w
end

--- Returns the absolute file path for the supplied buffer.
---@param buf number
---@return string
function Helpers.buf_get_absolute_file_path(buf)
  local ok, name = pcall(api.nvim_buf_get_name, buf)
  if not ok or name == "" then
    return "[No Name]"
  end
  return name
end

--- Returns the relative workspace file path for the supplied buffer.
---@param buf number
---@return string
function Helpers.buf_get_relative_file_path(buf)
  local file_path = Helpers.buf_get_absolute_file_path(buf)
  local workspace = fn.getcwd()
  local file_name = fn.fnamemodify(file_path, ":t")
  return file_path:gsub(workspace, ""):gsub(file_name, "") .. file_name
end

--- Extend tbl_base with tbl_extend.
---@param tbl_base? table
---@param tbl_extend? table
---@return table?
function Helpers.tbl_deep_extend(tbl_base, tbl_extend)
  if tbl_extend == nil then return tbl_base end
  if tbl_base == nil then return tbl_extend end
  if tbl_base == nil and tbl_extend == nil then return nil end

  for k, v in pairs(tbl_extend) do
    if type(v) == "table" then
      if tonumber(k) then
        table.insert(tbl_base, v)
      elseif type(tbl_base[k]) == "table" then
        Helpers.tbl_deep_extend(tbl_base[k], v)
      else
        tbl_base[k] = v
      end
    else
      if tonumber(k) then
        table.insert(tbl_base, v)
      else
        tbl_base[k] = v
      end
    end
  end

  return tbl_base
end

--- Returns true if the supplied path is a file path.
---@param path? string
---@return boolean
function Helpers.is_file_path(path)
  if not path then return false end
  return path:gsub("\\", "/"):match(".*/.*%.%w+$") ~= nil
end

--- Opens the supplied file path in a new buffer and optionally in the specified window and returns
--- the buffer id. If the window is not valid then a new window will be opened.
---@param file_path string
---@param win? number
---@param split_type? table
---@return number?
---@return number?
function Helpers.open_file(file_path, win, split_type)
  local expanded_path = fn.expand(file_path)
  local buf = fn.bufnr(expanded_path, true)

  if (buf == -1 or not api.nvim_buf_is_loaded(buf)) and fn.filereadable(expanded_path) == 1 then
    buf = api.nvim_create_buf(true, false)
    api.nvim_buf_set_name(buf, expanded_path)
    api.nvim_buf_call(buf, vim.cmd.edit)

    if win and buf then
      if not vim.tbl_contains(api.nvim_list_wins(), win) then
        vim.cmd(split_type or "vsplit")
        win = api.nvim_get_current_win()
      end

      if win ~= 0 then
        api.nvim_win_set_buf(win, buf)
      end
    end

    return win, buf
  elseif api.nvim_buf_is_loaded(buf) then
    return win, buf
  end

  return nil, nil
end

--- Returns the current time in milliseconds if no resolution is provided. The resolution will add
--- more precision to the returned time. The resolution parameter can be any multiple of 10
--- otherwise it will be set to 1.
---@param res? number
---@return number
function Helpers.time(res)
  if not res or res % 10 ~= 0 then res = 1 end
  local base_time = os.time() * 1000 * res
  local high_res_time = vim.loop.hrtime() / (1000000 / res)
  return math.floor(base_time + high_res_time)
end

--- Sets visual line selection for the supplied start and end lines.
---@param start_pos table<number, number>
---@param end_pos table<number, number>
function Helpers.set_visual_line_selection(start_pos, end_pos)
  if vim.fn.mode() == "v" then
    vim.cmd("normal! v")
  elseif vim.fn.mode() == "V" then
    vim.cmd("normal! V")
  end

  api.nvim_win_set_cursor(0, start_pos)
  vim.cmd("normal! V")
  api.nvim_win_set_cursor(0, end_pos)
end

--- Returns the signum of the supplied number.
function Helpers.signum(x)
  return x > 0 and 1 or x < 0 and -1 or 0
end

--- Returns the Manhattan Distance between the supplied points.
---@param a table<number, number>
---@param b table<number, number>
---@return number
function Helpers.manhattan_distance(a, b)
  return math.abs(a[1] - b[1]) + math.abs(a[2] - b[2])
end

--- Returns the absolute character distance between the supplied points in the specified buffer.
---@param buf? number
---@param a table<number, number>
---@param b table<number, number>
---@return number
function Helpers.buf_linear_character_distance(buf, a, b)
  if a[1] > b[1] then a, b = b, a end

  local lines = api.nvim_buf_get_lines(buf or 0, a[1], b[1] + 1, false)

  if #lines == 1 then
    return math.abs(a[2] - b[2])
  end

  local dist = 0

  for i = 1, #lines do
    if i == 1 then
      dist = dist + #lines[i] - a[2]
    elseif i == #lines then
      dist = dist + b[2]
    else
      dist = dist + #lines[i]
    end
  end

  return dist
end

return Helpers
