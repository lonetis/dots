local icons = require("helpers.icons")
local colors = require("helpers.colors")

local apple = sbar.add("item", {
  padding_right = 10,
  icon = {
    string = icons.apple,
    color = colors.red,
  },
  label = {
    drawing = false,
  },
})

local function apple_clicked()
  sbar.exec("open -a 'System Preferences'")
end

apple:subscribe("mouse.clicked", apple_clicked)
