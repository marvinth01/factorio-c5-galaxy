-- Migration to mod version 2.0.

-- Introduces a way of tracking of all planes that doesn't depend on players inside of the planes
global.planes = {
  ["c5-galaxy-grounded"] = {},
  ["c5-galaxy-flying"] = {},
}
for _, surface in pairs(game.surfaces) do
  for _, plane_grounded in ipairs(surface.find_entities_filtered { name = "c5-galaxy-grounded" }) do
    local id = plane_grounded.unit_number
    assert(id ~= nil)
    global.planes["c5-galaxy-grounded"][id] = {
      entity = plane_grounded,
      autopilot_data = nil,
    }
  end
  for _, plane_flying in ipairs(surface.find_entities_filtered { name = "c5-galaxy-flying" }) do
    local id = plane_flying.unit_number
    assert(id ~= nil)
    global.planes["c5-galaxy-flying"][id] = {
      entity = plane_flying,
      autopilot_data = nil,
    }
  end
end

-- Set up autopilot selection table
do
  global.player_selection = {}
end

-- Unlock new recipes since science changed
for _, force in pairs(game.forces) do
  local technologies = force.technologies
  local recipes = force.recipes

  if technologies["c5-galaxy"].researched then
    recipes["parking-marker"].enabled = true
    recipes["taxi-marker"].enabled = true
    recipes["takeoff-marker"].enabled = true
    recipes["landing-marker"].enabled = true
    recipes["c5-galaxy-controller"].enabled = true
  end
end
