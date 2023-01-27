---@author: Leon Heidelbach 12.01.2023
---@version: 1.0
---@license: GPLv3
---@tag helpers
---@mod trailblazer.helpers
---@brief [[
--- This module is responsible for providing helper functions.
---@brief ]]

local api = vim.api
local log = require("trailblazer.log")
local Helpers = {}

--- Returns the buffer number of the supplied value. If the value is a number, it is assumed to be
--- a buffer number. If the value is a string, it is assumed to be a buffer name.
---@param input? string | number
---@return number?
function Helpers.get_buf_nr(input)
  if not input then return input end
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
---@return string
function Helpers.buf_get_utf8_char_at_pos(buf, pos)
  local line = api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1]
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
---@param buf any
---@return string
function Helpers.buf_get_relative_file_path(buf)
  local file_path = Helpers.buf_get_absolute_file_path(buf)
  local workspace = vim.fn.getcwd()
  local file_name = vim.fn.fnamemodify(file_path, ":t")
  return file_path:gsub(workspace, ""):gsub(file_name, "") .. file_name
end

return Helpers
