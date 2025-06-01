local M = {}

local constants = require("lua.constants")
local state = require("lua.control.state")

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
  assert(plane.valid)
  assert(plane.name == name_from)
  local old_plane = plane
  assert(old_plane)
  state.suppress_registration = true
  local new_plane = plane.surface.create_entity {
    name = name_to,
    position = plane.position,
    direction = plane.direction,
    force = plane.force,
    create_build_effect_smoke = false,
    raise_built = true,
  }
  state.suppress_registration = false
  assert(new_plane)

  if old_plane.burner then
    assert(new_plane.burner)
    new_plane.burner.currently_burning = old_plane.burner.currently_burning
    new_plane.burner.remaining_burning_fuel = old_plane.burner.remaining_burning_fuel
  end
  copy_inventory(old_plane.get_inventory(defines.inventory.fuel), new_plane.get_inventory(defines.inventory.fuel))
  copy_inventory(old_plane.get_inventory(defines.inventory.car_trunk), new_plane.get_inventory(defines.inventory.car_trunk))

  new_plane.destructible = old_plane.destructible
  new_plane.operable = old_plane.operable
  new_plane.effectivity_modifier = old_plane.effectivity_modifier
  new_plane.consumption_modifier = old_plane.consumption_modifier
  new_plane.friction_modifier = old_plane.friction_modifier
  new_plane.speed = old_plane.speed
  new_plane.orientation = old_plane.orientation
  new_plane.riding_state = old_plane.riding_state
  new_plane.health = old_plane.health

  local driver = old_plane.get_driver()
  local passenger = old_plane.get_passenger()

  -- Move over the plane's information (e.g. autopilot data)
  local plane_id = storage.state.entity_to_plane_id[plane.unit_number]
  storage.state.plane_data[plane_id].entity = new_plane
  storage.state.entity_to_plane_id[new_plane.unit_number] = plane_id
  -- Deleting will be done on the next cleanup, no need to do it here
  --storage.state.entity_to_plane_id[old_plane.unit_number] = nil -- Hopefully doing this this early won't lead to problems

  old_plane.destroy { raise_destroy = true }
  new_plane.set_driver(driver)
  new_plane.set_passenger(passenger)
end

---@param plane LuaEntity
local function update_shadow(plane)
  if plane.prototype.name == "c5-galaxy-flying" then
    local pos = plane.position
    -- Shadow lags 1 frame behind, so we add the speed (conveniently in dist/tick)
    pos.x = pos.x + plane.speed * math.sin(plane.orientation * 2 * math.pi)
    pos.y = pos.y + plane.speed * -math.cos(plane.orientation * 2 * math.pi)

    local speed_above_takeoff = plane.speed - constants.takeoff_speed
    local height = constants.height_per_speed * speed_above_takeoff
    pos.x = pos.x + height * math.tan(30 / 180 * math.pi)
    local fadeout_height = constants.shadow_fadeout_height
    rendering.draw_animation {
      animation = "c5-galaxy-flying-shadow",
      surface = plane.surface,
      target = pos,
      render_layer = "smoke", -- Right below air-object
      tint = { 1, 1, 1, 0.5 * math.max(0.0, (fadeout_height - height) / fadeout_height) },
      animation_speed = 0,
      animation_offset = orientation_to_idx(plane.orientation, 128),
      time_to_live = 1,
    }
  end
end

---@param plane LuaEntity
---@param tick integer
function M.tick_plane(plane, tick)
  -- Backwards speed check
  local min_speed = -30 / (60 * 3.6)
  if plane.speed < min_speed then
    plane.speed = min_speed
  end

  -- Scan chunks
  if (plane.unit_number + tick) % 60 == 0 then
    plane.force.chart(plane.surface, {
      { x = plane.position.x - 128, y = plane.position.y - 128 },
      { x = plane.position.x + 128, y = plane.position.y + 128 },
    })
  end
end

---@param plane LuaEntity
function M.tick_plane_grounded_takeoff(plane)
  assert(plane.name == "c5-galaxy-grounded")
  if plane.speed == 0 then
    local tile = plane.surface.get_tile(plane.position)
    local cliff = plane.surface.find_entity("cliff", plane.position)
    if cliff or tile.collides_with("water_tile") then
      local driver = plane.get_driver()
      local passenger = plane.get_passenger()
      if driver and not driver.is_player() then driver.die() end
      if passenger and not passenger.is_player() then passenger.die() end
      plane.die()
      return
    end
  end

  -- This needs to be the last call in the function since the code before relies on the plane being grounded
  if plane.speed > constants.takeoff_speed then
    swap_plane_prototype("c5-galaxy-grounded", "c5-galaxy-flying", plane)
  end
end

---@param plane LuaEntity
function M.tick_plane_flying_landing_shadow(plane)
  update_shadow(plane)

  -- This needs to be the last call in the function since the code before relies on the plane flying
  if plane.speed < constants.takeoff_speed then
    swap_plane_prototype("c5-galaxy-flying", "c5-galaxy-grounded", plane)
  end
end

return M
