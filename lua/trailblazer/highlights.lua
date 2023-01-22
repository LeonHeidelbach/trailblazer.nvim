---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: MIT
---@tag highlights
---@mod trailblazer.highlights
---@brief [[
--- This module is responsible for generating and setting highlight groups used by TrailBlazer.
---
--->
--- ## Usage example
--- local hl_groups = {
---   trail_mark = {
---     name = 'TrailBlazerTrailMark',
---     def = {
---       guifg = "Black",
---       guibg = "Red",
---       gui = "bold",
---     }
---   },
---   trail_mark_2 = {
---     name = 'TrailBlazerTrailMark2',
---     def = {
---       link = 'TrailBlazerTrailMark',
---     }
---   }, ...
--- }
--- require("trailblazer.highlights").register(hl_groups)
---<
---@brief ]]

local helpers = require("trailblazer.helpers")
local Highlights = {}

--- Generate and register highlight groups. Returns the list of registered groups.
---@param user_table table<string, table<string, string>>
---@param generate_inverted? boolean
---@return table<string>
function Highlights.register(user_table, generate_inverted)
  local hl_group_keys = vim.tbl_keys(user_table)

  if generate_inverted then
    local inverted_user_table = Highlights.invert(user_table, true)
    local inverted_hl_groups = Highlights.generate_group_strings(inverted_user_table)
    Highlights.register_hl_groups(inverted_hl_groups)
    helpers.tbl_append(hl_group_keys, vim.tbl_keys(inverted_user_table))
  end

  local hl_groups = Highlights.generate_group_strings(user_table)
  Highlights.register_hl_groups(hl_groups)
  return hl_group_keys
end

--- Register highlight groups generated through `Highlights.generate_group_strings`.
---@param hl_groups table<string>
function Highlights.register_hl_groups(hl_groups)
  for _, hl_group in ipairs(hl_groups) do
    vim.cmd(hl_group)
  end
end

--- Generate FG/BG inverted highlight groups.
---@param hl_table table
---@param remove_bg? boolean
---@return table
function Highlights.invert(hl_table, remove_bg)
  local inverted = {}

  for name, hl in pairs(hl_table) do
    inverted[name .. "Inverted"] = {}
    local tmp = hl.guifg
    inverted[name .. "Inverted"].guifg = hl.guibg
    if not remove_bg then
      inverted[name .. "Inverted"].guibg = tmp
    end
  end

  return inverted
end

--- Generate a list of highlight group strings from a config table.
---@param hl_table table<string, table<string, string>>
---@return table<string>
function Highlights.generate_group_strings(hl_table)
  local hl_groups = {}

  for name, attrs in pairs(hl_table) do
    local hl_group = string.format("hi %s", Highlights.def_to_string(name, attrs))
    table.insert(hl_groups, hl_group)
  end

  return hl_groups
end

--- Stringify a single highlight definition.
---@param name string
---@param def table<string, string>
---@return string
function Highlights.def_to_string(name, def)
  local def_string = ""

  if def.link ~= nil then
    return string.format("link %s %s", name, def.link)
  end

  for key, value in pairs(def) do
    def_string = def_string .. string.format("%s=%s ", key, value)
  end

  return name .. " " .. string.gsub(def_string, "%s+$", "")
end

return Highlights
