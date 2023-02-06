---@author: Leon Heidelbach 29.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.stacks
---@mod trailblazer.trails.stacks
---@brief [[
--- This module is responsible for managing trail mark stacks.
---@brief ]]

local api = vim.api
local fn = vim.fn
local loop = vim.loop
local Stacks = {}

local config = require("trailblazer.trails.config")
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")

Stacks.trail_mark_cursor = 0
Stacks.ucid = 0
Stacks.current_trail_mark_stack = {}
Stacks.trail_mark_stack_list = {}

--- Setup TrailBlazer trail mark stacks.
---@param options? table
function Stacks.setup(options)
  Stacks.current_trail_mark_stack_name = config.custom.default_trail_mark_stacks[1] or "default"

  if options and options.default_trail_mark_stacks and
      type(options.default_trail_mark_stacks) == "table" then
    for _, name in ipairs(options.default_trail_mark_stacks) do
      Stacks.add_stack(name)
    end
  end
end

--- Pushes the current trail mark stack to the trail mark stack list under the given name.
---@param name? string
function Stacks.add_stack(name)
  if name == nil or fn.empty(name) == 1 then
    name = Stacks.current_trail_mark_stack_name or "default"
  end

  if Stacks.trail_mark_stack_list[name] == nil then
    Stacks.trail_mark_stack_list[name] = {
      created_at = loop.hrtime(),
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
---@param verbose? boolean
function Stacks.delete_stack(name, verbose)
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

  if verbose == nil or verbose then
    log.info("trail_mark_stack_deleted", name)
  end
end

--- Deletes all trail mark stacks.
function Stacks.delte_all_stacks()
  Stacks.trail_mark_stack_list = {}
  Stacks.switch_current_stack(nil, false)
end

--- Move the current trail mark stack to the next trail mark stack in the trail mark stack list
--- depending on the given sort mode.
---@param sort_mode? string
---@param verbose? boolean
function Stacks.switch_to_next_stack(sort_mode, verbose)
  if vim.tbl_count(Stacks.trail_mark_stack_list) <= 1 then
    if verbose == nil or verbose then
      log.info("no_next_trail_mark_stack")
    end
    return
  end

  sort_mode = Stacks.get_valid_sort_mode(sort_mode)

  local stack_names = Stacks.get_sorted_stack_names(sort_mode)
  local current_stack_index = helpers.tbl_indexof(function(name)
    return name == Stacks.current_trail_mark_stack_name
  end, stack_names)

  if current_stack_index == nil then
    current_stack_index = 1
  end

  Stacks.switch_current_stack(stack_names[current_stack_index >= #stack_names and 1
      or current_stack_index + 1])
end

--- Move the current trail mark stack to the previous trail mark stack in the trail mark stack list
---@param sort_mode? string
---@param verbose? boolean
function Stacks.switch_to_previous_stack(sort_mode, verbose)
  if vim.tbl_count(Stacks.trail_mark_stack_list) <= 1 then
    if verbose == nil or verbose then
      log.info("no_previous_trail_mark_stack")
    end
    return
  end

  sort_mode = Stacks.get_valid_sort_mode(sort_mode)

  local stack_names = Stacks.get_sorted_stack_names(sort_mode)
  local current_stack_index = helpers.tbl_indexof(function(name)
    return name == Stacks.current_trail_mark_stack_name
  end, stack_names)

  if current_stack_index == nil then
    current_stack_index = 1
  end

  Stacks.switch_current_stack(stack_names[current_stack_index <= 1 and #stack_names
      or current_stack_index - 1])
end

--- Switches the current trail mark stack to the trail mark stack under the given name.
---@param name? string
---@param save? boolean
---@param verbose? boolean
function Stacks.switch_current_stack(name, save, verbose)
  if name == nil or fn.empty(name) == 1 then
    name = Stacks.current_trail_mark_stack_name
  end

  if save == nil or save then
    Stacks.add_stack(Stacks.current_trail_mark_stack_name)
  end

  Stacks.current_trail_mark_stack_name = name

  if Stacks.trail_mark_stack_list[name] == nil then
    Stacks.trail_mark_stack_list[name] = {
      created_at = loop.hrtime(),
      stack = {}
    }
  end

  Stacks.current_trail_mark_stack = Stacks.trail_mark_stack_list[name].stack

  if verbose == nil or verbose then
    log.info("trail_mark_stack_switched", name)
  end
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
---@param verbose? boolean
---@return string
function Stacks.get_valid_sort_mode(sort_mode, verbose)
  if sort_mode == nil or fn.empty(sort_mode) == 1 then
    sort_mode = config.custom.current_trail_mark_stack_sort_mode
  end

  if not vim.tbl_contains(config.custom.available_trail_mark_stack_sort_modes, sort_mode) then
    sort_mode = config.custom.available_trail_mark_stack_sort_modes[1]
    if verbose == nil or verbose then
      log.warn("invalid_trail_mark_stack_sort_mode",
        table.concat(config.custom.available_trail_mark_stack_sort_modes, ", "))
    end
  end

  return sort_mode
end

--- Set the trail mark stack sort mode to the given mode or toggle between the available modes.
---@param sort_mode? string
---@param verbose? boolean
function Stacks.set_trail_mark_stack_sort_mode(sort_mode, verbose)
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
    if verbose == nil or verbose then
      log.warn("invalid_trail_mark_stack_sort_mode",
        table.concat(config.custom.available_trail_mark_stack_sort_modes, ", "))
    end
    return
  end

  if config.custom.verbose_trail_mark_select and (verbose == nil or verbose) then
    log.info("current_trail_mark_stack_sort_mode", config.custom.current_trail_mark_stack_sort_mode)
  end
end

--- Update the buffer ids in the trail mark stack list with the given lookup table.
---@param stack_list table
---@param lookup_tbl table
function Stacks.udpate_buffer_ids_with_filename_lookup_table(stack_list, lookup_tbl)
  local new_buf_id_lookup = {}

  for k, v in pairs(lookup_tbl) do
    local buf = fn.bufnr(k, true)

    if (buf == -1 or not api.nvim_buf_is_loaded(buf)) and fn.filereadable(k) == 1 then
      buf = api.nvim_create_buf(true, false)
      api.nvim_buf_set_name(buf, k)
      api.nvim_buf_call(buf, vim.cmd.edit)
      new_buf_id_lookup[v] = buf
    elseif api.nvim_buf_is_loaded(buf) then
      new_buf_id_lookup[v] = buf
    end
  end

  for _, stack in pairs(stack_list) do
    for i = #stack.stack, 1, -1 do
      if new_buf_id_lookup[stack.stack[i].buf] ~= nil then
        Stacks.ucid = Stacks.ucid + 1
        stack.stack[i].buf = new_buf_id_lookup[stack.stack[i].buf]
        stack.stack[i].mark_id = Stacks.ucid
      else
        table.remove(stack.stack, i)
      end
    end
  end

  Stacks.switch_current_stack(nil, false, false)
end

--- Create a table that maps buffer numbers to file names.
---@return table
function Stacks.create_buf_file_lookup_table()
  local file_buf_lookup_table = {}
  local unique_bufs = {}

  for _, stack in pairs(Stacks.trail_mark_stack_list) do
    for _, mark in ipairs(stack.stack) do
      unique_bufs[mark.buf] = true
    end
  end

  for _, buf in ipairs(vim.tbl_keys(unique_bufs)) do
    local buf_name = fn.fnamemodify(api.nvim_buf_get_name(buf), ":~:.")
    if buf_name ~= "" then
      file_buf_lookup_table[buf_name] = buf
    end
  end

  return file_buf_lookup_table
end

--[[
{
  ["stack_name"] = {
      created_at = <timestamp>,
      stack = {
          {
              win = <win_id>,
              buf = <bufnr>,
              mark_id = <mark_id>,
              pos = { <lnum>, <col> },
              timestamp = <number>, -- generated from vim.loop.hrtime
          }, ... -- more trail marks
      },
  }, ... -- more stacks
}
--]]
--- Validate the integrity of the given trail mark stack list.
---@param stack_list? table
---@param verbose? boolean
---@return boolean
function Stacks.validate_trail_mark_stack_list_integrity(stack_list, verbose)
  if not stack_list or type(stack_list) ~= "table" then
    if verbose then
      log.warn("invalid_trail_mark_stack_list", "[ - | " .. vim.inspect(stack_list) .. " ]")
    end
    return false
  end

  local ok, err

  for _, stack in pairs(stack_list) do
    if type(stack) ~= "table" then
      if verbose then
        log.warn("invalid_trail_mark_stack", "[ - | " .. vim.inspect(stack) .. " ]")
      end
      return false
    end

    ok, err = pcall(vim.validate, {
      created_at = { stack.created_at, "number" },
      stack = { stack.stack, "table" },
    })

    if not ok then
      if verbose then
        log.warn("invalid_trail_mark_stack", "[ " .. err .. " | " .. vim.inspect(stack) .. " ]")
      end
      return false
    end

    for _, mark in ipairs(stack.stack) do
      if type(mark) ~= "table" then
        if verbose then log.warn("invalid_trail_mark", "[ - | " .. vim.inspect(mark) .. " ]") end
        return false
      end

      ok, err = pcall(vim.validate, {
        win = { mark.win, "number" },
        buf = { mark.buf, "number" },
        mark_id = { mark.mark_id, "number" },
        pos = { mark.pos, "table" },
        timestamp = { mark.timestamp, "number" },
      })

      if not ok then
        if verbose then
          log.warn("invalid_trail_mark", "[ " .. err .. " | " .. vim.inspect(mark) .. " ]")
        end
        return false
      end

      ok, err = pcall(vim.validate, {
        lnum = { mark.pos[1], "number" },
        col = { mark.pos[2], "number" },
      })

      if not ok then
        if verbose then
          log.warn("invalid_trail_mark_pos", "[ " .. err .. " | " .. vim.inspect(mark.pos) .. " ]")
        end
        return false
      end
    end
  end

  return true
end

return Stacks
