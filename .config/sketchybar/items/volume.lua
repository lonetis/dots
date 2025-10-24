local icons = require("helpers.icons")

local volume = sbar.add("item", {
  position = "right",
})

local function volume_update(env)
  local percentage = tonumber(env.INFO)
  local icon = nil
  if percentage > 60 then
    icon = icons.volume._100
  elseif percentage > 30 then
    icon = icons.volume._66
  elseif percentage > 10 then
    icon = icons.volume._33
  elseif percentage > 0 then
    icon = icons.volume._10
  else
    icon = icons.volume._0
  end
  volume:set({ icon = icon, label = tostring(percentage) .. "%" })
end

volume:subscribe("volume_change", volume_update)
