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

Storage.data_path = vim.fn.stdpath("data")
Storage.trailblazer_storage_path = string.format("%s/trailblazer/", Storage.data_path)
Storage.trailblazer_cwd_storage = {}
Storage.trailblazer_cwd_storage.cwd = fn.getcwd()
Storage.trailblazer_cwd_storage.config = {}
Storage.trailblazer_cwd_storage.fb_lookup = {}
Storage.trailblazer_cwd_storage.stacks = {}

--- Setup the storage module.
---@param options? table
function Storage.setup(options)
  if options and options.custom_storage_path and fn.empty(options.custom_storage_path) == 0 then
    Storage.trailblazer_storage_path = options.custom_storage_path
  end
  Storage.ensure_storage_dir_exists()
end

--- Ensure that the storage directory exists. If no path is provided, the default path will be used.
---@param path? string
function Storage.ensure_storage_dir_exists(path)
  if not path or fn.empty(path) == 1 then path = Storage.trailblazer_storage_path end
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
  local ok, trail_marks_from_disk = pcall(vim.fn.json_decode, input)
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
---@param clear_fname? string
---@param verbose? boolean
---@return string?
---@return string?
function Storage.read_trailblazer_state_file_from_disk(storage_dir, clear_fname, verbose)
  local hashed_file_name = clear_fname and fn.sha256(clear_fname) or nil
  if storage_dir and string.sub(storage_dir, -1) ~= "/" then storage_dir = storage_dir .. "/" end
  return hashed_file_name, Storage.read_from_disk(storage_dir .. hashed_file_name, verbose)
end

--- Restore trail mark stacks from disk.
---@param path? string
---@param verbose? boolean
function Storage.load_trailblazer_state_from_file(path, verbose)
  path = Storage.ensure_storage_dir_exists(path)

  local name, content = Storage.read_trailblazer_state_file_from_disk(path, vim.fn.getcwd(), true)

  if content ~= nil and fn.empty(content) == 0 then
    local trail_marks_storage = Storage.decode(content)

    if trail_marks_storage == nil and verbose then
      log.warn("could_not_decode_trail_mark_save_file", Storage.trailblazer_storage_path .. name)
      Storage.trailblazer_cwd_storage = {}
      return
    end

    Storage.trailblazer_cwd_storage = trail_marks_storage
  else
    Storage.trailblazer_cwd_storage = {}
    return
  end

  Storage.trailblazer_cwd_storage.stacks = Storage.trailblazer_cwd_storage.stacks or {}

  stacks.add_stack()
  helpers.tbl_deep_extend(stacks.trail_mark_stack_list, Storage.trailblazer_cwd_storage.stacks)
  stacks.udpate_buffer_ids_with_filename_lookup_table(Storage.trailblazer_cwd_storage.fb_lookup)


  if Storage.trailblazer_cwd_storage.config and type(Storage.trailblazer_cwd_storage.config)
      == "table" then

    if Storage.trailblazer_cwd_storage.config.trail_mark_cursor and
        type(Storage.trailblazer_cwd_storage.config.trail_mark_cursor) == "number" then
      stacks.trail_mark_cursor = Storage.trailblazer_cwd_storage.config.trail_mark_cursor
    end

    actions.set_trail_mark_select_mode(Storage.trailblazer_cwd_storage.config
      .current_trail_mark_mode, false)
    stacks.switch_current_stack(Storage.trailblazer_cwd_storage.config
      .current_trail_mark_stack_name, false, false)
    stacks.set_trail_mark_stack_sort_mode(Storage.trailblazer_cwd_storage.config
      .current_trail_mark_stack_sort_mode, false)
  end

  common.reregister_trail_marks()
  list.update_trail_mark_list()
end

--- Encode the input to be written to disk. This currently uses vim.fn.json_encode but could be
--- replaced with a custom implementation.
---@param input? table
---@return string?
function Storage.encode(input)
  local ok, trail_marks_to_disk = pcall(vim.fn.json_encode, input)
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

  if verbose then log.warn("no_path_or_content_provided", "[" .. tostring(path) .. " | " ..
      tostring(content) .. "]")
  end

  return false
end

--- Write trail mark storage file to disk.
---@param storage_dir? string
---@param clear_fname? string
---@param content? string
---@param verbose? boolean
---@return boolean
function Storage.write_trail_mark_storage_file_to_disk(storage_dir, clear_fname, content, verbose)
  local hashed_file_name = clear_fname and fn.sha256(clear_fname) or nil
  if storage_dir and string.sub(storage_dir, -1) ~= "/" then storage_dir = storage_dir .. "/" end
  return Storage.write_to_disk(storage_dir .. hashed_file_name, content, verbose)
end

--- Save trail mark stacks to disk.
---@param path? string
---@param trail_mark_stacks? table
---@param verbose? boolean
function Storage.save_trailblazer_state_to_file(path, trail_mark_stacks, verbose)
  path = Storage.ensure_storage_dir_exists(path)

  if not trail_mark_stacks or type(trail_mark_stacks) ~= "table" then
    stacks.add_stack()
    trail_mark_stacks = stacks.trail_mark_stack_list or {}
  end

  Storage.trailblazer_cwd_storage.config = {
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

  Storage.write_trail_mark_storage_file_to_disk(
    path or Storage.trailblazer_storage_path, vim.fn.getcwd(), trail_mark_storage, true)
end

return Storage
