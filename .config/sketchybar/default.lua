local colors = require("helpers.colors")
local fonts = require("helpers.fonts")

-- https://felixkratz.github.io/SketchyBar/config/items
sbar.default({
  -- paddings and margins
  padding_left = 5,
  padding_right = 0, -- only the last item needs right padding

  -- icon
  icon = {
    font = fonts.text,
    color = colors.white,
    highlight_color = colors.red,
    padding_left = 5,
    padding_right = 0,
  },

  -- label
  label = {
    font = fonts.text,
    color = colors.white,
    padding_left = 5,
    padding_right = 5,
  },

  -- background
  background = {
    height = 25,
    corner_radius = 5,
  },

  -- popup
  popup = {
    blur_radius = 20,
    background = {
      color = colors.dark_transparent,
      border_color = colors.white,
      border_width = 1,
      corner_radius = 5,
    },
  },

  -- events
  updates = "when_shown",
})
