---@author: Leon Heidelbach 31.01.2023
---@version: 1.0
---@license: GPLv3
---@tag storage
---@mod trailblazer.storage
---@brief [[
--- This module is responsible for managing TrailBlazer local storage and persistence.
---@brief ]]

local fn = vim.fn
local Storage = {}

local config = require("trailblazer.trails.config")
local log = require("trailblazer.log")
local helpers = require("trailblazer.helpers")
local stacks = require("trailblazer.trails.stacks")
local common = require("trailblazer.trails.common")
local actions = require("trailblazer.trails.actions")
local list = require("trailblazer.trails.list")

Storage.data_path = fn.stdpath("data")
Storage.trailblazer_storage_path = string.format("%s/trailblazer/", Storage.data_path)
Storage.save_suffix = ".tbsv"
Storage.trailblazer_cwd_storage = {}
Storage.trailblazer_cwd_storage.cwd = fn.getcwd()
Storage.trailblazer_cwd_storage.config = {}
Storage.trailblazer_cwd_storage.fb_lookup = {}
Storage.trailblazer_cwd_storage.stacks = {}

Storage.auto_load_ignored_files = {
  "COMMIT_EDITMSG",
  "MERGE_MSG",
  "NOTES_EDITMSG",
  "PULLREQ_EDITMSG",
  "TAG_EDITMSG",
}

--- Setup the storage module.
---@param options? table
function Storage.setup(options)
  if options then
    Storage.auto_load_trailblazer_state_on_enter = options.auto_load_trailblazer_state_on_enter

    if options.custom_session_storage_dir and fn.empty(options.custom_session_storage_dir) == 0 then
      Storage.trailblazer_storage_path = fn.fnamemodify(options.custom_session_storage_dir, ":p")
    end
  end
  Storage.ensure_storage_dir_exists()
end

function Storage.auto_load_session_check()
  if Storage.auto_load_trailblazer_state_on_enter then
    local is_auto_load_ignored_file = false

    for _, v in ipairs(vim.v.argv) do
      for _, w in ipairs(Storage.auto_load_ignored_files) do
        if v:find(w) then
          is_auto_load_ignored_file = true
          break
        end
      end
    end

    if not is_auto_load_ignored_file then Storage.load_trailblazer_state_from_file(nil, false) end
  end
end

--- Ensure that the storage directory exists. If no path is provided, the default path will be used.
---@param path? string
function Storage.ensure_storage_dir_exists(path)
  if not path or fn.empty(path) == 1 then path = Storage.trailblazer_storage_path end

  if helpers.is_file_path(path) then path = fn.fnamemodify(path, ":h") end

  if fn.isdirectory(path) == 0 then
    if fn.empty(path) == 0 then
      fn.mkdir(path, "p")
    else
      log.error("invalid_storage_path", "[" .. path .. "]")
    end
  end

  return path
end

--- Decode the raw input from the disk. This currently uses vim.fn.json_decode but could be replaced
--- with a custom implementation.
---@param input? string
---@return table?
function Storage.decode(input)
  local ok, trail_marks_from_disk = pcall(fn.json_decode, input)
  if not ok or trail_marks_from_disk == nil then return nil end
  return trail_marks_from_disk
end

--- Try to read the provided file from disk.
---@param path string
---@param verbose? boolean
---@return string?
function Storage.read_from_disk(path, verbose)
  local ok, file, file_contents

  if path and fn.filereadable(path) then
    ok, file = pcall(io.open, path, "r")

    if not ok or file == nil then
      if verbose then log.warn("could_not_open_file", path) end
      return nil
    end

    ok, file_contents = pcall(file.read, file, "*all")

    if not ok or file_contents == nil then
      if verbose then log.warn("could_not_read_file", path) end
      pcall(file.close, file)
      return nil
    end

    pcall(file.close, file)
    return file_contents
  end

  if verbose then log.warn("could_not_read_file", path) end

  return nil
end

--- Read the trail mark storage from disk.
---@param storage_dir? string
---@param name? string
---@param verbose? boolean
---@return string?
---@return string?
function Storage.read_trailblazer_state_file_from_disk(storage_dir, name, verbose)
  name = Storage.get_valid_file_name(name)
  if storage_dir and string.sub(storage_dir, -1) ~= "/" then storage_dir = storage_dir .. "/" end
  return name, Storage.read_from_disk(storage_dir .. name, verbose)
