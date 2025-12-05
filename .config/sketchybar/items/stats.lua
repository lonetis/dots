local fonts = require("helpers.fonts")
local colors = require("helpers.colors")

sbar.exec("killall stats_provider >/dev/null; $CONFIG_DIR/sketchybar-system-stats/target/release/stats_provider --battery percentage remaining state time_to_full --cpu count frequency temperature usage --disk count free total usage used --memory ram_available ram_total ram_usage ram_used swp_free swp_total swp_usage swp_used --network en0 --system arch distro host_name kernel_version name os_version long_os_version --uptime day hour --interval 5 --network-refresh-rate 5 --no-units &")

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
    sbar.exec("shortcuts run get-wlan-ssid", function(result)
        local ssid = result:gsub("^%s*(.-)%s*$", "%1")
        if ssid == "" then
            wifi:set { label = "N/A" }
        else
            wifi:set { label = ssid }
        end
    end)
end

update_wifi()
wifi:subscribe("system_stats", update_wifi)

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
    if env.NETWORK_RX_en0 then
        local rx_kbytes = tonumber(env.NETWORK_RX_en0)
        local rx_kbits = rx_kbytes * 8
        if rx_kbits < 1000 then
            downlink:set { label = string.format("%d Kbit/s", rx_kbits) }
        else
            downlink:set { label = string.format("%.1f Mbit/s", rx_kbits / 1000) }
        end
    end
    if env.NETWORK_TX_en0 then
        local tx_kbytes = tonumber(env.NETWORK_TX_en0)
        local tx_kbits = tx_kbytes * 8
        if tx_kbits < 1000 then
            uplink:set { label = string.format("%d Kbit/s", tx_kbits) }
        else
            uplink:set { label = string.format("%.1f Mbit/s", tx_kbits / 1000) }
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
