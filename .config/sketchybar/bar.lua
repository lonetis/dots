local colors = require("helpers.colors")
local fonts = require("helpers.fonts")

-- https://felixkratz.github.io/SketchyBar/config/bar
sbar.bar({
  -- position
  hidden = false, -- <boolean>, current
  position = "bottom",
  display = "all", -- main, all, <positive_integer list>
  topmost = false, -- <boolean>, window
  sticky = true,

  -- paddings and margins
  padding_left = 0,
  padding_right = 0,
  margin = 0,
  y_offset = 0,

  -- style
  height = 30,
  corner_radius = 0,
  font_smoothing = false,

  -- notch
  -- notch_display_height = 40,
  -- notch_width = 200,
  -- notch_offset = 0,

  -- color
  color = colors.transparent,
  blur_radius = 0,

  -- border
  border_color = colors.white,
  border_width = 0,

  -- shadow
  shadow = false,
})
