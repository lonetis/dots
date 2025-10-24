local fonts = require("helpers.fonts")
local icon_map = require("helpers.icon_map")

local front_app_notch = sbar.add("item", {
  position = "left",
  display = 1, -- only main display has notch
  padding_left = 10,
})

local front_app_center = sbar.add("item", {
  position = "left",
  display = "2, 3, 4, 5", -- all displays except main display
  padding_left = 10,
})

local function front_app_update(env)
  for _, item in ipairs({front_app_notch, front_app_center}) do
    item:set({
      icon = {
        string = icon_map[env.INFO] or icon_map["Default"],
        font = fonts.apps,
      },
      label = {
        string = env.INFO,
      }
    })
  end
end

local function front_app_clicked()
  sbar.exec("osascript -e 'tell application \"System Events\" to keystroke \"b\" using {command down, option down}'")
end

front_app_notch:subscribe("front_app_switched", front_app_update)
front_app_notch:subscribe("mouse.clicked", front_app_clicked)
front_app_center:subscribe("front_app_switched", front_app_update)
front_app_center:subscribe("mouse.clicked", front_app_clicked)
