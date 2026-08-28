local fonts = require("helpers.fonts")
local colors = require("helpers.colors")

-- Network monitoring state (stats_provider network stats are broken, use netstat directly)
local network_iface = "en0"
local prev_rx_bytes = nil
local prev_tx_bytes = nil

-- Format a throughput in kbit/s. Lua's "%d" rejects floats with a fractional part,
-- so the value is floored before it reaches the integer conversion.
local function format_rate(kbits)
    if kbits < 1000 then
        return string.format("%d Kbit/s", math.floor(kbits))
    end
    return string.format("%.1f Mbit/s", kbits / 1000)
end

-- Get primary network interface dynamically
sbar.exec("route -n get default 2>/dev/null | awk '/interface:/{print $2}'", function(primary_iface)
    primary_iface = primary_iface:gsub("%s+", "") -- trim whitespace
    if primary_iface ~= "" then
        network_iface = primary_iface
    end
end)

-- stats_provider exits as soon as it fails to reach sketchybar (e.g. while the bar
-- reloads), and a plain detached child would then stay dead until a manual restart.
-- The supervisor restarts it, and replaces its own stale instance on every reload.
local config_dir = os.getenv("HOME") .. "/.config/sketchybar"
sbar.exec(config_dir .. "/helpers/stats_provider_supervisor.sh >/dev/null 2>&1 &")

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
    -- The interface list is collected before the loop runs: piping it into `while`
    -- and breaking early closed the pipe under awk and logged an i/o error each tick.
    sbar.exec([[for dev in $(networksetup -listallhardwareports | awk '/Ethernet|LAN/{getline; print $2}'); do ifconfig "$dev" 2>/dev/null | grep -q "status: active" && { echo "connected"; break; }; done]], function(lan_result)
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
        cpu:set { label = string.format("%02d%%", math.floor(tonumber(env.CPU_USAGE) or 0)) }
    end
    if env.CPU_TEMP then
        temp:set { label = string.format("%02d°C", math.floor(tonumber(env.CPU_TEMP) or 0)) }
    end
    if env.RAM_USAGE then
        ram:set { label = string.format("%02d%%", math.floor(tonumber(env.RAM_USAGE) or 0)) }
    end
    -- Network stats via netstat (stats_provider network output is broken in v0.8.1)
    sbar.exec("netstat -I " .. network_iface .. " -b | awk 'NR==2{print $7, $10}'", function(result)
        local rx_str, tx_str = result:match("(%d+)%s+(%d+)")
        if rx_str and tx_str then
            local rx_bytes = tonumber(rx_str)
            local tx_bytes = tonumber(tx_str)
            local last_rx, last_tx = prev_rx_bytes, prev_tx_bytes

            -- Advance the baseline before formatting: a formatting error here used to
            -- abort the callback and freeze the baseline, inflating every later delta.
            prev_rx_bytes = rx_bytes
            prev_tx_bytes = tx_bytes

            if last_rx and last_tx then
                -- Counters are 32-bit on some interfaces and reset on link change;
                -- a negative delta means the counter wrapped, so skip that sample.
                local rx_delta = rx_bytes - last_rx
                local tx_delta = tx_bytes - last_tx
                if rx_delta >= 0 and tx_delta >= 0 then
                    downlink:set { label = format_rate(rx_delta * 8 / 1000) }
                    uplink:set { label = format_rate(tx_delta * 8 / 1000) }
                end
            end
        end
    end)
    if env.DISK_USAGE then
        disk:set { label = string.format("%02d%%", math.floor(tonumber(env.DISK_USAGE) or 0)) }
    end
    if env.HOST_NAME then
        hostname:set { label = env.HOST_NAME }
    end
    if env.UPTIME then
        uptime:set { label = env.UPTIME }
    end
end)
