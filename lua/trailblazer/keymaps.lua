---@author: Leon Heidelbach 11.01.2023
---@version: 1.0
---@license: MIT
---@tag keymaps
---@mod trailblazer.keymaps
---@brief [[
--- This module is responsible for setting up keymaps.
---@brief ]]

local api = vim.api
local Keymaps = {}
Keymaps.config = {
  default_map_opts = { noremap = true, silent = true }
}

function Keymaps.register(key_maps)
  for mode_label, mode_maps in pairs(key_maps) do
    for mode in mode_label:gmatch(".") do
      for _, map_type in pairs(mode_maps) do
        for callback, map in pairs(map_type) do
          local cmd = string.format("<cmd>lua require('trailblazer').%s()<CR>", callback)
          api.nvim_set_keymap(mode, map, cmd, Keymaps.config.default_map_opts)
        end
      end
    end
  end
end

return Keymaps
