local colors = require("helpers.colors")
local settings = require("helpers.settings")

-- https://felixkratz.github.io/SketchyBar/config/items
sbar.default({
  -- paddings and margins
  padding_left = 5,
  padding_right = 5,

  -- icon
  icon = {
    font = settings.font_text,
    color = colors.white,
    highlight_color = colors.red,
    padding_left = settings.padding,
    padding_right = settings.padding,
  },

  -- label
  label = {
    font = settings.font_text,
    color = colors.white,
    padding_left = settings.padding,
    padding_right = settings.padding,
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
      color = colors.popup.bg,
      border_color = colors.popup.border,
      border_width = 1,
      corner_radius = 5,
    },
  },

  -- events
  updates = "when_shown",
})
