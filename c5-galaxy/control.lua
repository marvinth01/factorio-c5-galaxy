---@param str string
---@param start string
---@return boolean
local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local state = require("lua.control.state")
local flight = require("lua.control.flight")
local autopilot = require("lua.control.autopilot")

script.on_init(function()
  state.on_init()
end)

script.on_event(
  defines.events.script_raised_built,
  ---@param e EventData.script_raised_built
  function(e) state.on_entity_created(e.entity) end
)
script.on_event(
  defines.events.on_built_entity,
  ---@param e EventData.on_built_entity
  function(e) state.on_entity_created(e.created_entity) end
)

script.on_event(defines.events.on_tick,
  ---@param e EventData.on_tick
  function(e)
    state.cleanup()

    for plane_id, plane_data in pairs(global.state.plane_data) do
      assert(plane_data.entity.valid)

      local plane = plane_data.entity

      autopilot.tick_plane(plane_data)

      flight.tick_plane(plane, e.tick)

      -- These are called last since they destroy and create entities
      if plane.name == "c5-galaxy-grounded" then
        flight.tick_plane_grounded_takeoff(plane)
      elseif plane.name == "c5-galaxy-flying" then
        flight.tick_plane_flying_landing_shadow(plane)
      else
        assert(false, "Invalid plane entity name: " .. plane.name)
      end
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
