-- Chromatic Aberration: split R/G/B channels with per-channel offsets on the
-- active cel. Operates in-place on the active layer (no new layer created).

local dialog = -1

chroma = {}

local function sample_channel(image, x, y, channel)
    if x < 0 or y < 0 or x >= image.width or y >= image.height then
        return 0, 0
    end
    local px = image:getPixel(x, y)
    local a = app.pixelColor.rgbaA(px)
    if channel == "r" then
        return app.pixelColor.rgbaR(px), a
    elseif channel == "g" then
        return app.pixelColor.rgbaG(px), a
    else
        return app.pixelColor.rgbaB(px), a
    end
end

-- Build a new image by sampling each channel from offset coordinates.
chroma.apply = function(target_cel, rdx, rdy, gdx, gdy, bdx, bdy)
    local src = target_cel.image
    local out = Image(src.width, src.height, src.colorMode)
    for y = 0, src.height - 1 do
        for x = 0, src.width - 1 do
            local r = sample_channel(src, x - rdx, y - rdy, "r")
            local g, ga = sample_channel(src, x - gdx, y - gdy, "g")
            local b = sample_channel(src, x - bdx, y - bdy, "b")
            local _, a0 = sample_channel(src, x, y, "r")
            local a = math.max(a0, ga)
            if a > 0 then
                out:drawPixel(x, y, app.pixelColor.rgba(r, g, b, a))
            end
        end
    end
    target_cel.image = out
end

chroma.show = function(x, y)
    if not util.require_rgb() then
        return nil
    end

    local source_cel = app.activeCel
    local source_layer = app.activeLayer
    local sprite = app.activeSprite
    local backups = {}

    local function stash(frame_num, cel)
        if not backups[frame_num] then
            backups[frame_num] = {
                image = cel.image:clone(),
                position = Point(cel.position.x, cel.position.y),
            }
        end
    end

    local function restore_all()
        for frame_num, entry in pairs(backups) do
            local cel = source_layer:cel(frame_num)
            if cel then
                cel.image = entry.image
                cel.position = entry.position
            end
        end
        backups = {}
    end

    local new_dialog = Dialog({
        title = "Chromatic Aberration",
        onclose = function()
            if should_apply == false then
                restore_all()
                app.refresh()
            else
                should_apply = false
            end
            sub_dialogs.chroma_dialog = nil
        end,
    })

    dialog = new_dialog

    dialog
        :separator({ text = "Red channel" })
        :slider({ id = "r_dx", label = "dx", min = -30, max = 30, value = 3 })
        :slider({ id = "r_dy", label = "dy", min = -30, max = 30, value = 0 })
        :separator({ text = "Green channel" })
        :slider({ id = "g_dx", label = "dx", min = -30, max = 30, value = 0 })
        :slider({ id = "g_dy", label = "dy", min = -30, max = 30, value = 0 })
        :separator({ text = "Blue channel" })
        :slider({ id = "b_dx", label = "dx", min = -30, max = 30, value = -3 })
        :slider({ id = "b_dy", label = "dy", min = -30, max = 30, value = 0 })
        :check({
            id = "mirror_rb",
            text = "Mirror R/B (B = -R)",
            selected = false,
        })
        :separator({ text = "Animation" })
        :check({ id = "animate", text = "Animate across frames", selected = false })
        :check({
            id = "jitter",
            text = "Per-frame jitter (+/- 1 px)",
            selected = true,
        })
        :slider({
            id = "from_frame",
            label = "From",
            min = 1,
            max = #sprite.frames,
            value = 1,
        })
        :slider({
            id = "to_frame",
            label = "To",
            min = 1,
            max = #sprite.frames,
            value = #sprite.frames,
        })
        :separator()

    local function offsets(data, frame_jitter)
        local rdx, rdy = data.r_dx, data.r_dy
        local gdx, gdy = data.g_dx, data.g_dy
        local bdx, bdy = data.b_dx, data.b_dy
        if data.mirror_rb then
            bdx, bdy = -rdx, -rdy
        end
        if frame_jitter then
            rdx = rdx + math.random(-1, 1)
            rdy = rdy + math.random(-1, 1)
            bdx = bdx + math.random(-1, 1)
            bdy = bdy + math.random(-1, 1)
        end
        return rdx, rdy, gdx, gdy, bdx, bdy
    end

    dialog
        :button({
            id = "preview",
            text = "Preview",
            onclick = function()
                if not source_cel then
                    return
                end
                stash(app.activeFrame.frameNumber, source_cel)
                -- restore first so slider changes re-apply from the original
                source_cel.image = backups[app.activeFrame.frameNumber].image:clone()
                local rdx, rdy, gdx, gdy, bdx, bdy = offsets(dialog.data, false)
                chroma.apply(source_cel, rdx, rdy, gdx, gdy, bdx, bdy)
                app.refresh()
            end,
        })
        :newrow()
        :button({
            id = "reset",
            text = "Reset",
            onclick = function()
                restore_all()
                app.refresh()
            end,
        })
        :button({
            id = "apply",
            text = "Apply",
            onclick = function()
                local data = dialog.data
                if data.animate then
                    animator.run_across_frames(
                        data.from_frame,
                        data.to_frame,
                        source_layer,
                        function(cel, frame_num)
                            stash(frame_num, cel)
                            cel.image = backups[frame_num].image:clone()
                            local rdx, rdy, gdx, gdy, bdx, bdy =
                                offsets(data, data.jitter)
                            chroma.apply(cel, rdx, rdy, gdx, gdy, bdx, bdy)
                        end
                    )
                elseif source_cel then
                    stash(app.activeFrame.frameNumber, source_cel)
                    source_cel.image =
                        backups[app.activeFrame.frameNumber].image:clone()
                    local rdx, rdy, gdx, gdy, bdx, bdy = offsets(data, false)
                    chroma.apply(source_cel, rdx, rdy, gdx, gdy, bdx, bdy)
                end
                backups = {}
                app.refresh()
            end,
        })
        :show({ wait = false })

    return dialog
end

return chroma
