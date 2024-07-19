---@param str string
---@param start string
---@return boolean
local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local tracking = require("lua.control.tracking")
local flight = require("lua.control.flight")
local autopilot = require("lua.control.autopilot")

script.on_init(function()
  tracking.on_init()
  autopilot.on_init()
end)

script.on_event(
  defines.events.script_raised_built,
  ---@param e EventData.script_raised_built
  function(e) tracking.on_entity_created(e.entity) end
)
script.on_event(
  defines.events.on_built_entity,
  ---@param e EventData.on_built_entity
  function(e) tracking.on_entity_created(e.created_entity) end
)

script.on_event(defines.events.on_tick,
  ---@param e EventData.on_tick
  function(e)
    for id, plane_grounded_info in tracking.valid_pairs(global.planes["c5-galaxy-grounded"]) do
      autopilot.tick_plane(plane_grounded_info)

      flight.tick_plane(plane_grounded_info.entity, e.tick)

      -- Called last since it destroys and creates entities
      flight.tick_plane_grounded_takeoff(plane_grounded_info.entity)
    end
    for id, plane_flying_info in tracking.valid_pairs(global.planes["c5-galaxy-flying"]) do
      autopilot.tick_plane(plane_flying_info)

      flight.tick_plane(plane_flying_info.entity, e.tick)

      -- Called last since it destroys and creates entities
      flight.tick_plane_flying_shadow_landing(plane_flying_info.entity)
    end

    for _, player in pairs(game.connected_players) do
      autopilot.tick_player(player)

      -- Set correct military target flag
      if player.character then
        if player
            and player.driving
            and player.vehicle
            and starts_with(player.vehicle.name, "c5-galaxy-")
        then
          if player.vehicle.name == "c5-galaxy-grounded" then
            player.character.is_military_target = true
          elseif player.vehicle.name == "c5-galaxy-flying" then
            player.character.is_military_target = false
          end
        else
          player.character.is_military_target = true
        end
      end
    end
  end
)
script.on_event(defines.events.on_player_selected_area,
  ---@param e EventData.on_player_selected_area
  function(e)
    autopilot.on_player_selected_area(e)
  end
)
script.on_event(defines.events.on_player_reverse_selected_area,
  ---@param e EventData.on_player_reverse_selected_area
  function(e)
    autopilot.on_player_reverse_selected_area(e)
  end
)
