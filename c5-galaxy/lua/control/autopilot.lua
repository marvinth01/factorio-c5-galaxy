local M = {}

local pathfinding = require("autopilot.pathfinding")
local pathfollowing = require("autopilot.pathfollowing")

---@class AutopilotData
---@field path_segments PathSegment[]

---@class SelectionState
---@field plane LuaEntity
---@field queue LuaEntity[]

function M.on_init()
  ---Maps player names to their selection state
  ---@type table<string, SelectionState>
  global.player_selection = {}
end

---@param info PlaneInfo
function M.tick_plane(info)
  if not info.autopilot_data then
    return
  end
  if #info.autopilot_data.path_segments == 0 then
    info.autopilot_data = nil
    return
  end
  local plane = info.entity
  local segment_riding_state = pathfollowing.follow(plane, info.autopilot_data.path_segments[1])
  if segment_riding_state then
    plane.riding_state = segment_riding_state
  else
    table.remove(info.autopilot_data.path_segments, 1)
  end

  local players_holding_controller = {}
  for _, player in pairs(game.players) do
    if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "c5-galaxy-controller" then
      table.insert(players_holding_controller, player)
    end
  end
  if #players_holding_controller > 0 then
    local color = { 31, 63, 255, 127 }
    for _, segment in pairs(info.autopilot_data.path_segments) do
      pathfinding.draw_segment(segment, color, info.entity.surface, players_holding_controller)
    end
  end
end

---@param player LuaPlayer
function M.tick_player(player)
  if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "c5-galaxy-controller" then
    -- Validate selection (check if marker entities might have been destroyed)
    local selection = global.player_selection[player.name]
    if selection then
      local valid = true
      if not selection.plane.valid then valid = false end
      for _, marker in ipairs(selection.queue) do
        if not marker.valid then valid = false end
      end
      if not valid then
        global.player_selection[player.name] = nil
        player.print({ "c5-galaxy.error-path-marker-destroyed" })
      end
    end

    -- Draw path currently being planned if player is holding a controller
    local selection = global.player_selection[player.name]
    if selection then
      local color = { 255, 31, 127, 127 }
      rendering.draw_circle {
        color = color,
        width = 15,
        radius = 10,
        target = selection.plane,
        surface = selection.plane.surface,
        time_to_live = 2,
        players = { player },
      }
      for i, marker in ipairs(selection.queue) do
        local prev = selection.queue[i - 1] or selection.plane
        rendering.draw_line {
          color = color,
          width = 15,
          from = prev,
          to = marker,
          surface = marker.surface,
          time_to_live = 2,
          players = { player },
        }
      end
    end
  end
end

---@param player LuaPlayer
---@param marker LuaEntity
local function add_marker(player, marker)
  local selection = global.player_selection[player.name]
  if not selection then
    player.print({ "c5-galaxy.error-no-plane-selected" })
    return
  end

  -- Checks
  if marker.name == "parking-marker"
      or marker.name == "taxi-marker"
      or marker.name == "takeoff-marker"
  then
    if #selection.queue > 0 and selection.queue[#selection.queue].name == "takeoff-marker" then
      player.print({ "c5-galaxy.error-invalid-after-takeoff-marker" })
      return
    end
  elseif marker.name == "landing-marker" then
    if #selection.queue == 0 or selection.queue[#selection.queue].name ~= "takeoff-marker" then
      player.print({ "c5-galaxy.error-landing-marker-only-after-takeoff-marker" })
      return
    end
  else
    assert(false, "Invalid marker type: " .. marker.name)
  end

  table.insert(selection.queue, marker)

  -- Check if path ready (should maybe be a gui action in the future)
  if marker.name == "parking-marker" then
    global.planes[selection.plane.name][selection.plane.unit_number].autopilot_data = {
      path_segments = pathfinding.pathfind(selection.queue)
    }
    global.player_selection[player.name] = nil
  end
end

---@param e EventData.on_player_selected_area
function M.on_player_selected_area(e)
  -- Make sure we are using the autopilot controller
  if e.item ~= "c5-galaxy-controller" then
    return
  end

  local player = game.players[e.player_index]

  local plane_count = 0
  local marker_count = 0
  local entity
  for _, curr_entity in ipairs(e.entities) do
    if curr_entity.name == "c5-galaxy-grounded" or curr_entity.name == "c5-galaxy-flying" then
      plane_count = plane_count + 1
      entity = curr_entity
      if plane_count > 1 then
        player.print({ "c5-galaxy.error-too-many-planes-selected" })
        return
      end
    elseif curr_entity.name == "parking-marker"
        or curr_entity.name == "taxi-marker"
        or curr_entity.name == "takeoff-marker"
        or curr_entity.name == "landing-marker"
    then
      if plane_count == 0 then
        marker_count = marker_count + 1
        entity = curr_entity
      end
    else
      assert(false, "Invalid selected entity: " .. curr_entity.name)
    end
  end
  if marker_count > 1 and plane_count == 0 then
    player.print({ "c5-galaxy.error-too-many-markers-selected" })
    return
  end
  if not entity then
    return
  end
  assert(plane_count == 1 or marker_count == 1)

  ---@cast entity LuaEntity

  if global.player_selection[player.name]
      and not global.player_selection[player.name].plane.valid then
    global.player_selection[player.name] = nil
  end

  if entity.name == "c5-galaxy-grounded" or entity.name == "c5-galaxy-flying" then
    global.player_selection[player.name] = { plane = entity, queue = {} }
  elseif entity.name == "parking-marker"
      or entity.name == "taxi-marker"
      or entity.name == "takeoff-marker"
      or entity.name == "landing-marker"
  then
    add_marker(player, entity)
  end
end

---@param e EventData.on_player_reverse_selected_area
function M.on_player_reverse_selected_area(e)
  -- Make sure we are using the autopilot controller
  if e.item ~= "c5-galaxy-controller" then
    return
  end

  local player = game.players[e.player_index]
  for _, entity in pairs(e.entities) do
    if entity.name == "c5-galaxy-grounded" or entity.name == "c5-galaxy-flying" then
      player.print({ "c5-galaxy.message-player-aborting-plane-path" })
      global.planes[entity.name][entity.unit_number].autopilot_data = nil
      if entity.name == "c5-galaxy-grounded" then
        entity.riding_state = {
          acceleration = defines.riding.acceleration.braking,
          direction = defines.riding.direction.straight,
        }
      elseif entity.name == "c5-galaxy-flying" then
        entity.riding_state = {
          acceleration = defines.riding.acceleration.nothing,
          direction = defines.riding.direction.straight,
        }
      else
        assert(false)
      end
    end
  end
end

return M
