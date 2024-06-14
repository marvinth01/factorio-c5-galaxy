data:extend { {
  type = "trigger-target-type",
  name = "high-altitude-unit",
} }

local make_plane = require("prototypes.make_plane")
local plane_grounded = make_plane(true)
local plane_flying = make_plane(false)

-- Shadow animation
local shadow_anim = plane_flying.animation.layers[2]
plane_flying.animation.layers[2] = nil
shadow_anim.type = "animation"
shadow_anim.name = "c5-galaxy-flying-shadow"
shadow_anim.frame_count = shadow_anim.direction_count
shadow_anim.direction_count = nil
shadow_anim.draw_as_shadow = false -- Would put the shadow under entities
data:extend { shadow_anim }

data:extend { plane_grounded }
data:extend { plane_flying }

local plane_item = table.deepcopy(data.raw["item-with-entity-data"]["car"])
plane_item.name = "c5-galaxy"
plane_item.place_result = "c5-galaxy-grounded"
plane_item.icon = "__c5-galaxy__/graphics/icon.png"
plane_item.icon_size = 512
data:extend { plane_item }

local plane_tech = {
  type = "technology",
  name = "c5-galaxy",
  icon = "__c5-galaxy__/graphics/icon.png",
  icon_size = 512,
  prerequisites = { "low-density-structure", "advanced-electronics-2" },
  unit = {
    count_formula = "1000",
    ingredients = {
      { "automation-science-pack", 1 },
      { "logistic-science-pack",   1 },
      { "chemical-science-pack",   1 },
    },
    time = 30
  },
  effects = { { type = "unlock-recipe", recipe = "c5-galaxy" } },
}
data:extend { plane_tech }

local recipe = {
  type = "recipe",
  name = "c5-galaxy",
  enabled = false,
  energy_required = 20,
  -- TODO: Balance
  ingredients = { { "steel-plate", 200 }, { "low-density-structure", 50 }, { "processing-unit", 20 } },
  result = "c5-galaxy",
}
data:extend { recipe }
