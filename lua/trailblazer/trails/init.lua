---@author: Leon Heidelbach 10.01.2023
---@version: 1.0
---@license: GPLv3
---@tag trails.init
---@mod trailblazer.trails
---@brief [[
--- This module is responsible setting up the trails module.
---@brief ]]

local Trails = {}

Trails.config = require("trailblazer.trails.config")
Trails.common = require("trailblazer.trails.common")
Trails.stacks = require("trailblazer.trails.stacks")
Trails.storage = require("trailblazer.storage")
Trails.actions = require("trailblazer.trails.actions")
Trails.motions = require("trailblazer.trails.motions")
Trails.list = require("trailblazer.trails.list")

--- Setup the TrailBlazer trails module.
---@param options? table
function Trails.setup(options)
  Trails.config.setup(options)
  Trails.stacks.setup(Trails.config.custom)
  Trails.list.setup(options)
end

return Trails
