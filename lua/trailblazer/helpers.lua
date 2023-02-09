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

--- Returns the character at the provided position. This function will return the correct value as
--- long as the character has a maximum width of 4 bytes as per the utf-8 standard.
---@param buf number
---@param pos table<number, number>
---@return string?
function Helpers.buf_get_utf8_char_at_pos(buf, pos)
  local line = api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1]
  if not line then return nil end

  local col = vim.str_utfindex(line:sub(1, pos[2])) + 1

  local char
  local i = 1

  while i <= #line do
    local byte = line:byte(i)

    if byte >= 240 then
      char = line:sub(i, i + 3)
      i = i + 4
    elseif byte >= 225 then
      char = line:sub(i, i + 2)
      i = i + 3
    elseif byte >= 192 then
      char = line:sub(i, i + 1)
      i = i + 2
    else
      char = line:sub(i, i)
      i = i + 1
    end

    if col == 1 then
      return char
    end

    col = col - 1
  end

  return ""
end

--- Returns the absolute file path for the supplied buffer.
---@param buf number
---@return string
function Helpers.buf_get_absolute_file_path(buf)
  local name = api.nvim_buf_get_name(buf)
  if name == "" then
    return "[No Name]"
  end
  return name
end

--- Returns the relative workspace file path for the supplied buffer.
---@param buf number
---@return string
function Helpers.buf_get_relative_file_path(buf)
  local file_path = Helpers.buf_get_absolute_file_path(buf)
  local workspace = vim.fn.getcwd()
  local file_name = vim.fn.fnamemodify(file_path, ":t")
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
      if type(tbl_base[k]) == "table" then
        Helpers.tbl_deep_extend(tbl_base[k], v)
      else
        tbl_base[k] = v
      end
    else
      tbl_base[k] = v
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
---@param file_path any
---@param focus? boolean
---@param win? number
---@param win_opts? table
---@return number?
function Helpers.open_file(file_path, focus, win, win_opts)
  local expanded_path = fn.expand(file_path)
  local buf = fn.bufnr(expanded_path, true)

  if (buf == -1 or not api.nvim_buf_is_loaded(buf)) and fn.filereadable(expanded_path) == 1 then
    buf = api.nvim_create_buf(true, false)
    api.nvim_buf_set_name(buf, expanded_path)
    api.nvim_buf_call(buf, vim.cmd.edit)

    if win and buf then
      if not vim.tbl_contains(api.nvim_list_wins(), win) then
        win = api.nvim_open_win(buf, focus == true, win_opts or {
          width = math.floor(api.nvim_win_get_width(0) / 2),
          height = math.floor(api.nvim_win_get_height(0) / 2),
        })
      end

      if win ~= 0 then
        api.nvim_win_set_buf(win, buf)
      end
    end

    return buf
  elseif api.nvim_buf_is_loaded(buf) then
    return buf
  end

  return nil
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

return Helpers
