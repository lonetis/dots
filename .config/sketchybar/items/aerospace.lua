local colors = require("helpers.colors")
local settings = require("helpers.settings")
local icon_map = require("helpers.icon_map")

-- https://nikitabobko.github.io/AeroSpace/commands#list-workspaces
local aerospace_list_workspaces = "aerospace list-workspaces --all --json --format '%{workspace} %{workspace-is-focused} %{workspace-is-visible} %{monitor-id} %{monitor-appkit-nsscreen-screens-id} %{monitor-name}'"

-- https://nikitabobko.github.io/AeroSpace/commands#list-windows
local aerospace_list_windows = "aerospace list-windows --all --json --format '%{window-id} %{window-title} %{app-bundle-id} %{app-name} %{app-pid} %{workspace} %{workspace-is-focused} %{workspace-is-visible} %{monitor-id} %{monitor-appkit-nsscreen-screens-id} %{monitor-name}'"

local space_names = {
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
  "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  "ä", "ö", "ü",
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
}

local space_items = {}
local space_current_focus = nil
local space_previous_focus = nil

-- Create invisible trigger
local trigger = sbar.add("item", "aerospace", {
  drawing = false,
  updates = true,
})

-- Create space items
for _, space_name in ipairs(space_names) do
  local space_item = sbar.add("item", "space." .. space_name, {
    icon = {
      string = string.upper(space_name),
      font = settings.font_mono,
      color = colors.white,
      highlight_color = colors.red,
    },
    label = {
      font = settings.font_apps,
      color = colors.grey,
      highlight_color = colors.white,
    },
    background = {
      color = colors.items.bg,
      border_color = colors.items.border,
      border_width = 1,
    },
  })

  space_items[space_name] = space_item

  -- Click handlers
  space_item:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "left" then
      -- Left click -> switch to space
      sbar.exec("aerospace summon-workspace " .. space_name)
    elseif env.BUTTON == "right" then
      -- Right click -> hide / show app icons from all space items
      sbar.set("/space\\..*/", { label = { drawing = "toggle" } })
    elseif env.BUTTON == "right" and env.MODIFIER == "shift" then
      -- Right shift click -> hide / show app icons from clicked space item
      space_item:set({ label = { drawing = "toggle" } })
    end
  end)
end

