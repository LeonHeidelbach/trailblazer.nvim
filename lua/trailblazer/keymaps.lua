---@author: Leon Heidelbach 11.01.2023
---@version: 1.0
---@license: MIT
---@tag keymaps
---@mod trailblazer.keymaps
---@brief [[
--- This module is responsible for setting up keymaps.
---@brief ]]

local log = require("trailblazer.log")
local Keymaps = {}

Keymaps.config = {
  default_map_opts = { noremap = true, silent = true }
}

--- Check if callback function exists in the TrailBlazer API and register all mappings in the
--- supplied keymap table.
---@param key_maps table
---@param tb_api? table
function Keymaps.register_api_maps(key_maps, tb_api)
  Keymaps.register_for_buf(key_maps, "trailblazer", tb_api, nil,
    function(_, callback)
      log.warn("invalid_trailblazer_api_callback", callback)
    end)
end

--- Check if callback function exists in the specified module and register all mappings in the
--- supplied keymap table.
---@param key_maps table
---@param mod_name string
---@param mod? table
---@param buf? number
---@param warn_callback? function
function Keymaps.register_for_buf(key_maps, mod_name, mod, buf, warn_callback)
  for mode_label, mode_maps in pairs(key_maps) do
    for mode in mode_label:gmatch(".") do
      for _, map_type in pairs(mode_maps) do
        for callback, map in pairs(map_type) do
          if not mod or mod and mod[callback] ~= nil then
            local cmd = string.format("<cmd>lua require('" .. mod_name .. "').%s()<CR>", callback)
            vim.keymap.set(mode, map, cmd, Keymaps.config.default_map_opts, buf)
          else
            if warn_callback then
              warn_callback(mod_name, callback)
            else
              log.warn("invalid_trailblazer_mod_callback", "[ " .. callback .. " | " .. mod_name
                .. " ]")
            end
          end
        end
      end
    end
  end
end

return Keymaps
