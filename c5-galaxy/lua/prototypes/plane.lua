local make_plane = require("plane.make_plane")
local plane_grounded = make_plane("c5-galaxy-grounded", true)
local plane_flying = make_plane("c5-galaxy-flying", false)

-- Allow disabling players as military targets when in an airborne plane
data.raw["character"]["character"].allow_run_time_change_of_is_military_target = true

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

---@type data.ItemWithEntityDataPrototype
local plane_item = table.deepcopy(data.raw["item-with-entity-data"]["car"])
plane_item.name = "c5-galaxy"
plane_item.place_result = "c5-galaxy-grounded"
plane_item.icon = "__c5-galaxy__/graphics/icon.png"
plane_item.icon_size = 512
plane_item.order = "b[personal-transport]-d[c5-galaxy]-a[plane]"
data:extend { plane_item }

---@type data.RecipePrototype
local recipe = {
  type = "recipe",
  name = "c5-galaxy",
  enabled = false,
  energy_required = 20,
  ingredients = {
    { type = "item", name = "steel-plate",           amount = 200 },
    { type = "item", name = "low-density-structure", amount = 50 },
    { type = "item", name = "processing-unit",       amount = 20 },
  },
  results = {
    { type = "item", name = "c5-galaxy", amount = 1 },
  },
}
data:extend { recipe }
