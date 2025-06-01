---@type data.SelectionToolPrototype
local item = {
  type = "selection-tool",
  name = "c5-galaxy-tool-path",
  subgroup = "transport",
  order = "b[personal-transport]-d[c5-galaxy]-c[tool]-a[path]",
  stack_size = 1,
  icon = "__c5-galaxy__/graphics/tool-path.png",
  icon_size = 32,

  flags = {"not-stackable", "only-in-cursor", "spawnable"},

  select = {
    mode = { "entity-with-owner" },
    border_color = { 127, 127, 255, 127 },
    cursor_box_type = "pair",
    entity_filter_mode = "whitelist",
    entity_filters = { "c5-galaxy-grounded", "parking-marker", "taxi-marker", "landing-marker", "takeoff-marker" },
  },
  reverse_select = {
    mode = { "entity-with-owner" },
    border_color = { 127, 127, 255, 127 },
    cursor_box_type = "pair",
    entity_filter_mode = "whitelist",
    entity_filters = { "c5-galaxy-grounded", "c5-galaxy-flying" },
  },
  alt_select = {
    mode = { "nothing" },
    border_color = { 127, 127, 255, 127 },
    cursor_box_type = "pair",
  },
}
data:extend { item }

---@type data.ShortcutPrototype
local shortcut = {
  type = "shortcut",
  name = "c5-galaxy-tool-path",
  order = "f[c5-galaxy]-a[tool-path]",
  action = "spawn-item",
  technology_to_unlock = "c5-galaxy",
  item_to_spawn = "c5-galaxy-tool-path",
  icon = "__c5-galaxy__/graphics/tool-path.png",
  icon_size = 32,
  small_icon = "__c5-galaxy__/graphics/tool-path.png",
  small_icon_size = 32,
}
data:extend { shortcut }
