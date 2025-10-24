local colors = require("helpers.colors")
local settings = require("helpers.settings")

-- https://felixkratz.github.io/SketchyBar/config/bar
sbar.bar({
  -- position
  hidden = false, -- <boolean>, current
  position = "bottom",
  display = "all", -- main, all, <positive_integer list>
  topmost = false, -- <boolean>, window
  sticky = true,

  -- paddings and margins
  padding_left = 10,
  padding_right = 10,
  margin = 0,
  y_offset = 0,

  -- style
  height = 30,
  corner_radius = 0,
  font_smoothing = false,

  -- notch
  -- notch_display_height = 40,
  notch_width = 200,
  notch_offset = 0,

  -- color
  color = colors.bar.bg,
  blur_radius = 20,

  -- border
  border_color = colors.bar.border,
  border_width = 0,

  -- shadow
  shadow = false,
})
