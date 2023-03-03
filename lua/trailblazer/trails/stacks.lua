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
local Stacks = {}

local config = require("trailblazer.trails.config")
local events = require("trailblazer.events")
local helpers = require("trailblazer.helpers")
local log = require("trailblazer.log")

Stacks.custom_ord_local_buf = nil
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
      created_at = helpers.time(),
      custom_ord_local_buf = Stacks.custom_ord_local_buf,
      stack = vim.deepcopy(Stacks.current_trail_mark_stack)
    }
  else
    Stacks.trail_mark_stack_list[name] = {
      created_at = Stacks.trail_mark_stack_list[name].created_at,
      custom_ord_local_buf = Stacks.custom_ord_local_buf,
      stack = vim.deepcopy(Stacks.current_trail_mark_stack)
    }
  end

  if events.is_registered(events.config.events.TRAIL_MARK_STACK_SAVED) then
    events.dispatch(events.config.events.TRAIL_MARK_STACK_SAVED, {
      added_stack = name,
      current_stack = Stacks.current_trail_mark_stack_name,
      available_stacks = Stacks.get_sorted_stack_names()
    })
  end
end

--- Deletes the trail mark stack under the given name or the current trail mark stack if no name
--- is supplied.
---@param name? string | table
---@param verbose? boolean
function Stacks.delete_stack(name, verbose)
  if name == nil or fn.empty(name) == 1 then
    name = Stacks.current_trail_mark_stack_name or "default"
  end

  if type(name) == "table" then
    for _, stack_name in ipairs(name) do
      Stacks.trail_mark_stack_list[stack_name] = nil
    end

    if vim.tbl_contains(name, Stacks.current_trail_mark_stack_name)
        and #Stacks.trail_mark_stack_list > 0 then
      Stacks.switch_to_previous_stack(nil, false, false)
    elseif #Stacks.trail_mark_stack_list == 0 then
      Stacks.switch_current_stack(config.custom.default_trail_mark_stacks[1] or "default", false,
        false)
    end

    name = table.concat(name, ", ")
  else
    Stacks.trail_mark_stack_list[name] = nil

    if name == Stacks.current_trail_mark_stack_name and #Stacks.trail_mark_stack_list > 0 then
      Stacks.switch_to_previous_stack(nil, false, false)
    else
      Stacks.switch_current_stack(config.custom.default_trail_mark_stacks[1] or "default", false,
        false)
    end
  end

  if events.is_registered(events.config.events.TRAIL_MARK_STACK_DELETED) then
    events.dispatch(events.config.events.TRAIL_MARK_STACK_DELETED, {
      deleted_stacks = { name },
      current_stack = Stacks.current_trail_mark_stack_name,
      available_stacks = Stacks.get_sorted_stack_names()
    })
  end

  if verbose == nil or verbose then
    log.info("trail_mark_stack_deleted", name)
  end
end

--- Deletes all trail mark stacks.
---@param verbose? boolean
function Stacks.delete_all_stacks(verbose)
  local evt_is_registered = events.is_registered(events.config.events.TRAIL_MARK_STACK_DELETED)
  local deleted_stacks = evt_is_registered and Stacks.get_sorted_stack_names() or nil

  Stacks.trail_mark_stack_list = {}
  Stacks.current_trail_mark_stack = {}
  Stacks.switch_current_stack(config.custom.default_trail_mark_stacks[1] or "default", verbose)

  if evt_is_registered then
    events.dispatch(events.config.events.TRAIL_MARK_STACK_DELETED, {
      deleted_stacks = deleted_stacks,
      current_stack = Stacks.current_trail_mark_stack_name,
      available_stacks = Stacks.get_sorted_stack_names()
    })
  end
end

--- Move the current trail mark stack to the next trail mark stack in the trail mark stack list
--- depending on the given sort mode.
---@param sort_mode? string
---@param save_current? boolean
---@param verbose? boolean
function Stacks.switch_to_next_stack(sort_mode, save_current, verbose)
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
  or current_stack_index + 1], save_current, verbose)
end

--- Move the current trail mark stack to the previous trail mark stack in the trail mark stack list
---@param sort_mode? string
---@param save_current? boolean
---@param verbose? boolean
function Stacks.switch_to_previous_stack(sort_mode, save_current, verbose)
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
  or current_stack_index - 1], save_current, verbose)
end

