---@type data.SelectionToolPrototype
local item = {
  type = "selection-tool",
  name = "c5-galaxy-controller",
  subgroup = "transport",
  order = "b[personal-transport]-d[c5-galaxy]-c[controller]",
  stack_size = 1,
  icon = "__c5-galaxy__/graphics/controller.png",
  icon_size = 32,
  icon_mipmaps = 1,

  selection_mode = { "entity-with-owner" },
  alt_selection_mode = { "nothing" },
  selection_color = { 127, 127, 255, 127 },
  alt_selection_color = { 127, 127, 255, 127 },
  selection_cursor_box_type = "pair",
  alt_selection_cursor_box_type = "pair",

  entity_filter_mode = "whitelist",
  entity_filters = { "c5-galaxy-grounded", "parking-marker", "taxi-marker", "landing-marker", "takeoff-marker" },
  reverse_entity_filters = { "c5-galaxy-grounded", "c5-galaxy-flying" },
}
data:extend { item }

---@type data.RecipePrototype
local recipe = {
  type = "recipe",
  name = "c5-galaxy-controller",
  enabled = false,
  energy_required = 0.5,
  ingredients = { { "processing-unit", 1 } },
  result = "c5-galaxy-controller",
}
data:extend { recipe }
