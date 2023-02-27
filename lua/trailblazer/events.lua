---@author: Leon Heidelbach 27.03.2023
---@version: 1.0
---@license: GPLv3
---@tag events
---@mod trailblazer.events
---@brief [[
--- This module is responsible for managing TrailBlazer events.
---@brief ]]

local api = vim.api
local Events = {}

Events.config = {}
Events.config.events = {
  TRAIL_MARK_STACK_SAVED = "TrailBlazerTrailMarkStackSaved",
  TRAIL_MARK_STACK_DELETED = "TrailBlazerTrailMarkStackDeleted",
  CURRENT_TRAIL_MARK_STACK_CHANGED = "TrailBlazerCurrentTrailMarkStackChanged",
  TRAIL_MARK_STACK_SORT_MODE_CHANGED = "TrailBlazerTrailMarkStackSortModeChanged"
}
Events.config.event_list = {}

--- Setup the events module.
---@param options? table
function Events.setup(options)
  if options and options.event_list then
    Events.config.event_list = options.event_list
  end
end

--- Dispatch the given event if it is in the event list.
---@param event_name? string
---@param data any
function Events.dispatch(event_name, data)
  if not event_name or not Events.config.event_list or not Events.is_registered(event_name) then
    return
  end
  api.nvim_exec_autocmds('User', { pattern = event_name, modeline = false, data = data })
end

--- Check if the given event is registered.
---@param event_name string
---@return boolean
function Events.is_registered(event_name)
  return vim.tbl_contains(Events.config.event_list, event_name)
end

return Events
