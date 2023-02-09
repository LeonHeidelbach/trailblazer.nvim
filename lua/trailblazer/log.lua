---@author: Leon Heidelbach 11.01.2023
---@version: 1.0
---@license: GPLv3
---@tag log
---@mod trailblazer.log
---@brief [[
--- This module is responsible for logging messages in a consistent way with support for multiple
--- languages.
---@brief ]]

local api = vim.api
local Log = {}

Log.config = {
  default_lang = "en",
  available_langs = {
    "en"
  },
  prefixes = {
    info = "TrailBlazer(INFO):",
    warn = "TrailBlazer(WARN):",
    error = "TrailBlazer(ERROR):"
  }
}

Log.langs = {
  en = {
    infos = {
      current_trail_mark_select_mode = "Current trail mark select mode: ",
      trail_mark_stack_deleted = "Trail mark stack deleted: ",
      trail_mark_stack_switched = "Trail mark stack switched to: ",
      no_next_trail_mark_stack = "No next trail mark stack available.",
      no_previous_trail_mark_stack = "No previous trail mark stack available.",
      current_trail_mark_stack_sort_mode = "Current trail mark stack sort mode: ",
    },
    warnings = {
      invalid_trail_mark_select_mode = "Invalid trail mark select mode. Please use one of the "
          .. "following: ",
      hl_group_does_not_exist = "Highlight group does not exist: ",
      invalid_trailblazer_api_callback = "Provided callback for your keymap could not be found in "
          .. "the TrailBlazer API. Callback is -> ",
      invalid_trailblazer_mod_callback_register = "Provided callback for your keymap registration "
          .. "could not be found in your module. [Callback | Module] is -> ",
      invalid_trailblazer_mod_callback_unregister = "Provided callback for your keymap "
          .. "unregistration could not be found in your module. [Callback | Module] is -> ",
      invalid_trailblazer_list_type = "Invalid TrailBlazer list type. Please use one of the "
          .. "following: ",
      invalid_trail_mark_stack_sort_mode = "Invalid trail mark stack sort mode. Please use one of "
          .. "the following: ",
      could_not_open_file = "Could not open file: ",
      could_not_read_file = "Could not read file: ",
      could_not_decode_trail_mark_save_file = "Could not decode trail mark save file: ",
      could_not_encode_trail_mark_save_file = "Could not encode trail mark save file: ",
      could_not_write_to_file = "Could not write to file: ",
      no_path_or_content_provided = "Could not write to file. No path or content provided " ..
          "[Path | Content] is -> ",
      tb_save_cwd_mismatch = "The working directory from the loaded trail mark save file does not "
          .. "match the current working directory. Trail marks might not be properly loaded. " ..
          "Auto-saving is disabled until you manually save this session. [Saved CWD | Current CWD] "
          .. "is -> ",
      could_not_verify_trail_mark_save_file_integrity = "Could not verify trail mark save file "
          .. "integrity. Trail marks have not been loaded.",
      invalid_trailblazer_config = "Invalid TrailBlazer config. Please make sure that the config "
          .. "is a valid table. [Error | Config] is -> ",
      invalid_trail_mark_stack_list = "Invalid trail mark stack list. Please make sure that the "
          .. "list is a valid table. [Error | Stack] is -> ",
      invalid_trail_mark_stack = "Invalid trail mark stack. Please make sure that the stack is a "
          .. "valid table. [Error | Stack] is -> ",
      invalid_trail_mark = "Invalid trail mark. Please make sure that the trail mark is a valid "
          .. "table. [Error | Trail Mark] is -> ",
      invalid_trail_mark_pos = "Invalid trail mark position. Please make sure that the position "
          .. "is a valid table. [Error | Position] is -> ",
    },
    errors = {
      not_configured = "TrailBlazer is not configured. Please call `require('trailblazer').setup()`"
          .. " first.",
      unsupported_lang = "Unsupported language. Please use one of the following: ",
      invalid_buf_name = "Invalid buffer name. The current buffer has been used instead.",
      invalid_pos_for_buf_lines = "Could not retrieve buffer lines for the current cursor position.",
      invalid_trail_mark_mode = "Invalid trail mark select mode. Please use one of the following: ",
      invalid_pos_for_new_trail_mark = "Invalid position for new trail mark. Please make sure that "
          .. "the cursor is on a valid position or you provide valid input values.",
      duplicate_key_in_flatmap = "Duplicate key in flatmap.",
      mark_id_mismatch = "Mark id mismatch. This should not happen.",
      invalid_storage_path = "Invalid storage path. Please make sure that the path is a valid "
          .. "non empty string [Path] is -> ",
    },
  }
}

Log.current_lang = {}

--- Set the current language if the specified language is supported.
---@param lang string
function Log.setup(lang)
  if vim.tbl_contains(vim.tbl_keys(Log.langs), lang) then
    Log.current_lang = Log.langs[lang]
    return
  end

  Log.error("unsupported_lang", table.concat(Log.config.available_langs, ", "))
end

--- Log an info message.
---@param name string
---@param additional_info? string
function Log.info(name, additional_info)
  api.nvim_notify(Log.config.prefixes.info .. " " .. Log.current_lang.infos[name] ..
    (additional_info and tostring(additional_info) or ""), 0, {})
end

--- Log a warning message.
---@param name string
---@param additional_info? string
function Log.warn(name, additional_info)
  api.nvim_err_writeln(Log.config.prefixes.warn .. " " .. Log.current_lang.warnings[name] ..
    (additional_info and tostring(additional_info) or ""))
end

--- Log an error message.
---@param name string
---@param additional_info? string
function Log.error(name, additional_info)
  error(Log.config.prefixes.error .. " " .. Log.current_lang.errors[name] ..
    (additional_info and tostring(additional_info) or ""))
end

Log.setup(Log.config.default_lang)

return Log