local function aerospace_update()
  sbar.exec(aerospace_list_workspaces, function(workspaces)
    local space_data = {}

    -- Convert aerospace workspace information to space data
    for _, ws in ipairs(workspaces) do
      local workspace = ws["workspace"] -- string (i.e., "e")
      local workspace_is_focused = ws["workspace-is-focused"] -- boolean
      local workspace_is_visible = ws["workspace-is-visible"] -- boolean
      local monitor_id = ws["monitor-id"] -- int (left to right, starting at 1)
      local screen_id = ws["monitor-appkit-nsscreen-screens-id"] -- int (NSScreen.screens ordering, starting at 1)
      local monitor_name = ws["monitor-name"] -- string (i.e., "Built-in Retina Display")

      -- Init empty space data
      if space_data[workspace] == nil then
        space_data[workspace] = {}
      end

      -- Store space data
      space_data[workspace].workspace = workspace
      space_data[workspace].workspace_is_focused = workspace_is_focused
      space_data[workspace].workspace_is_visible = workspace_is_visible
      space_data[workspace].monitor_id = monitor_id
      space_data[workspace].screen_id = screen_id
      space_data[workspace].monitor_name = monitor_name
    end

    -- Update space items from space data
    for _, space_name in ipairs(space_names) do
      local sitem = space_items[space_name]
      local sdata = space_data[space_name]

      if sitem and sdata ~= nil then -- Space exists
        sitem:set({
          drawing = true,
          display = sdata.screen_id,
        })
        if sdata.workspace_is_focused then -- Space is focused (white + red bold border)
          sitem:set({
            icon = { color = colors.white },
            label = { color = colors.white },
            background = {
              color = colors.items.bg2,
              border_color = colors.items.border2,
              border_width = 2,
            },
          })
        elseif space_name == space_previous_focus then -- Space was previously focused (white + yellow bold border)
          sitem:set({
            icon = { color = colors.white },
            label = { color = colors.white },
            background = {
              color = colors.items.bg3,
              border_color = colors.items.border3,
              border_width = 2,
            },
          })
        elseif sdata.workspace_is_visible then -- Space is visible but not focused (white + green bold border)
          sitem:set({
            icon = { color = colors.white },
            label = { color = colors.white },
            background = {
              color = colors.items.bg4,
              border_color = colors.items.border4,
              border_width = 2,
            },
          })
        else -- Space is not focused (grey + grey thin border)
          sitem:set({
            icon = { color = colors.grey },
            label = { color = colors.grey },
            background = {
              border_color = colors.items.border,
              border_width = 1,
            },
          })
        end
      elseif sitem and sdata == nil then -- Space does not exist
        sitem:set({ drawing = false })
      end
    end
  end)

  sbar.exec(aerospace_list_windows, function(windows)
    local space_data = {}

    -- Convert aerospace window information to space data
    for _, window in ipairs(windows) do
      local window_id = window["window-id"] -- int
      local window_title = window["window-title"] -- string
      local app_bundle_id = window["app-bundle-id"] -- string (i.e., "com.apple.finder")
      local app_name = window["app-name"] -- string (i.e., "Finder")
      local app_pid = window["app-pid"] -- int
      local workspace = window["workspace"] -- string (i.e., "e")
      local workspace_is_focused = window["workspace-is-focused"] -- boolean
      local workspace_is_visible = window["workspace-is-visible"] -- boolean
      local monitor_id = window["monitor-id"] -- int (left to right, starting at 1)
      local screen_id = window["monitor-appkit-nsscreen-screens-id"] -- int (NSScreen.screens ordering, starting at 1)
      local monitor_name = window["monitor-name"] -- string (i.e., "Built-in Retina Display")

      -- Init empty space data
      if space_data[workspace] == nil then
        space_data[workspace] = { apps_counts = {} }
      end

      -- Store space data
      space_data[workspace].window_id = window_id
      space_data[workspace].window_title = window_title
      space_data[workspace].app_bundle_id = app_bundle_id
      space_data[workspace].app_name = app_name
      space_data[workspace].app_pid = app_pid
      space_data[workspace].workspace = workspace
      space_data[workspace].workspace_is_focused = workspace_is_focused
      space_data[workspace].workspace_is_visible = workspace_is_visible
      space_data[workspace].monitor_id = monitor_id
      space_data[workspace].screen_id = screen_id
      space_data[workspace].monitor_name = monitor_name

      -- Track apps and counts
      local apps_counts = space_data[workspace].apps_counts
      apps_counts[app_name] = (apps_counts[app_name] or 0) + 1
    end

    -- Update space items from space data
    for _, space_name in ipairs(space_names) do
      local sitem = space_items[space_name]
      local sdata = space_data[space_name]

      -- Build apps icons line
      local apps_icons_line = nil
      if sdata and sdata.apps_counts then
        local icons = {}
        for app, count in pairs(sdata.apps_counts) do
          local icon = icon_map[app] or icon_map["Default"]
          for i = 1, count do
            table.insert(icons, icon)
          end
        end
        apps_icons_line = table.concat(icons, " ")
      end

      -- Update space item with apps icons line
      if sitem then
        sitem:set({
          label = {
            string = apps_icons_line or "",
            drawing = (apps_icons_line ~= nil) and true or false,
          }
        })
      end
    end
  end)
end

local function aerospace_workspace_change(env)
  local focused = env.FOCUSED_WORKSPACE
  local previous = env.PREVIOUS_WORKSPACE

  space_current_focus = focused
  space_previous_focus = previous
end

trigger:subscribe("aerospace_workspace_change", aerospace_workspace_change) -- Triggered from aerospace
trigger:subscribe("aerospace_window_change", aerospace_update) -- Triggered from aerospace
trigger:subscribe("space_windows_change", aerospace_update) -- When a window is created or destroyed on a space
aerospace_update()
