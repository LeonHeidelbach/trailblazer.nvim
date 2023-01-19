---@author: Leon Heidelbach 11.01.2023
---@version: 1.0
---@license: MIT
---@tag keymaps
---@mod trailblazer.keymaps
---@brief [[
--- This module is responsible for setting up keymaps.
---@brief ]]

local api = vim.api
local log = require("trailblazer.log")
local Keymaps = {}

Keymaps.config = {
  default_map_opts = { noremap = true, silent = true }
}

--- Check if callback function exists in the TrailBlazer API and register all mappings in the
--- supplied keymap table.
---@param key_maps table
---@param tb_api? table
function Keymaps.register(key_maps, tb_api)
  for mode_label, mode_maps in pairs(key_maps) do
    for mode in mode_label:gmatch(".") do
      for _, map_type in pairs(mode_maps) do
        for callback, map in pairs(map_type) do
          if not tb_api or tb_api and tb_api[callback] ~= nil then
            local cmd = string.format("<cmd>lua require('trailblazer').%s()<CR>", callback)
            api.nvim_set_keymap(mode, map, cmd, Keymaps.config.default_map_opts)
          else
            log.warn("invalid_trailblazer_api_callback", callback)
          end
        end
      end
    end
  end
end

return Keymaps
