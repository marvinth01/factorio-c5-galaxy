---@type data.TechnologyPrototype
local plane_tech = {
  type = "technology",
  name = "c5-galaxy",
  icon = "__c5-galaxy__/graphics/icon.png",
  icon_size = 512,
  icon_mipmaps = 1,
  prerequisites = { "low-density-structure", "advanced-electronics-2" },
  unit = {
    count_formula = "500",
    ingredients = {
      { "automation-science-pack", 1 },
      { "logistic-science-pack",   1 },
      { "chemical-science-pack",   1 },
    },
    time = 30
  },
  effects = {
    { type = "unlock-recipe", recipe = "c5-galaxy" },
    { type = "unlock-recipe", recipe = "parking-marker" },
    { type = "unlock-recipe", recipe = "taxi-marker" },
    { type = "unlock-recipe", recipe = "takeoff-marker" },
    { type = "unlock-recipe", recipe = "landing-marker" },
    { type = "unlock-recipe", recipe = "c5-galaxy-tool-path" },
    { type = "unlock-recipe", recipe = "c5-galaxy-tool-config" },
  },
}
data:extend { plane_tech }