end

--- Restore trail mark stacks from disk.
---@param path? string
---@param verbose? boolean
function Storage.load_trailblazer_state_from_file(path, verbose)
  local name, content, new_buf_id_lookup
  local should_auto_save = true
  local valid_path = path and fn.empty(path) == 0
  local cwd = fn.getcwd()

  path = valid_path and fn.fnamemodify(path, ":p") or nil
  name = valid_path and fn.fnamemodify(path, ":t") or nil

  if fn.empty(name) == 1 then name = nil end

  path = Storage.ensure_storage_dir_exists(path)
  name, content = Storage.read_trailblazer_state_file_from_disk(path, name, verbose)

  if content ~= nil and fn.empty(content) == 0 then
    local trail_marks_storage = Storage.decode(content)

    if trail_marks_storage == nil and verbose then
      log.warn("could_not_decode_trail_mark_save_file", Storage.trailblazer_storage_path .. name)
      Storage.trailblazer_cwd_storage = {}
      return
    end

    if Storage.validate_save_file_content_integrity(trail_marks_storage) then
      Storage.trailblazer_cwd_storage = trail_marks_storage
    else
      log.warn("could_not_verify_trail_mark_save_file_integrity")
      Storage.trailblazer_cwd_storage = {}
      return
    end
  else
    Storage.trailblazer_cwd_storage = {}
    return
  end

  Storage.trailblazer_cwd_storage.stacks = Storage.trailblazer_cwd_storage.stacks or {}

  if Storage.trailblazer_cwd_storage.cwd ~= cwd and (verbose == nil or verbose) then
    should_auto_save = false
    log.warn("tb_save_cwd_mismatch", Storage.trailblazer_cwd_storage.cwd .. " -> " .. cwd)
  end

  stacks.add_stack()
  new_buf_id_lookup = stacks.udpate_buffer_ids_with_filename_lookup_table(
    Storage.trailblazer_cwd_storage.stacks, Storage.trailblazer_cwd_storage.fb_lookup,
    Storage.trailblazer_cwd_storage.cwd)
  helpers.tbl_deep_extend(stacks.trail_mark_stack_list, Storage.trailblazer_cwd_storage.stacks)


  if Storage.trailblazer_cwd_storage.config and type(Storage.trailblazer_cwd_storage.config)
      == "table" then
    if Storage.trailblazer_cwd_storage.config.trail_mark_cursor and
        type(Storage.trailblazer_cwd_storage.config.trail_mark_cursor) == "number" then
      stacks.trail_mark_cursor = Storage.trailblazer_cwd_storage.config.trail_mark_cursor
    end

    stacks.custom_ord_local_buf = new_buf_id_lookup[Storage.trailblazer_cwd_storage.config
    .custom_ord_local_buf]
    actions.set_trail_mark_select_mode(Storage.trailblazer_cwd_storage.config
    .current_trail_mark_mode, false)
    stacks.switch_current_stack(Storage.trailblazer_cwd_storage.config
    .current_trail_mark_stack_name, false, false)
    stacks.set_trail_mark_stack_sort_mode(Storage.trailblazer_cwd_storage.config
    .current_trail_mark_stack_sort_mode, false)
  end

  common.remove_duplicate_pos_trail_marks()
  common.sort_trail_mark_stack()
  common.reregister_trail_marks()
  common.focus_win_and_buf_by_trail_mark_index(nil, stacks.trail_mark_cursor, false)
  list.update_trail_mark_list()

  config.runtime.should_auto_save = should_auto_save
end

--- Encode the input to be written to disk. This currently uses vim.fn.json_encode but could be
--- replaced with a custom implementation.
---@param input? table
---@return string?
function Storage.encode(input)
  local ok, trail_marks_to_disk = pcall(fn.json_encode, input)
  if not ok or trail_marks_to_disk == nil then return nil end
  return trail_marks_to_disk
end

