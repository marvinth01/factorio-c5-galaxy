local M = {}

local vec = require("lua.vecmath")

local SPEED_PARKING = 10 / (3.6 * 60)
local SPEED_TAXI = 40 / (3.6 * 60)
local SPEED_APPROACH = 180 / (3.6 * 60)

local TURNRADIUS_PARKING = 20
local TURNRADIUS_TAXI = 27
local TURNRADIUS_APPROACH = 75
local TURNRADIUS_CRUISE = 125

---@alias PathSegment CirclePathSegment|LinePathSegment

-- Criteria for end: Approximately correct speed, orientation, position
---@class CirclePathSegment
---@field type "circle"
---@field speed float|nil
---@field center MapPosition.0
---@field radius double
---@field orientation RealOrientation
---@field winding 1|-1

-- Criterium for end: Have passed the end point
---@class LinePathSegment
---@field type "line"
---@field speed float|nil
---@field a MapPosition.0
---@field b MapPosition.0
---Mostly used by ground navigation to arrive at line quickly
---Especially important when parking
---@field precision_turn_radius double|nil

---@param goal_pos MapPosition.0
---@param goal_orientation RealOrientation
---@param radius double
---@param speed float|nil
---@param winding 1|-1
---@return CirclePathSegment
function M.circle_from_exit_pos(goal_pos, goal_orientation, radius, speed, winding)
  local center = vec.add(
    goal_pos,
    vec.scalar_mul(radius * winding, vec.rotclock90(vec.from_orientation(goal_orientation)))
  )
  return {
    type = "circle",
    speed = speed,
    center = center,
    radius = radius,
    orientation = goal_orientation,
    winding = winding,
  }
end

---@param center MapPosition.0
---@param radius double
---@param winding 1|-1
---@param orientation RealOrientation
---@return MapPosition.0
function M.circle_get_tangent_pos(center, radius, winding, orientation)
  local oridir = vec.from_orientation(orientation)
  local exit_point = vec.add(
    center,
    vec.scalar_mul(winding * -radius, vec.rotclock90(oridir))
  )
  return exit_point
end

