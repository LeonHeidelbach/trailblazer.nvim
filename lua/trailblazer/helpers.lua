---@author: Leon Heidelbach 12.01.2023
---@version: 1.0
---@license: MIT
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

return Helpers
