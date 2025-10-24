local settings = require("helpers.settings")

local calendar = sbar.add("item", {
  position = "right",
  update_freq = 15,
  icon = {
    string = ":calendar:",
    font = settings.font_apps,
  },
})

local function calendar_update()
  local date = os.date("%a. %d %b.")
  local time = os.date("%H:%M")
  calendar:set({ label = date .. " " .. time })
end

local function calendar_clicked()
  sbar.exec("open -a 'Calendar'")
end

calendar:subscribe({"routine", "forced"}, calendar_update)
calendar:subscribe("mouse.clicked", calendar_clicked)
