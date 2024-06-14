---@param str string
---@param start string
---@return boolean
local function starts_with(str, start)
  return str:sub(1, #start) == start
end

---@param orientation double
---@param n_idx uint
---@return number
local function orientation_to_idx(orientation, n_idx)
  local x = math.sin(orientation * math.pi * 2)
  local y = -math.cos(orientation * math.pi * 2)

  y = y / math.cos(math.pi / 4)

  local projected_orientation = math.atan2(x, -y) / (math.pi * 2)
  return math.floor(projected_orientation * n_idx + 0.5) % n_idx
end


---@param old LuaInventory?
---@param new LuaInventory?
local function copy_inventory(old, new)
  if not old then return end
  assert(new)
  assert(#new == #old)
  for i = 1, #old, 1 do
    new[i].set_stack(old[i])
  end
end

---@param name_from string
---@param name_to string
---@param plane LuaEntity
local function swap_plane_prototype(name_from, name_to, plane)
  assert(plane.name == name_from)
  local old = plane
  assert(old)
  local new = plane.surface.create_entity {
    name = name_to,
    position = plane.position,
    direction = plane.direction,
    force = plane.force,
    create_build_effect_smoke = false,
  }
  assert(new)

  if old.burner then
    assert(new.burner)
    new.burner.currently_burning = old.burner.currently_burning
    new.burner.remaining_burning_fuel = old.burner.remaining_burning_fuel
  end
  copy_inventory(old.get_inventory(defines.inventory.fuel), new.get_inventory(defines.inventory.fuel))
  copy_inventory(old.get_inventory(defines.inventory.car_trunk), new.get_inventory(defines.inventory.car_trunk))

  new.destructible = old.destructible
  new.operable = old.operable
  new.effectivity_modifier = old.effectivity_modifier
  new.consumption_modifier = old.consumption_modifier
  new.friction_modifier = old.friction_modifier
  new.speed = old.speed
  new.orientation = old.orientation
  new.riding_state = old.riding_state
  new.health = old.health

  local driver = old.get_driver()
  local passenger = old.get_passenger()
  old.destroy {}
  new.set_driver(driver)
  new.set_passenger(passenger)
end

---@param plane LuaEntity
local function update_shadow(plane)
  if plane.prototype.name == "c5-galaxy-flying" then
    local pos = plane.position
    -- Shadow lags 1 frame behind, so we add the speed (conveniently in dist/tick)
    pos.x = pos.x + plane.speed * math.sin(plane.orientation * 2 * math.pi)
    pos.y = pos.y + plane.speed * -math.cos(plane.orientation * 2 * math.pi)

    local kmh_above_takeoff = plane.speed * 60 * 3.6 - settings.global["takeoff-speed-kmh"].value
    local height = settings.global["height-per-kmh"].value * kmh_above_takeoff
    pos.x = pos.x + height * math.tan(30 / 180 * math.pi)
    local fadeout_height = settings.global["shadow-fadeout-height"].value
    rendering.draw_animation {
      animation = "c5-galaxy-flying-shadow",
      surface = plane.surface,
      target = pos,
      render_layer = "smoke", -- Right below air-object
      tint = { 1, 1, 1, 0.5 * math.max(0.0, (fadeout_height - height) / fadeout_height) },
      animation_speed = 0,
      animation_offset = orientation_to_idx(plane.orientation, 128),
      time_to_live = 2,
    }
  end
end

---@param plane LuaEntity
local function tick_plane(plane)
  -- Backwards speed check
  local min_speed = -30 / (60 * 3.6)
  if plane.speed < min_speed then
    plane.speed = min_speed
  end
end

---@param plane LuaEntity
local function tick_plane_grounded(plane)
  if plane.speed == 0 then
    local tile = plane.surface.get_tile(plane.position)
    local cliff = plane.surface.find_entity("cliff", plane.position)
    if cliff or tile.collides_with("water-tile") then
      local driver = plane.get_driver()
      local passenger = plane.get_passenger()
      if driver and not driver.is_player() then driver.die() end
      if passenger and not passenger.is_player() then passenger.die() end
      plane.die()
      return
    end
  end

  -- This needs to be the last call in the function since the code before relies on the plane being grounded
  if plane.speed * 60 * 3.6 > settings.global["takeoff-speed-kmh"].value then
    swap_plane_prototype("c5-galaxy-grounded", "c5-galaxy-flying", plane)
  end
end

---@param plane LuaEntity
local function tick_plane_flying(plane)
  update_shadow(plane)

  -- This needs to be the last call in the function since the code before relies on the plane flying
  if plane.speed * 60 * 3.6 < settings.global["takeoff-speed-kmh"].value then
    swap_plane_prototype("c5-galaxy-flying", "c5-galaxy-grounded", plane)
  end
end

script.on_event(
  defines.events.on_tick,
  ---@param e EventData.on_tick
  function(e)
    for _, player in pairs(game.connected_players) do
      if player
          and player.driving
          and player.vehicle
          and starts_with(player.vehicle.name, "c5-galaxy-")
      then
        tick_plane(player.vehicle)
        if player.vehicle.name == "c5-galaxy-grounded" then
          if player.character then
            player.character.is_military_target = true
          end
          tick_plane_grounded(player.vehicle)
        elseif player.vehicle.name == "c5-galaxy-flying" then
          if player.character then
            player.character.is_military_target = false
          end
          tick_plane_flying(player.vehicle)
        end
      else
        if player.character then
          player.character.is_military_target = true
        end
      end
    end
  end
)

script.on_event(
  defines.events.on_player_driving_changed_state,
  ---@param e EventData.on_player_driving_changed_state
  function(e)
    local player = game.get_player(e.player_index)
    if player and not player.driving then
      if e.entity.name == "c5-galaxy-flying" then
        local driver = e.entity.get_driver()
        local passenger = e.entity.get_passenger()
        if not driver and passenger then
          e.entity.set_driver(passenger)
        elseif not driver and not passenger then
          e.entity.die()
        end
      end
    end
  end
)
