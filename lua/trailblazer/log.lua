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
    error = "TrailBlazer(ERROR):"
  }
}

Log.langs = {
  en = {
    errors = {
      not_configured = "TrailBlazer is not configured. Please call `require('trailblazer').setup()` first.",
      unsupported_lang = "Unsupported language. Please use one of the following: " ..
          table.concat(Log.config.available_langs, ", "),
    }
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

--- Log an error message.
---@param name string
function Log.error(name)
  api.nvim_err_writeln(Log.config.prefixes.error .. " " .. Log.current_lang.errors[name])
end

Log.setup(Log.config.default_lang)

return Log
