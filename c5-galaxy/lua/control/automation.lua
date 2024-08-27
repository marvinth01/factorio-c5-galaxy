local M = {}

---@param e EventData.on_player_selected_area
function M.on_player_selected_area(e)
  if e.item ~= "c5-galaxy-tool-config" then
    return
  end

  local player = game.players[e.player_index]

  ---@type LuaGuiElement
  local element = {
    type = "frame",
    name = "c5_main_frame",
    caption = "hello gui, entity: " .. e.entities[1].name,
  }
  local main_frame = player.gui.screen.add(element)
  main_frame.style.size = { 800, 450 }
  main_frame.auto_center = true

  local content_frame = main_frame.add {
    type = "frame",
    name = "content_frame",
    direction = "vertical",
    --style = "c5_content_frame",
  }
  local controls_flow = content_frame.add {
    type = "flow",
    name = "controls_flow",
    direction = "horizontal",
    --style = "c5_controls_flow",
  }

  local button = controls_flow.add {
    type = "button",
    name = "ugg_controls_toggle",
    caption = { "ugg.deactivate" },
  }

  -- https://github.com/ClaudeMetz/UntitledGuiGuide/wiki/Chapter-2:-Pressing-The-Button
end

return M
