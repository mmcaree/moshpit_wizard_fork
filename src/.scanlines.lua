-- Scanlines: darken / blacken / cut every Nth row to evoke a CRT look.
-- Optionally rolls the offset per frame for a vertical-sync feel.

local dialog = -1

scanlines = {}

local function apply_row(img, y, mode, darkness, overlay)
    if mode == "transparent" then
        for x = 0, img.width - 1 do
            img:drawPixel(x, y, app.pixelColor.rgba(0, 0, 0, 0))
        end
    elseif overlay then
        -- Standalone overlay: paint black rows with alpha = darkness%.
        -- In "black" mode always fully opaque; in "darken" mode alpha scales with darkness.
        local alpha = mode == "black" and 255
            or math.floor((darkness / 100) * 255)
        if alpha <= 0 then
            return
        end
        for x = 0, img.width - 1 do
            img:drawPixel(x, y, app.pixelColor.rgba(0, 0, 0, alpha))
        end
    elseif mode == "black" then
        for x = 0, img.width - 1 do
            local px = img:getPixel(x, y)
            local a = app.pixelColor.rgbaA(px)
            if a > 0 then
                img:drawPixel(x, y, app.pixelColor.rgba(0, 0, 0, a))
            end
        end
    else -- darken existing pixels
        local k = (100 - darkness) / 100
        for x = 0, img.width - 1 do
            local px = img:getPixel(x, y)
            local a = app.pixelColor.rgbaA(px)
            if a > 0 then
                local r = math.floor(app.pixelColor.rgbaR(px) * k)
                local g = math.floor(app.pixelColor.rgbaG(px) * k)
                local b = math.floor(app.pixelColor.rgbaB(px) * k)
                img:drawPixel(x, y, app.pixelColor.rgba(r, g, b, a))
            end
        end
    end
end

scanlines.apply = function(
    target_cel,
    spacing,
    thickness,
    darkness,
    mode,
    offset,
    overlay
)
    local src = target_cel.image:clone()
    spacing = math.max(1, spacing)
    thickness = math.max(1, thickness)
    local y = offset % spacing
    while y < src.height do
        for t = 0, thickness - 1 do
            if y + t < src.height then
                apply_row(src, y + t, mode, darkness, overlay)
            end
        end
        y = y + spacing
    end
    target_cel.image = src
end

scanlines.show = function(x, y)
    if not util.require_rgb() then
        return nil
    end

    local source_cel = app.activeCel
    local source_layer = app.activeLayer
    local sprite = app.activeSprite
    local backups = {}

    local function resolve_layer(data)
        if data.use_new_layer then
            return animator.get_or_create_layer("Scanlines")
        end
        return source_layer
    end

    local function stash(layer, frame_num, cel)
        local key = layer.name .. ":" .. frame_num
        if not backups[key] then
            backups[key] = {
                layer = layer,
                frame = frame_num,
                image = cel.image:clone(),
                position = Point(cel.position.x, cel.position.y),
            }
        end
    end

    local function restore_all()
        for _, entry in pairs(backups) do
            local cel = entry.layer:cel(entry.frame)
            if cel then
                cel.image = entry.image
                cel.position = entry.position
            end
        end
        backups = {}
    end

    local new_dialog = Dialog({
        title = "Scanlines",
        onclose = function()
            if should_apply == false then
                restore_all()
                app.refresh()
            else
                should_apply = false
            end
            sub_dialogs.scanlines_dialog = nil
        end,
    })

    dialog = new_dialog

    dialog
        :slider({ id = "spacing", label = "Spacing", min = 1, max = 20, value = 3 })
        :slider({ id = "thickness", label = "Thickness", min = 1, max = 10, value = 1 })
        :slider({
            id = "darkness",
            label = "Darkness %",
            min = 0,
            max = 100,
            value = 60,
        })
        :separator({ text = "Mode" })
        :radio({
            id = "mode_darken",
            label = "Mode",
            text = "Darken",
            selected = true,
        })
        :radio({ id = "mode_black", text = "Black" })
        :radio({ id = "mode_transparent", text = "Transparent" })
        :separator({ text = "Layer" })
        :check({
            id = "use_new_layer",
            text = "Draw on 'Scanlines' layer",
            selected = false,
        })
        :separator({ text = "Animation" })
        :check({ id = "animate", text = "Animate across frames", selected = false })
        :check({
            id = "roll",
            text = "Roll offset per frame (CRT)",
            selected = true,
        })
        :slider({
            id = "roll_speed",
            label = "Roll speed",
            min = 1,
            max = 20,
            value = 2,
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

    local function mode(data)
        if data.mode_black then
            return "black"
        elseif data.mode_transparent then
            return "transparent"
        else
            return "darken"
        end
    end

    local function apply_to(target_cel, offset, overlay)
        local data = dialog.data
        scanlines.apply(
            target_cel,
            data.spacing,
            data.thickness,
            data.darkness,
            mode(data),
            offset,
            overlay
        )
    end

    -- Replace a cel's image with a blank sprite-sized image so overlay rows have a full canvas to paint on.
    local function blank_cel(cel)
        local spec = app.activeSprite.spec
        cel.image = Image(spec.width, spec.height, spec.colorMode)
        cel.position = Point(0, 0)
    end

    dialog
        :button({
            id = "preview",
            text = "Preview",
            onclick = function()
                local data = dialog.data
                local target_layer = resolve_layer(data)
                local target_cel
                local overlay = data.use_new_layer
                if overlay then
                    target_cel = animator.get_or_create_cel(
                        target_layer,
                        app.activeFrame.frameNumber
                    )
                    stash(target_layer, app.activeFrame.frameNumber, target_cel)
                    blank_cel(target_cel)
                else
                    target_cel = source_cel
                    if not target_cel then
                        return
                    end
                    stash(target_layer, app.activeFrame.frameNumber, target_cel)
                    target_cel.image = backups[target_layer.name
                        .. ":"
                        .. app.activeFrame.frameNumber].image:clone()
                end
                apply_to(target_cel, 0, overlay)
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
                local target_layer = resolve_layer(data)
                local overlay = data.use_new_layer
                if data.animate then
                    animator.run_across_frames(
                        data.from_frame,
                        data.to_frame,
                        target_layer,
                        function(cel, frame_num)
                            stash(target_layer, frame_num, cel)
                            if overlay then
                                blank_cel(cel)
                            end
                            local speed = data.roll_speed
                            if not speed or speed < 1 then
                                speed = 1
                            end
                            local offset = data.roll
                                    and ((frame_num - 1) * speed)
                                or 0
                            apply_to(cel, offset, overlay)
                        end
                    )
                else
                    local target_cel
                    if overlay then
                        target_cel = animator.get_or_create_cel(
                            target_layer,
                            app.activeFrame.frameNumber
                        )
                        stash(target_layer, app.activeFrame.frameNumber, target_cel)
                        blank_cel(target_cel)
                    else
                        target_cel = source_cel
                        if target_cel then
                            stash(
                                target_layer,
                                app.activeFrame.frameNumber,
                                target_cel
                            )
                        end
                    end
                    if target_cel then
                        apply_to(target_cel, 0, overlay)
                    end
                end
                backups = {}
                app.refresh()
            end,
        })
        :show({ wait = false })

    return dialog
end

return scanlines
