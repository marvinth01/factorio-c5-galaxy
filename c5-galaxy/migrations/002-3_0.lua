-- Migrate to new state

---@type table<string, table>
local player_selection = global.player_selection
global.player_selection = nil

---@type table<string, table<integer, table>>
local planes = global.planes
global.planes = nil

---@type State
global.state = {
  next_id = 0,
  plane_data = {},
  entity_to_plane_id = {},
  player_path_planning = {},
}

---@param entity LuaEntity
---@param autopilot_data AutopilotData|nil
local function register_plane(entity, autopilot_data)
  local plane_id = global.state.next_id
  global.state.next_id = global.state.next_id + 1
  log("Migrating " .. entity.name .. ", unit number " .. entity.unit_number .. ", plane id " .. plane_id)

  global.state.plane_data[plane_id] = {
    entity = entity,
    autopilot_data = autopilot_data,
  }
  global.state.entity_to_plane_id[entity.unit_number] = plane_id
end
for _, plane_info in pairs(planes["c5-galaxy-grounded"]) do
  ---@type LuaEntity
  local entity = plane_info.entity
  ---@type AutopilotData|nil
  local autopilot_data = plane_info.autopilot_data
  register_plane(entity, autopilot_data)
end
for _, plane_info in pairs(planes["c5-galaxy-flying"]) do
  ---@type LuaEntity
  local entity = plane_info.entity
  ---@type AutopilotData|nil
  local autopilot_data = plane_info.autopilot_data
  register_plane(entity, autopilot_data)
end

for player_name, path_planning_data in pairs(player_selection) do
  local player = game.players[player_name]
  ---@type LuaEntity
  local plane = path_planning_data.plane
  ---@type LuaEntity[]
  local queue = path_planning_data.queue
  global.state.player_path_planning[player.index] = {
    plane_id = global.state.entity_to_plane_id[plane.unit_number],
    markers = queue
  }
  log("Migrating player \"" .. player.name .. "\", player index " .. player.index)
end