---@param queue LuaEntity[]
---@return PathSegment[]
function M.pathfind(queue)
  ---@type PathSegment[]
  local path = {}
  for _, marker in ipairs(queue) do
    if marker.name == "parking-marker" then
      local dirvec = vec.from_orientation(marker.orientation)
      local function approachpoint(dist)
        return vec.add(
          marker.position,
          vec.scalar_mul(dist, dirvec)
        )
      end
      table.insert(path, {
        type = "line",
        speed = SPEED_TAXI,
        a = approachpoint(-50),
        b = approachpoint(-10),
        precision_turn_radius = TURNRADIUS_TAXI,
      })
      table.insert(path, {
        type = "line",
        speed = SPEED_PARKING,
        a = approachpoint(-10),
        b = marker.position,
        precision_turn_radius = TURNRADIUS_PARKING,
      })
      table.insert(path, {
        type = "line",
        speed = 0,
        a = marker.position,
        b = approachpoint(10),
        precision_turn_radius = TURNRADIUS_PARKING,
      })
    elseif marker.name == "taxi-marker" then
      local taxi_line_start = vec.add(
        marker.position,
        vec.scalar_mul(-25, vec.from_orientation(marker.orientation))
      )
      table.insert(path, {
        type = "line",
        speed = SPEED_TAXI,
        a = taxi_line_start,
        b = marker.position,
        precision_turn_radius = TURNRADIUS_TAXI,
      })
    elseif marker.name == "takeoff-marker" then
      local takeoff_line_end = vec.add(
        marker.position,
        vec.scalar_mul(350, vec.from_orientation(marker.orientation))
      )
      table.insert(path, {
        type = "line",
        speed = SPEED_TAXI,
        a = vec.add(
          marker.position,
          vec.scalar_mul(-50, vec.from_orientation(marker.orientation))
        ),
        b = marker.position,
        precision_turn_radius = TURNRADIUS_TAXI,
      })
      table.insert(path, {
        type = "line",
        speed = nil,
        a = marker.position,
        b = takeoff_line_end,
      })
      table.insert(
        path,
        M.circle_from_exit_pos(takeoff_line_end, marker.orientation, TURNRADIUS_CRUISE, nil, 1)
      )
    elseif marker.name == "landing-marker" then
      local landing_approach_start = vec.add(
        marker.position,
        vec.scalar_mul(-75, vec.from_orientation(marker.orientation))
      )
      table.insert(
        path,
        M.circle_from_exit_pos(landing_approach_start, marker.orientation, TURNRADIUS_APPROACH, SPEED_APPROACH, 1)
      )
      table.insert(path, {
        type = "line",
        speed = SPEED_APPROACH,
        a = landing_approach_start,
        b = marker.position,
      })
      table.insert(path, {
        type = "line",
        speed = 0,
        a = marker.position,
        b = vec.add(marker.position, vec.scalar_mul(500, vec.from_orientation(marker.orientation))),
      })
    else
      assert(false, "Invalid marker in queue: " .. marker.name)
    end
  end

  -- Connect circles with lines
  local i = 1
  while i + 1 <= #path do
    local a = path[i]
    local b = path[i + 1]
    if a.type == "circle" and b.type == "circle" then
      ---@cast a CirclePathSegment
      ---@cast b CirclePathSegment

      local dirvec = vec.sub(b.center, a.center)
      local dist = vec.len(dirvec)
      local raddiff = a.winding * a.radius - b.winding * b.radius
      local arcsin_arg = raddiff / dist
      if arcsin_arg < -1 or arcsin_arg > 1 or dist == 0 then
        -- Can't properly connect the 2 circles, create circle not intersecting the offending 2 circles
        table.insert(path, i + 1, {
          type = "circle",
          speed = a.speed,
          center = vec.add(a.center, { x = 2 * (a.radius + b.radius), y = 0 }),
          radius = a.radius,
          orientation = 0.0, -- Doesn't matter, will be overwritten
          winding = b.winding, -- Shouldn't matter
        })
        -- Don't increment radius, we will want to create the 2 line connections to and from the auxiliary circle
        goto continue
      end
      local oridiff = math.asin(arcsin_arg) / (2.0 * math.pi)
      local conn_orientation = vec.to_orientation(dirvec) + oridiff

      table.insert(path, i + 1, {
        type = "line",
        speed = a.speed,
        a = M.circle_get_tangent_pos(a.center, a.radius, a.winding, conn_orientation),
        b = M.circle_get_tangent_pos(b.center, b.radius, b.winding, conn_orientation),
      })
      path[i].orientation = conn_orientation
    end
    i = i + 1
    ::continue::
  end
  return path
end

---@param segment PathSegment
---@param color Color
---@param surface LuaSurface
---@param players LuaPlayer[]
function M.draw_segment(segment, color, surface, players)
  if segment.type == "line" then
    ---@cast segment LinePathSegment
    rendering.draw_line {
      color = color,
      width = 15,
      from = segment.a,
      to = segment.b,
      surface = surface,
      time_to_live = 2,
      players = players,
    }
  elseif segment.type == "circle" then
    ---@cast segment CirclePathSegment
    rendering.draw_circle {
      color = color,
      width = 15,
      radius = segment.radius,
      target = segment.center,
      surface = surface,
      time_to_live = 2,
      players = players,
    }
  end
end

---Connects 2 circles with a line, respecting windings
---You should update the orientation of the 1st circle afterwards
---Returns nil if not possible
---@param circle1 CirclePathSegment
---@param circle2 CirclePathSegment
---@param speed float|nil
---@return LinePathSegment|nil
local function connect_circles(circle1, circle2, speed)
end

return M
