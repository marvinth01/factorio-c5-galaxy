local M = {}

M.speed_per_kmh = 1 / (3.6 * 60)

M.takeoff_speed = 160.0 * M.speed_per_kmh

local height_per_kmh = 0.75
M.height_per_speed = height_per_kmh / M.speed_per_kmh

M.shadow_fadeout_height = 150.0

return M
