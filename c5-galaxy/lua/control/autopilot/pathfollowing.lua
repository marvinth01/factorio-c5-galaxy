local M = {}

local vec = require("lua.vecmath")
local constants = require("lua.constants")

local function sign(x)
  if x >= 0 then
    return 1
  else
    return -1
  end
end

local SPEED_TOLERANCE = 0.5 / (3.6 * 60)

---@param current number
---@param target number|nil
---@return nil
local function determine_acceleration(current, target)
  if target == nil then
    return defines.riding.acceleration.accelerating
  elseif target == 0 then
    return defines.riding.acceleration.braking
  elseif math.abs(current - target) <= SPEED_TOLERANCE then
    return defines.riding.acceleration.nothing
  elseif current > target then
    return defines.riding.acceleration.braking
  else
    return defines.riding.acceleration.accelerating
  end
end

---Returns the next riding state to follow the `PathSegment`, or `nil` if we finished it.
---@param plane LuaEntity
---@param segment PathSegment
---@return RidingState|nil
function M.follow(plane, segment)
  if segment.type == "line" then
    ---@cast segment LinePathSegment

    -- Check if we reached target
    local pathvec = vec.sub(segment.b, segment.a)
    local pathlen = vec.len(pathvec)
    local pathdir = vec.normalize(pathvec)
    local t = vec.dot(vec.sub(plane.position, segment.a), pathdir) / pathlen
    if t >= 1 then
      return nil
    end
    -- Special case: Once speed 0 is reached we are at the destination
    if plane.speed == 0 and segment.speed == 0 then
      return nil
    end

    local acceleration = determine_acceleration(plane.speed, segment.speed)

    -- Orientation stuff
    local rightnessdir = vec.rotclock90(pathdir)
    local rightness = vec.dot(vec.sub(plane.position, segment.a), rightnessdir)
    if math.abs(rightness) < 0.1 then
      rightness = 0
    end
    local local_orientation_target
    if segment.precision_turn_radius ~= nil then
      local rightness_radius_adjusted = rightness / segment.precision_turn_radius
      local x = math.max(-1, math.min(1, rightness_radius_adjusted))
      local_orientation_target = 0.25 * (sign(x) * math.asin(1 - math.abs(x)) / (0.5 * math.pi) - sign(x))
    else
      local_orientation_target = math.atan(0.05 * rightness) / (-2.0 * math.pi)
    end
    local orientation_target = (vec.to_orientation(pathdir) + local_orientation_target) % 1.0
    local oridiff = (orientation_target - plane.orientation) % 1.0
    local direction
    if oridiff == 0.0 then
      direction = defines.riding.direction.straight
    elseif oridiff <= 0.5 then
      direction = defines.riding.direction.right
    else
      direction = defines.riding.direction.left
    end

    return {
      acceleration = acceleration,
      direction = direction,
    }
  elseif segment.type == "circle" then
    ---@cast segment CirclePathSegment

    -- Check if we reached target
    local speed_ok = not segment.speed or math.abs(plane.speed - segment.speed) <= 5 * constants.speed_per_kmh
    local orientation_ok = math.abs((plane.orientation - segment.orientation + 0.5) % 1.0 - 0.5) < 0.01
    if speed_ok and orientation_ok then
      local oridir = vec.from_orientation(segment.orientation)
      local exit_point = vec.add(
        segment.center,
        vec.scalar_mul(segment.winding * -segment.radius, vec.rotclock90(oridir))
      )
      local position_ok = vec.len(vec.sub(plane.position, exit_point)) <= 3.0
      if position_ok then
        return nil
      end
    end
    -- Special case: Once speed 0 is reached we are at the destination
    if plane.speed == 0 and segment.speed == 0 then
      return nil
    end

    local acceleration = determine_acceleration(plane.speed, segment.speed)

    -- Orientation stuff
    local centerdir = vec.normalize(vec.sub(segment.center, plane.position))
    local rightnessdir = vec.scalar_mul(segment.winding, centerdir)
    local projected_plane_pos_on_circle = vec.add(segment.center, vec.scalar_mul(-segment.radius, centerdir))
    local rightness = vec.dot(vec.sub(plane.position, projected_plane_pos_on_circle), rightnessdir)
    local local_orientation_target = math.atan(0.05 * rightness) / (-2.0 * math.pi)
    local orientation_target = (vec.to_orientation(rightnessdir) - 0.25 + local_orientation_target) % 1.0
    local oridiff = (orientation_target - plane.orientation) % 1.0
    local direction
    if oridiff == 0.0 then
      direction = defines.riding.direction.straight
    elseif oridiff <= 0.5 then
      direction = defines.riding.direction.right
    else
      direction = defines.riding.direction.left
    end

    return {
      acceleration = acceleration,
      direction = direction,
    }
  end
end

return M
