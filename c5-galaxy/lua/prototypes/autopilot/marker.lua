local collision_mask_util = require("collision-mask-util")
local marker_mask = collision_mask_util.get_first_unused_layer()

---@param name string
---@param width number
---@param length number
---@param image_location string
---@param image_size integer
---@param icon_location string
---@param inner_order string
local function add_marker(name, width, length, image_location, image_size, icon_location, inner_order)
  local halfwidth = width / 2
  local halflength = length / 2
  ---@type data.SimpleEntityWithOwnerPrototype
  local entity = {
    type = "simple-entity-with-owner",
    name = name,
    build_grid_size = 1,
    selection_box = { { -halfwidth, -halflength }, { halfwidth, halflength } },
    collision_box = { { -halfwidth + 0.1, -halflength + 0.1 }, { halfwidth - 0.1, halflength - 0.1 } },
    collision_mask = { marker_mask },
    selection_priority = 49,
    minable = {
      mining_time = 0.5,
      result = name,
    },
    flags = {
      "placeable-player",
      "player-creation",
      "not-repairable",
    },
    render_layer = "lower-object",
    icon = icon_location,
    icon_size = 64,
    icon_mipmaps = 1,
    picture = {
      sheet = {
        filename = image_location,
        size = { image_size, image_size },
        frames = 4,
        scale = 8,
      },
    }
  }
  data:extend { entity }

  ---@type data.ItemWithEntityDataPrototype
  local item = {
    type = "item-with-entity-data",
    name = name,
    subgroup = "transport",
    order = "b[personal-transport]-d[c5-galaxy]-b" .. inner_order .. "[" .. name .. "]",
    stack_size = 20,
    place_result = name,
    icon = icon_location,
    icon_size = 64,
  }
  data:extend { item }

  ---@type data.RecipePrototype
  local recipe = {
    type = "recipe",
    name = name,
    enabled = false,
    energy_required = 0.5,
    ingredients = { { "processing-unit", 1 } },
    result = name,
  }
  data:extend { recipe }
end

add_marker(
  "parking-marker",
  6, 21,
  "__c5-galaxy__/graphics/parking-marker.png",
  128,
  "__c5-galaxy__/graphics/parking-icon.png",
  "1"
)
add_marker(
  "taxi-marker",
  4, 4,
  "__c5-galaxy__/graphics/taxi-marker.png",
  32,
  "__c5-galaxy__/graphics/taxi-icon.png",
  "1"
)
add_marker(
  "takeoff-marker",
  4, 8,
  "__c5-galaxy__/graphics/takeoff-marker.png",
  64,
  "__c5-galaxy__/graphics/takeoff-icon.png",
  "2"
)
add_marker(
  "landing-marker",
  4, 8,
  "__c5-galaxy__/graphics/landing-marker.png",
  64,
  "__c5-galaxy__/graphics/landing-icon.png",
  "3"
)
