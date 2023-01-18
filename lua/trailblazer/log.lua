---@author: Leon Heidelbach 11.01.2023
---@version: 1.0
---@license: MIT
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
    },
    warnings = {
      invalid_trail_mark_select_mode = "Invalid trail mark select mode. Please use one of the following: ",
      hl_group_does_not_exist = "Highlight group does not exist: ",
    },
    errors = {
      not_configured = "TrailBlazer is not configured. Please call `require('trailblazer').setup()` first.",
      unsupported_lang = "Unsupported language. Please use one of the following: " ..
          table.concat(Log.config.available_langs, ", "),
      invalid_buf_name = "Invalid buffer name. The current buffer has been used instead.",
      invalid_pos_for_buf_lines = "Could not retrieve buffer lines for the current cursor position.",
      invalid_trail_mark_mode = "Invalid trail mark select mode. Please use one of the following: ",
      duplicate_key_in_flatmap = "Duplicate key in flatmap.",
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

  Log.error("unsupported_lang")
end

--- Log an info message.
---@param name string
---@param additional_info? string
function Log.info(name, additional_info)
  api.nvim_notify(Log.config.prefixes.info .. " " .. Log.current_lang.infos[name] ..
    (tostring(additional_info) or ""), 0, {})
end

--- Log a warning message.
---@param name string
---@param additional_info? string
function Log.warn(name, additional_info)
  api.nvim_err_writeln(Log.config.prefixes.warn .. " " .. Log.current_lang.warnings[name] ..
    (tostring(additional_info) or ""))
end

--- Log an error message.
---@param name string
---@param additional_info? string
function Log.error(name, additional_info)
  error(Log.config.prefixes.error .. " " .. Log.current_lang.errors[name] ..
    (tostring(additional_info) or ""))
end

Log.setup(Log.config.default_lang)

return Log
