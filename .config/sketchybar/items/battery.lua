local icons = require("helpers.icons")
local settings = require("helpers.settings")

local battery = sbar.add("item", {
  position = "right",
  update_freq = 120,
})

local function battery_update()
  sbar.exec("pmset -g batt", function(info)
    local icon = "!"
    local label = ""

    if (info:find("AC Power")) then -- Charging
      icon = icons.battery.charging

      local found_percentage, _, percentage = info:find("(%d+)%%") -- Percentage
      if found_percentage then
        label = percentage .. "%"
      end

      local found_remaining, _, remaining = info:find("(%d+:%d+) remaining") -- Remaining
      if found_remaining and remaining ~= "0:00" then
        label = label .. " (" .. remaining .. " remaining)"
      end

    else -- Discharging
      local found_percentage, _, percentage = info:find("(%d+)%%") -- Percentage
      if found_percentage then
        label = percentage .. "%"
      end

      if found_percentage and tonumber(percentage) > 80 then
        icon = icons.battery._100
      elseif found_percentage and tonumber(percentage) > 60 then
        icon = icons.battery._75
      elseif found_percentage and tonumber(percentage) > 40 then
        icon = icons.battery._50
      elseif found_percentage and tonumber(percentage) > 20 then
        icon = icons.battery._25
      else
        icon = icons.battery._0
      end
    end

    battery:set({ icon = icon, label = label })
  end)
end

battery:subscribe({"routine", "power_source_change", "system_woke"}, battery_update)