--- Write content to disk under the provided path.
---@param path? string
---@param content? string
---@param verbose? boolean
---@return boolean
function Storage.write_to_disk(path, content, verbose)
  if path and content then
    local ok, file = pcall(io.open, path, "w")

    if not ok or file == nil then
      if verbose then log.warn("could_not_open_file", path) end
      return false
    end

    ok = pcall(file.write, file, content)

    if not ok then
      if verbose then log.warn("could_not_write_to_file", path) end
      pcall(file.close, file)
      return false
    end

    pcall(file.close, file)
    return true
  end

  if verbose then
    log.warn("no_path_or_content_provided", "[" .. tostring(path) .. " | " ..
    tostring(content) .. "]")
  end

  return false
end

--- Write trail mark storage file to disk.
---@param storage_dir? string
---@param name? string
---@param content? string
---@param verbose? boolean
---@return boolean
function Storage.write_trail_mark_storage_file_to_disk(storage_dir, name, content, verbose)
  name = Storage.get_valid_file_name(name)
  if storage_dir and string.sub(storage_dir, -1) ~= "/" then storage_dir = storage_dir .. "/" end
  return Storage.write_to_disk(storage_dir .. name, content, verbose)
end

--- Save trail mark stacks to disk.
---@param path? string
---@param trail_mark_stacks? table
---@param verbose? boolean
function Storage.save_trailblazer_state_to_file(path, trail_mark_stacks, verbose)
  local name
  local valid_path = path and fn.empty(path) == 0

  path = valid_path and fn.fnamemodify(path, ":p") or nil
  name = valid_path and fn.fnamemodify(path, ":t") or nil

  if fn.empty(name) == 1 then name = nil end

  path = Storage.ensure_storage_dir_exists(path)

  if not trail_mark_stacks or type(trail_mark_stacks) ~= "table" then
    stacks.add_stack()
    trail_mark_stacks = stacks.trail_mark_stack_list or {}
  end

  Storage.trailblazer_cwd_storage.config = {
    custom_ord_local_buf = stacks.custom_ord_local_buf,
    trail_mark_cursor = stacks.trail_mark_cursor,
    current_trail_mark_stack_name = stacks.current_trail_mark_stack_name,
    current_trail_mark_mode = config.custom.current_trail_mark_mode,
    current_trail_mark_stack_sort_mode = config.custom.current_trail_mark_stack_sort_mode
  }

  Storage.trailblazer_cwd_storage.cwd = fn.getcwd()
  Storage.trailblazer_cwd_storage.fb_lookup = stacks.create_buf_file_lookup_table()
  Storage.trailblazer_cwd_storage.stacks = trail_mark_stacks

  local trail_mark_storage = Storage.encode(Storage.trailblazer_cwd_storage)

  if trail_mark_storage == nil and verbose then
    log.warn("could_not_encode_trail_mark_save_file", Storage.trailblazer_storage_path)
    return
  end

  Storage.write_trail_mark_storage_file_to_disk(path or Storage.trailblazer_storage_path, name,
    trail_mark_storage, true)

  config.runtime.should_auto_save = true
end

--- Returns a valid file name for the provided name. If no name is provided, the current working
--- directory will be used and hashed.
---@param name? string
---@return string
function Storage.get_valid_file_name(name)
  local cwd = fn.getcwd()

  if not name or fn.empty(name) == 1 or name == cwd then
    name = fn.sha256(cwd)
  end

  if name and string.sub(name, -#Storage.save_suffix) ~= Storage.save_suffix then
    name = name .. Storage.save_suffix
  end

  return name
end

--[[
{
    fb_lookup = {
        ["/path/to/file"] = <bufnr>,
    },
    cwd = "/path/to/cwd",
    stacks = {
      -- list of TrailMarkStacks
    },
    config = {
        -- current TrailBlazer state
    },
}
--]]
--- Validate the integrity of the provided save file content.
---@param cfg? table
---@param verbose? boolean
---@return boolean
function Storage.validate_save_file_content_integrity(cfg, verbose)
  if type(cfg) ~= "table" then return false end

  local ok, err = pcall(vim.validate, {
    fb_lookup = { cfg.fb_lookup, "table" },
    cwd = { cfg.cwd, "string" },
    stacks = { cfg.stacks, "table" },
    config = { cfg.config, "table" }
  })

  if not ok and verbose then
    log.warn("invalid_trailblazer_config", "[ " .. err .. " | " .. vim.inspect(cfg) .. " ]")
    return false
  end

  return ok and stacks.validate_trail_mark_stack_list_integrity(cfg.stacks, verbose)
end

return Storage
