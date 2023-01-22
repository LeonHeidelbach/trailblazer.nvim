---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: MIT
---@tag init
---@mod trailblazer.trails
---@brief [[
--- This module is responsible setting up the trails module.
---@brief ]]

local Trails = {}

Trails.config = require("trailblazer.trails.config")
Trails.common = require("trailblazer.trails.common")
Trails.actions = require("trailblazer.trails.actions")
Trails.motions = require("trailblazer.trails.motions")

--- Setup the TrailBlazer trails module.
---@param options? table
function Trails.setup(options)
  Trails.config.setup(options)
end

return Trails
