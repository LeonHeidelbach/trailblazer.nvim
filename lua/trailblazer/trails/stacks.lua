---@author: Leon Heidelbach 29.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.stacks
---@mod trailblazer.trails.stacks
---@brief [[
--- This module is responsible for managing trail mark stacks.
---@brief ]]

local fn = vim.fn
local Stacks = {}

local config = require("trailblazer.trails.config")
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")

Stacks.current_trail_mark_stack_name = "default"
Stacks.current_trail_mark_stack = {}

Stacks.trail_mark_stack_list = {}

--- Pushes the current trail mark stack to the trail mark stack list under the given name.
---@param name? string
function Stacks.add_stack(name)
  if name == nil or fn.empty(name) == 1 then
    name = "default"
  end

  if Stacks.trail_mark_stack_list[name] == nil then
    Stacks.trail_mark_stack_list[name] = {
      created_at = os.time(),
      stack = vim.deepcopy(Stacks.current_trail_mark_stack)
    }
  else
    Stacks.trail_mark_stack_list[name] = {
      created_at = Stacks.trail_mark_stack_list[name].created_at,
      stack = vim.deepcopy(Stacks.current_trail_mark_stack)
    }
  end
end

--- Deletes the trail mark stack under the given name or the current trail mark stack if no name
--- is supplied.
---@param name? string | table
function Stacks.delete_stack(name)
  if name == nil or fn.empty(name) == 1 then
    name = Stacks.current_trail_mark_stack_name
  end

  if type(name) == "table" then
    for _, stack_name in ipairs(name) do
      Stacks.trail_mark_stack_list[stack_name] = nil
    end

    if vim.tbl_contains(name, Stacks.current_trail_mark_stack_name) then
      Stacks.switch_current_stack(nil, false)
    end

    name = table.concat(name, ", ")
  else
    Stacks.trail_mark_stack_list[name] = nil

    if name == Stacks.current_trail_mark_stack_name then
      Stacks.switch_current_stack(nil, false)
    end
  end

  log.info("trail_mark_stack_deleted", name)
end

--- Deletes all trail mark stacks.
function Stacks.delte_all_stacks()
  Stacks.trail_mark_stack_list = {}
  Stacks.switch_current_stack(nil, false)
end

--- Move the current trail mark stack to the next trail mark stack in the trail mark stack list
--- depending on the given sort mode.
---@param sort_mode? string
function Stacks.switch_to_next_stack(sort_mode)
  if vim.tbl_count(Stacks.trail_mark_stack_list) <= 1 then
    log.info("no_next_trail_mark_stack")
    return
  end

  sort_mode = Stacks.get_valid_sort_mode(sort_mode)

  local stack_names = Stacks.get_sorted_stack_names(sort_mode)
  local current_stack_index = helpers.tbl_indexof(function(name)
    return name == Stacks.current_trail_mark_stack_name
  end, stack_names)

  Stacks.switch_current_stack(stack_names[current_stack_index >= #stack_names and 1
      or current_stack_index + 1])
end

--- Move the current trail mark stack to the previous trail mark stack in the trail mark stack list
---@param sort_mode? string
function Stacks.switch_to_previous_stack(sort_mode)
  if vim.tbl_count(Stacks.trail_mark_stack_list) <= 1 then
    log.info("no_previous_trail_mark_stack")
    return
  end

  sort_mode = Stacks.get_valid_sort_mode(sort_mode)

  local stack_names = Stacks.get_sorted_stack_names(sort_mode)
  local current_stack_index = helpers.tbl_indexof(function(name)
    return name == Stacks.current_trail_mark_stack_name
  end, stack_names)

  Stacks.switch_current_stack(stack_names[current_stack_index <= 1 and #stack_names
      or current_stack_index - 1])
end

--- Switches the current trail mark stack to the trail mark stack under the given name.
---@param name? string
---@param save? boolean
function Stacks.switch_current_stack(name, save)
  if name == nil or fn.empty(name) == 1 then
    name = "default"
  end

  if save == nil or save then
    Stacks.add_stack(Stacks.current_trail_mark_stack_name)
  end

  Stacks.current_trail_mark_stack_name = name

  if Stacks.trail_mark_stack_list[name] == nil then
    Stacks.trail_mark_stack_list[name] = {
      created_at = os.time(),
      stack = {}
    }
  end

  Stacks.current_trail_mark_stack = Stacks.trail_mark_stack_list[name].stack

  log.info("trail_mark_stack_switched", name)
end

--- Returns a table of all trail mark stack names sorted by the given sort mode.
---@param sort_mode? string
---@return table<string>
function Stacks.get_sorted_stack_names(sort_mode)
  sort_mode = Stacks.get_valid_sort_mode(sort_mode)

  local stack_names = vim.tbl_keys(Stacks.trail_mark_stack_list)

  if sort_mode == "alpha_asc" then
    table.sort(stack_names, function(a, b) return a < b end)
  elseif sort_mode == "alpha_dsc" then
    table.sort(stack_names, function(a, b) return a > b end)
  elseif sort_mode == "chron_asc" then
    table.sort(stack_names, function(a, b)
      return Stacks.trail_mark_stack_list[a].created_at < Stacks.trail_mark_stack_list[b].created_at
    end)
  elseif sort_mode == "chron_dsc" then
    table.sort(stack_names, function(a, b)
      return Stacks.trail_mark_stack_list[a].created_at > Stacks.trail_mark_stack_list[b].created_at
    end)
  end

  return stack_names
end

--- Returns a valid sort mode for the given input.
---@param sort_mode? string
---@return string
function Stacks.get_valid_sort_mode(sort_mode)
  if sort_mode == nil or fn.empty(sort_mode) == 1 then
    sort_mode = config.custom.current_trail_mark_stack_sort_mode
  end

  if not vim.tbl_contains(config.custom.available_trail_mark_stack_sort_modes, sort_mode) then
    sort_mode = config.custom.available_trail_mark_stack_sort_modes[1]
    log.warn("invalid_trail_mark_stack_sort_mode",
      table.concat(config.custom.available_trail_mark_stack_sort_modes, ", "))
  end

  return sort_mode
end

--- Set the trail mark stack sort mode to the given mode or toggle between the available modes.
---@param sort_mode? string
function Stacks.set_trail_mark_stack_sort_mode(sort_mode)
  if sort_mode == nil then
    config.custom.current_trail_mark_stack_sort_mode = config.custom
        .available_trail_mark_stack_sort_modes[
        (helpers.tbl_indexof(function(available_mode)
          return available_mode == config.custom.current_trail_mark_stack_sort_mode
        end, config.custom.available_trail_mark_stack_sort_modes)) %
            #config.custom.available_trail_mark_stack_sort_modes + 1
        ]
  elseif vim.tbl_contains(config.custom.available_trail_mark_stack_sort_modes, sort_mode) then
    config.custom.current_trail_mark_stack_sort_mode = sort_mode
  else
    log.warn("invalid_trail_mark_stack_sort_mode",
      table.concat(config.custom.available_trail_mark_stack_sort_modes, ", "))
    return
  end

  if config.custom.verbose_trail_mark_select then
    log.info("current_trail_mark_stack_sort_mode", config.custom.current_trail_mark_stack_sort_mode)
  end
end

return Stacks
