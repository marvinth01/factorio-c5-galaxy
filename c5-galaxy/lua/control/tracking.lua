local M = {}

---@class PlaneInfo
---@field entity LuaEntity
---@field autopilot_data? AutopilotData

function M.on_init()
  ---@type table<string, table<int, PlaneInfo>>
  global.planes = {
    ["c5-galaxy-grounded"] = {},
    ["c5-galaxy-flying"] = {},
  }
end

---Similar to `pairs`. Iterates over all the valid plane infos, cleaning up invalid ones.
---@param t table<int, PlaneInfo>
function M.valid_pairs(t)
  local f, s, var = pairs(t)
  return function()
    while true do
      local id, info = f(s, var)
      var            = id
      if var == nil then break end

      if info.entity.valid then
        return id, info
      else
        t[id] = nil
      end
    end
    return nil
  end
end

---@param entity LuaEntity
function M.on_entity_created(entity)
  if entity.name == "c5-galaxy-grounded" then
    local id = entity.unit_number
    assert(id ~= nil)
    if not global.planes["c5-galaxy-grounded"][id] then
      global.planes["c5-galaxy-grounded"][id] = {
        entity = entity,
        autopilot_data = nil,
      }
    else
      assert(global.planes["c5-galaxy-grounded"][id].entity == entity)
    end
  elseif entity.name == "c5-galaxy-flying" then
    local id = entity.unit_number
    assert(id ~= nil)
    if not global.planes["c5-galaxy-flying"][id] then
      global.planes["c5-galaxy-flying"][id] = {
        entity = entity,
        autopilot_data = nil,
      }
    else
      assert(global.planes["c5-galaxy-flying"][id].entity == entity)
    end
  end
end

return M