--- Switches the current trail mark stack to the trail mark stack under the given name.
---@param name? string
---@param save? boolean
---@param verbose? boolean
function Stacks.switch_current_stack(name, save, verbose)
  if name == nil or fn.empty(name) == 1 then
    name = Stacks.current_trail_mark_stack_name or "default"
  end

  if save == nil or save then
    Stacks.add_stack(Stacks.current_trail_mark_stack_name)
  end

  Stacks.current_trail_mark_stack_name = name

  if Stacks.trail_mark_stack_list[name] == nil then
    Stacks.trail_mark_stack_list[name] = {
      created_at = helpers.time(),
      custom_ord_local_buf = Stacks.custom_ord_local_buf,
      stack = {}
    }
  end

  Stacks.current_trail_mark_stack = Stacks.trail_mark_stack_list[name].stack
  Stacks.custom_ord_local_buf = Stacks.trail_mark_stack_list[name].custom_ord_local_buf

  if events.is_registered(events.config.events.CURRENT_TRAIL_MARK_STACK_CHANGED) then
    events.dispatch(events.config.events.CURRENT_TRAIL_MARK_STACK_CHANGED, {
      current_stack = name,
      available_stacks = Stacks.get_sorted_stack_names()
    })
  end

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

  if events.is_registered(events.config.events.TRAIL_MARK_STACK_SORT_MODE_CHANGED) then
    events.dispatch(events.config.events.TRAIL_MARK_STACK_SORT_MODE_CHANGED, {
      current_sort_mode = config.custom.current_trail_mark_stack_sort_mode,
      available_stacks = Stacks.get_sorted_stack_names()
    })
  end

  if config.custom.verbose_trail_mark_select and (verbose == nil or verbose) then
    log.info("current_trail_mark_stack_sort_mode", config.custom.current_trail_mark_stack_sort_mode)
  end
end

--- Update the buffer ids in the trail mark stack list with the given lookup table. This also
--- returns a new buffer id lookup table where the old buffer ids are the keys and the new buffer
--- ids are the values.
---@param stack_list table
---@param lookup_tbl table
---@param saved_cwd? string
---@return table
function Stacks.udpate_buffer_ids_with_filename_lookup_table(stack_list, lookup_tbl, saved_cwd)
  local new_buf_id_lookup = {}
  local is_windows = fn.has("win32") == 1
  local fp_sep = is_windows and "\\" or "/"
  local cwd_match = saved_cwd and fn.getcwd() == saved_cwd or nil

  for k, v in pairs(lookup_tbl) do
    local buf

    if cwd_match or string.match(k, "^[" .. fp_sep .. "~]") or
        (is_windows and string.match(k, "^%a+:")) then
      _, buf = helpers.open_file(k)
    elseif string.match(k, "^%a") then
      _, buf = helpers.open_file(saved_cwd .. fp_sep .. k)
    end

    if buf then new_buf_id_lookup[v] = buf end
  end

  for _, stack in pairs(stack_list) do
    stack.custom_ord_local_buf = new_buf_id_lookup[stack.custom_ord_local_buf]

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

  return new_buf_id_lookup
end

--- Create a table that maps buffer numbers to file names.
---@param buf_as_key? boolean
---@param stack_name_list? table
---@return table
function Stacks.create_buf_file_lookup_table(buf_as_key, stack_name_list)
  local is_windows = fn.has("win32") == 1
  local file_buf_lookup_table = {}
  local unique_bufs = {}

  if type(stack_name_list) == "table" then
    for _, stack_name in ipairs(stack_name_list) do
      if Stacks.trail_mark_stack_list[stack_name] then
        for _, mark in ipairs(Stacks.trail_mark_stack_list[stack_name].stack) do
          unique_bufs[mark.buf] = true
        end
      end
    end
  else
    for _, stack in pairs(Stacks.trail_mark_stack_list) do
      for _, mark in ipairs(stack.stack) do
        unique_bufs[mark.buf] = true
      end
    end
  end

  for _, buf in ipairs(vim.tbl_keys(unique_bufs)) do
    if api.nvim_buf_is_valid(buf) then
      local buf_name = fn.expand(api.nvim_buf_get_name(buf))
      if buf_name ~= "" then
        if is_windows then
          local drive_letter = string.match(buf_name, "^(%a+):")
          if drive_letter then
            buf_name = string.upper(drive_letter) .. string.sub(buf_name, #drive_letter + 2)
          end
        end

        if buf_as_key then
          file_buf_lookup_table[buf] = buf_name
        else
          file_buf_lookup_table[buf_name] = buf
        end
      end
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
              timestamp = <number>, -- generated from helpers.time()
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

  local ok, err, custom_ord_set

  for _, stack in pairs(stack_list) do
    if type(stack) ~= "table" then
      if verbose then
        log.warn("invalid_trail_mark_stack", "[ - | " .. vim.inspect(stack) .. " ]")
      end
      return false
    end

    ok, err = pcall(vim.validate, {
      created_at = { stack.created_at, "number" },
      custom_ord_local_buf = { stack.custom_ord_local_buf, { "number", "nil" } },
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
        custom_ord = { mark.custom_ord, { "number", "nil" } },
        timestamp = { mark.timestamp, "number" },
      })

      if not custom_ord_set and mark.custom_ord then
        table.insert(config.custom.available_trail_mark_modes, 1, "custom_ord")
        custom_ord_set = true
      end

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
