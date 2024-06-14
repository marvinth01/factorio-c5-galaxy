---@param grounded boolean
---@return data.CarPrototype
local function make_plane(grounded)
  local plane = table.deepcopy(data.raw["car"]["car"])

  if not grounded then
    table.insert(plane.flags, "no-automated-item-insertion")
    table.insert(plane.flags, "no-automated-item-removal")
  end

  if grounded then
    plane.name = "c5-galaxy-grounded"
    plane.collision_mask = { "player-layer", "train-layer" }
    plane.terrain_friction_modifier = 1.0
    plane.braking_power = "5MW"
  else
    plane.name = "c5-galaxy-flying"
    plane.collision_mask = {}
    plane.terrain_friction_modifier = 0.0
    plane.braking_power = "32MW"
    plane.selection_priority = 51
    plane.trigger_target_mask = { "high-altitude-unit" }
  end
  plane.consumption = "12MW"
  plane.effectivity = 0.8
  plane.friction = 0.00025
  plane.is_military_target = grounded
  plane.max_health = 5000
  plane.minable = { mining_time = 3.0, result = "c5-galaxy" }
  plane.rotation_speed = 0.003
  plane.weight = 60000
  plane.energy_per_hit_point = 4.0
  plane.inventory_size = 960
  plane.burner = {
    fuel_category = "chemical",
    effectivity = 1,
    fuel_inventory_size = 8,
  }
  plane.has_belt_immunity = true

  plane.immune_to_tree_impacts = false
  plane.immune_to_rock_impacts = false
  plane.immune_to_cliff_impacts = false
  plane.collision_box = { { -3.0, -8.5 }, { 3.0, 8.5 } }
  plane.selection_box = { { -3.0, -8.5 }, { 3.0, 8.5 } }

  if grounded then
    plane.resistances = {
      {
        type = "fire",
        decrease = 15,
        percent = 60,
      },
      {
        type = "physical",
        decrease = 15,
        percent = 50,
      },
      {
        type = "impact",
        decrease = 20,
        percent = 30,
      },
      {
        type = "explosion",
        decrease = 15,
        percent = 40,
      },
      {
        type = "acid",
        decrease = 0,
        percent = 70,
      }
    }
  else
    plane.resistances = {
      {
        type = "fire",
        percent = 100,
      },
      {
        type = "physical",
        percent = 100,
      },
      {
        type = "impact",
        percent = 100,
      },
      {
        type = "explosion",
        percent = 100,
      },
      {
        type = "acid",
        percent = 100,
      }
    }
  end

  plane.water_reflection = nil
  plane.render_layer = "air-object"
  plane.animation = {
    layers = {
      {
        -- TODO: HR version
        filename = "__c5-galaxy__/graphics/sprites-flying-color.png",
        size = 512,
        frame_count = 1,
        direction_count = 128,
        line_length = 16,
        scale = 2.5,
      },
      {
        -- TODO: HR version
        filename = "__c5-galaxy__/graphics/sprites-flying-shadow.png",
        draw_as_shadow = true,
        size = 512,
        frame_count = 1,
        direction_count = 128,
        line_length = 16,
        scale = 2.5,
      },
    }
  }
  plane.sound_scaling_ratio = 0.4
  plane.working_sound = {
    sound = { filename = "__c5-galaxy__/sounds/jet-loop-0_5.ogg", volume = 0.3 },
    --activate_sound = { filename = "__c5-galaxy__/sounds/jet-start.ogg", volume = 0.3 },
    deactivate_sound = { filename = "__c5-galaxy__/sounds/jet-stop-0_5.ogg", volume = 0.3 },
    match_speed_to_activity = true,
    fade_in_ticks = 30,
  }

  plane.light_animation = nil
  plane.icon = "__c5-galaxy__/graphics/icon.png"
  plane.icon_size = 512
  plane.turret_animation = nil
  plane.turret_rotation_speed = nil
  plane.turret_return_timeout = nil
  plane.guns = nil

  plane.minimap_representation = {
    -- Credits to the aircraft mod
    filename = "__c5-galaxy__/graphics/aircraft-minimap-representation.png",
    flags = { "icon" },
    size = { 40, 40 },
    scale = 1.0
  }
  plane.selected_minimap_representation = {
    -- Credits to the aircraft mod
    filename = "__c5-galaxy__/graphics/aircraft-minimap-representation-selected.png",
    flags = { "icon" },
    size = { 40, 40 },
    scale = 1.0
  }

  return plane
end

return make_plane
