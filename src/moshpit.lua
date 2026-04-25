local util = dofile("./.util.lua")
local hsl = dofile("./.hsl.lua")
local palette = dofile("./.palette.lua")
local animator = dofile("./.animator.lua")
local shifter = dofile("./.shifter.lua")
local sorter = dofile("./.pixel_sorter.lua")
local blocks = dofile("./.blocks.lua")
local streaks = dofile("./.streaks.lua")
local chroma = dofile("./.chroma.lua")
local scanlines = dofile("./.scanlines.lua")

local cel = app.activeCel
if not cel then
    return app.alert("There is no active image")
end

glob = {}
glob.rgba = app.pixelColor.rgba

-- starting position / dimensions
-- todo: how can this be made adaptive?
local xAnchor = 100
local yAnchor = 50
local dialog_width = 180
local dialog_height = 180

local should_apply = false
sub_dialogs = {}

local dlg = Dialog({
    title = "Moshpit",
    onclose = function()
        if should_apply == false then
            app.refresh()
        else
            should_apply = false
        end

        for _, sub_dialog in pairs(sub_dialogs) do
            sub_dialog:close()
        end
    end,
})

-- Open / close a sub-dialog stored under sub_dialogs[key] using module.show.
local function toggle_sub_dialog(key, module)
    if sub_dialogs[key] == nil then
        local bounds = dlg.bounds
        local d = module.show(bounds.x, bounds.y + bounds.height)
        if d ~= nil then
            sub_dialogs[key] = d
        end
    else
        sub_dialogs[key]:close()
    end
end

dlg
    :button({
        id = "sort",
        text = "Pixel Sort",
        onclick = function()
            toggle_sub_dialog("sorter_dialog", sorter)
        end,
    })
    :button({
        id = "shift",
        text = "Pixel Shift",
        onclick = function()
            toggle_sub_dialog("shifter_dialog", shifter)
        end,
    })
    :newrow()
    :button({
        id = "blocks",
        text = "Glitch Blocks",
        onclick = function()
            toggle_sub_dialog("blocks_dialog", blocks)
        end,
    })
    :button({
        id = "streaks",
        text = "Glitch Streaks",
        onclick = function()
            toggle_sub_dialog("streaks_dialog", streaks)
        end,
    })
    :newrow()
    :button({
        id = "chroma",
        text = "Chromatic Aberration",
        onclick = function()
            toggle_sub_dialog("chroma_dialog", chroma)
        end,
    })
    :button({
        id = "scanlines",
        text = "Scanlines",
        onclick = function()
            toggle_sub_dialog("scanlines_dialog", scanlines)
        end,
    })
    :show({
        wait = false,
        bounds = Rectangle(xAnchor, yAnchor, dialog_width, dialog_height),
    })
