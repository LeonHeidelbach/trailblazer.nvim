---@author: Leon Heidelbach 22.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer.trails.config
---@brief [[
--- This module is responsible for managing the configuration of TrailBlazer trails.
---@brief ]]

local api = vim.api
local Config = {}

Config.custom = {}
Config.custom.available_trail_mark_modes = {
  "global_chron",
  "global_buf_line_sorted",
  "global_chron_buf_line_sorted",
  "global_chron_buf_switch_group_chron",
  "global_chron_buf_switch_group_line_sorted",
  "buffer_local_chron",
  "buffer_local_line_sorted"
}
Config.custom.current_trail_mark_mode = "global_chron"
Config.custom.verbose_trail_mark_select = true
Config.custom.newest_mark_symbol = "⬤"
Config.custom.cursor_mark_symbol = "⬤"
Config.custom.next_mark_symbol = "⬤"
Config.custom.previous_mark_symbol = "⬤"
Config.custom.multiple_mark_symbol_counters_enabled = true
Config.custom.number_line_color_enabled = true
Config.custom.symbol_line_enabled = true

Config.ns_name = "trailblazer"
Config.ucid = 0
Config.nsid = api.nvim_create_namespace(Config.ns_name)

--- Setup the TrailBlazer config module.
---@param options? table
function Config.setup(options)
  if options then
    Config.custom = vim.tbl_deep_extend("force", Config.custom, options)
  end
end

return Config