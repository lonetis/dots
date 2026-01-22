local fonts = require("helpers.fonts")
local colors = require("helpers.colors")

-- Get primary network interface dynamically
sbar.exec("route -n get default 2>/dev/null | awk '/interface:/{print $2}'", function(primary_iface)
    primary_iface = primary_iface:gsub("%s+", "") -- trim whitespace
    if primary_iface == "" then
        primary_iface = "en0" -- fallback to en0
    end
    sbar.exec("killall stats_provider >/dev/null; $CONFIG_DIR/sketchybar-system-stats/target/release/stats_provider --battery percentage remaining state time_to_full --cpu count frequency temperature usage --disk count free total usage used --memory ram_available ram_total ram_usage ram_used swp_free swp_total swp_usage swp_used --network " .. primary_iface .. " --system arch distro host_name kernel_version name os_version long_os_version --uptime day hour --interval 1 --network-refresh-rate 1 --no-units &")
end)

local uptime = sbar.add("item", "uptime", {
    position = "right",
    padding_right = 5, -- last item needs right padding
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local hostname = sbar.add("item", "hostname", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local wifi = sbar.add("item", "wifi", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "󰖩",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local function update_wifi()
    -- Check for active ethernet/LAN connection (matches Ethernet adapters and USB LAN adapters)
    sbar.exec([[networksetup -listallhardwareports | awk '/Ethernet|LAN/{getline; print $2}' | while read dev; do [ -n "$dev" ] && ifconfig "$dev" 2>/dev/null | grep -q "status: active" && echo "connected" && break; done]], function(lan_result)
        local has_lan = lan_result:gsub("%s+", "") == "connected"

        sbar.exec("shortcuts run get-wlan-ssid", function(result)
            local ssid = result:gsub("^%s*(.-)%s*$", "%1")
            local has_wifi = ssid ~= ""
            local icon
            if has_lan and has_wifi then
                icon = "󰈀 󰖩"
            elseif has_lan then
                icon = "󰈀"
            elseif has_wifi then
                icon = "󰖩"
            else
                icon = "󰖪"
            end
            wifi:set { icon = { string = icon }, label = has_wifi and ssid or "" }
        end)
    end)
end

update_wifi()
wifi:subscribe("wifi_change", update_wifi)

local disk = sbar.add("item", "disk", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "󰋊",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local uplink = sbar.add("item", "uplink", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
        width = 120,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local downlink = sbar.add("item", "downlink", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
        width = 120,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local ram = sbar.add("item", "ram", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local temp = sbar.add("item", "temp", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

local cpu = sbar.add("item", "cpu", {
    position = "right",
    icon = {
        font = fonts.nerd,
        string = "",
    },
    label = {
        font = fonts.mono,
    },
    background = {
        drawing = true,
        border_color = colors.grey,
        border_width = 1,
    },
})

disk:subscribe("system_stats", function(env)
    if env.CPU_USAGE then
        cpu:set { label = string.format("%02d%%", tonumber(env.CPU_USAGE)) }
    end
    if env.CPU_TEMP then
        temp:set { label = string.format("%02d°C", math.floor(tonumber(env.CPU_TEMP))) }
    end
    if env.RAM_USAGE then
        ram:set { label = string.format("%02d%%", tonumber(env.RAM_USAGE)) }
    end
    -- Find network stats for any interface (supports en0, en1, etc.)
    for key, value in pairs(env) do
        if key:match("^NETWORK_RX_") then
            local rx_kbytes = tonumber(value)
            local rx_kbits = rx_kbytes * 8
            if rx_kbits < 1000 then
                downlink:set { label = string.format("%d Kbit/s", rx_kbits) }
            else
                downlink:set { label = string.format("%.1f Mbit/s", rx_kbits / 1000) }
            end
        elseif key:match("^NETWORK_TX_") then
            local tx_kbytes = tonumber(value)
            local tx_kbits = tx_kbytes * 8
            if tx_kbits < 1000 then
                uplink:set { label = string.format("%d Kbit/s", tx_kbits) }
            else
                uplink:set { label = string.format("%.1f Mbit/s", tx_kbits / 1000) }
            end
        end
    end
    if env.DISK_USAGE then
        disk:set { label = string.format("%02d%%", tonumber(env.DISK_USAGE)) }
    end
    if env.HOST_NAME then
        hostname:set { label = env.HOST_NAME }
    end
    if env.UPTIME then
        uptime:set { label = env.UPTIME }
    end
end)
