local settings = require("helpers.settings")
local icons = require("helpers.icons")

local uname = sbar.add("item", {
  position = "right",
  icon = {
    string = icons.user,
  },
  label = {
    string = os.getenv("USER"),
  },
})
