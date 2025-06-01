local M = {}

---@class State
---@field next_id uint
---@field plane_data table<uint, PlaneData>
---@field entity_to_plane_id table<uint, uint>
---@field player_path_planning table<uint, PathPlanningState|nil>

---@class PlaneData
---@field entity LuaEntity
---@field autopilot_data? AutopilotData

---@class PathPlanningState
---@field plane_id uint
---@field markers LuaEntity[]

function M.on_init()
  ---@type State
  storage.state = {
    next_id = 0,
    plane_data = {},
    entity_to_plane_id = {},
    player_path_planning = {},
  }
end

---@return uint
function M.new_id()
  local id = storage.state.next_id
  storage.state.next_id = storage.state.next_id + 1
  return id
end

-- Temporarily enabled during prototype swapping
M.suppress_registration = false

---@param plane LuaEntity
function M.register_plane(plane)
  assert(storage.state.entity_to_plane_id[plane.unit_number] == nil)
  if not M.suppress_registration then
    local plane_id = M.new_id()
    storage.state.plane_data[plane_id] = { entity = plane, autopilot_data = nil }
    storage.state.entity_to_plane_id[plane.unit_number] = plane_id
  end
end

---Cleans up the state, removing non-existent entities
function M.cleanup()
  for plane_id, plane_data in pairs(storage.state.plane_data) do
    if not plane_data.entity.valid then
      storage.state.plane_data[plane_id] = nil
    end
  end
  for unit_number, plane_id in pairs(storage.state.entity_to_plane_id) do
    local plane_data = storage.state.plane_data[plane_id]
    if plane_data then
      local plane = plane_data.entity
      if not (plane.valid and plane.unit_number == unit_number) then
        storage.state.entity_to_plane_id[unit_number] = nil
      end
    else
      storage.state.entity_to_plane_id[unit_number] = nil
    end
  end
end

---@param entity LuaEntity
function M.on_entity_created(entity)
  if entity.name == "c5-galaxy-grounded" or entity.name == "c5-galaxy-flying" then
    M.register_plane(entity)
  end
end

return M
