-- Bar readout of CPU, GPU, memory, storage and network; a click opens the default style's stats panel.

local look = require("../lib/look")
local stats = require("../lib/stats")

local HOT = 90

local function usage(ctx: Context, symbol: string, value: number?)
    return ui.row{ gap = 4 * look.scale(ctx),
        look.glyph{ name = symbol, size = look.px(ctx, "symbol"),
            color = if value and value >= HOT then "warning" else nil },
        look.text{ text = if value then ctx.format.percent(value / 100) else "—", size = look.px(ctx, "text"),
            reserve = ctx.format.percent(1) } }
end

local function rate(ctx: Context, symbol: string, bytes: number?)
    return ui.row{ gap = 2 * look.scale(ctx),
        look.glyph{ name = symbol, size = look.px(ctx, "small") },
        look.text{ text = ctx.format.bytes(bytes or 0, "file") .. "/s", size = look.px(ctx, "text"),
            reserve = "00.0 MB/s" } }
end

function render(ctx: Context)
    local data = ctx.data
    local network = data.network
    return look.bar(ctx, { gap = 12 * look.scale(ctx), onClick = ui.popout,
        help = omniwm.l10n("Show system stats"),
        usage(ctx, "cpu", data.cpu),
        usage(ctx, "cube", data.gpu),
        usage(ctx, "memorychip", data.memory),
        usage(ctx, "internaldrive", data.disk),
        rate(ctx, "arrow.down", network and network.down),
        rate(ctx, "arrow.up", network and network.up) })
end

function popout(ctx: Context)
    return stats.popout(ctx)
end
