local M = {}

-- ---@class Vec2
-- ---@field x number
-- ---@field y number
---@alias Vec2 MapPosition.0

---@param a Vec2
---@param b Vec2
---@return Vec2
function M.add(a, b)
  return {
    x = a.x + b.x,
    y = a.y + b.y,
  }
end

---@param a Vec2
---@param b Vec2
---@return Vec2
function M.sub(a, b)
  return {
    x = a.x - b.x,
    y = a.y - b.y,
  }
end

---@param s number
---@param v Vec2
---@return Vec2
function M.scalar_mul(s, v)
  return {
    x = s * v.x,
    y = s * v.y,
  }
end

---@param a Vec2
---@param b Vec2
---@return number
function M.dot(a, b)
  return a.x * b.x + a.y * b.y
end

---@param v Vec2
---@return number
function M.len(v)
  return math.sqrt(v.x * v.x + v.y * v.y)
end

---@param v Vec2
---@return Vec2
function M.normalize(v)
  return M.scalar_mul(1 / M.len(v), v)
end

---@param v Vec2
---@return Vec2
function M.rotclock90(v)
  -- Coordinate system: X=right Y=down
  return {
    x = -v.y,
    y = v.x,
  }
end

---@param o number
---@return Vec2
function M.from_orientation(o)
  return {
    x = math.sin(o * math.pi * 2),
    y = -math.cos(o * math.pi * 2),
  }
end

---@param v Vec2
---@return number
function M.to_orientation(v)
  local o = math.atan2(v.x, -v.y) / (math.pi * 2)
  return o % 1.
end

return M
