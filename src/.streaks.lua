-- Glitch Streaks: long thin rectangles that shoot away from the logo,
-- giving the illusion of motion. Shares look-and-feel with .blocks.lua.

local dialog = -1

streaks = {}

local function build_anchor_pool(placement, source_cel)
    local anchors = {}
    if placement == "edges" and source_cel then
        local edges = util.get_edge_pixels(source_cel.image, 2)
        for _, p in ipairs(edges) do
            table.insert(anchors, {
                x = p.x + source_cel.position.x,
                y = p.y + source_cel.position.y,
            })
        end
    elseif placement == "selection" and not app.activeSprite.selection.isEmpty then
        local sel = app.activeSprite.selection.bounds
        for y = sel.y, sel.y + sel.height - 1, 3 do
            for x = sel.x, sel.x + sel.width - 1, 3 do
                table.insert(anchors, { x = x, y = y })
            end
        end
    end
    if #anchors == 0 then
        local sw = app.activeSprite.width
        local sh = app.activeSprite.height
        for y = 0, sh - 1, 6 do
            for x = 0, sw - 1, 6 do
                table.insert(anchors, { x = x, y = y })
            end
        end
    end
    return anchors
end

-- Weighted random pick among "right", "left", "up", "down".
local function pick_direction(data)
    local weights = {
        { dir = "right", w = data.bias_right },
        { dir = "left", w = data.bias_left },
        { dir = "up", w = data.bias_up },
        { dir = "down", w = data.bias_down },
    }
    local total = 0
    for _, e in ipairs(weights) do
        total = total + e.w
    end
    if total <= 0 then
        return "right"
    end
    local roll = math.random(1, total)
    local acc = 0
    for _, e in ipairs(weights) do
        acc = acc + e.w
        if roll <= acc then
            return e.dir
        end
    end
    return "right"
end

local function collect_palette(data)
    local colors = {}
    for i = 1, 6 do
        local c = data["color_" .. i]
        if c and c.alpha > 0 then
            table.insert(colors, app.pixelColor.rgba(c.red, c.green, c.blue, 255))
        end
    end
    if #colors == 0 then
        colors = palette.default_rgba()
    end
    return colors
end

streaks.draw = function(target_cel, anchor_pool, data)
    local img = target_cel.image:clone()
    local colors = collect_palette(data)
    for _ = 1, data.count do
        local anchor = util.random_choice(anchor_pool)
        local length = math.random(data.length_min, data.length_max)
        local thickness = math.random(data.thickness_min, data.thickness_max)
        local color = util.random_choice(colors)
        local dir = pick_direction(data)
        local w, h, x, y
        local ax = anchor.x - target_cel.position.x
        local ay = anchor.y - target_cel.position.y
        if dir == "right" then
            w, h, x, y = length, thickness, ax, ay - math.floor(thickness / 2)
        elseif dir == "left" then
            w, h, x, y =
                length, thickness, ax - length + 1, ay - math.floor(thickness / 2)
        elseif dir == "down" then
            w, h, x, y = thickness, length, ax - math.floor(thickness / 2), ay
        else -- up
            w, h, x, y =
                thickness, length, ax - math.floor(thickness / 2), ay - length + 1
        end
        util.draw_rect(img, x, y, w, h, color)
    end
    target_cel.image = img
end

streaks.show = function(x, y)
    if not util.require_rgb() then
        return nil
    end

    local source_layer = app.activeLayer
    local source_cel = app.activeCel
    local sprite = app.activeSprite
    local animated_backups = {}

    local new_dialog = Dialog({
        title = "Glitch Streaks",
        onclose = function()
            if should_apply == false then
                for frame_num, entry in pairs(animated_backups) do
                    local cel = entry.layer:cel(frame_num)
                    if cel then
                        cel.image = entry.image
                        cel.position = entry.position
                    end
                end
                app.refresh()
            else
                should_apply = false
            end
            sub_dialogs.streaks_dialog = nil
        end,
    })

    dialog = new_dialog

    dialog
        :separator({ text = "Placement" })
        :radio({
            id = "placement_edges",
            label = "Where",
            text = "Around logo edges",
            selected = true,
        })
        :radio({ id = "placement_selection", text = "Within selection" })
        :radio({ id = "placement_canvas", text = "Whole canvas" })
        :separator({ text = "Size" })
        :slider({ id = "count", label = "Count", min = 1, max = 200, value = 20 })
        :slider({
            id = "length_min",
            label = "Length min",
            min = 10,
            max = 400,
            value = 60,
        })
        :slider({
            id = "length_max",
            label = "Length max",
            min = 10,
            max = 400,
            value = 200,
        })
        :slider({
            id = "thickness_min",
            label = "Thick min",
            min = 1,
            max = 20,
            value = 2,
        })
        :slider({
            id = "thickness_max",
            label = "Thick max",
            min = 1,
            max = 20,
            value = 5,
        })
        :separator({ text = "Direction bias" })
        :slider({ id = "bias_right", label = "Right", min = 0, max = 10, value = 5 })
        :slider({ id = "bias_left", label = "Left", min = 0, max = 10, value = 3 })
        :slider({ id = "bias_up", label = "Up", min = 0, max = 10, value = 1 })
        :slider({ id = "bias_down", label = "Down", min = 0, max = 10, value = 1 })
        :separator({ text = "Palette" })

    for i, hex in ipairs(palette.default_hex) do
        dialog:color({
            id = "color_" .. i,
            color = Color({
                r = tonumber(hex:sub(2, 3), 16),
                g = tonumber(hex:sub(4, 5), 16),
                b = tonumber(hex:sub(6, 7), 16),
                a = 255,
            }),
        })
        if i % 3 == 0 then
            dialog:newrow()
        end
    end

    dialog
        :separator({ text = "Layer" })
        :check({
            id = "use_new_layer",
            text = "Draw on 'Glitch Streaks' layer",
            selected = true,
        })
        :separator({ text = "Animation" })
        :check({ id = "animate", text = "Animate across frames", selected = false })
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

    local function placement_mode(data)
        if data.placement_edges then
            return "edges"
        elseif data.placement_selection then
            return "selection"
        else
            return "canvas"
        end
    end

    local function resolve_target_layer(data)
        if data.use_new_layer then
            return animator.get_or_create_layer("Glitch Streaks")
        end
        return source_layer
    end

    local function run_once(target_cel, source_image_cel)
        local data = dialog.data
        local anchors = build_anchor_pool(placement_mode(data), source_image_cel)
        -- normalize min/max in case user inverted them
        if data.length_min > data.length_max then
            data.length_min, data.length_max = data.length_max, data.length_min
        end
        if data.thickness_min > data.thickness_max then
            data.thickness_min, data.thickness_max =
                data.thickness_max, data.thickness_min
        end
        streaks.draw(target_cel, anchors, data)
    end

    dialog
        :button({
            id = "preview",
            text = "Preview",
            onclick = function()
                local data = dialog.data
                local target_layer = resolve_target_layer(data)
                local target_cel = animator.get_or_create_cel(
                    target_layer,
                    app.activeFrame.frameNumber
                )
                if not animated_backups[app.activeFrame.frameNumber] then
                    animated_backups[app.activeFrame.frameNumber] = {
                        layer = target_layer,
                        image = target_cel.image:clone(),
                        position = Point(target_cel.position.x, target_cel.position.y),
                    }
                end
                -- restore from backup before drawing so previews don't stack
                local backup = animated_backups[app.activeFrame.frameNumber]
                target_cel.image = backup.image:clone()
                target_cel.position = backup.position
                run_once(target_cel, source_cel)
                app.refresh()
            end,
        })
        :newrow()
        :button({
            id = "reset",
            text = "Reset",
            onclick = function()
                for frame_num, entry in pairs(animated_backups) do
                    local cel = entry.layer:cel(frame_num)
                    if cel then
                        cel.image = entry.image
                        cel.position = entry.position
                    end
                end
                animated_backups = {}
                app.refresh()
            end,
        })
        :button({
            id = "apply",
            text = "Apply",
            onclick = function()
                local data = dialog.data
                local target_layer = resolve_target_layer(data)
                if data.animate then
                    animator.run_across_frames(
                        data.from_frame,
                        data.to_frame,
                        target_layer,
                        function(cel, frame_num)
                            if not animated_backups[frame_num] then
                                animated_backups[frame_num] = {
                                    layer = target_layer,
                                    image = cel.image:clone(),
                                    position = Point(cel.position.x, cel.position.y),
                                }
                            end
                            animator.clear_cel(cel)
                            local src = source_layer:cel(frame_num) or source_cel
                            run_once(cel, src)
                        end
                    )
                else
                    local target_cel = animator.get_or_create_cel(
                        target_layer,
                        app.activeFrame.frameNumber
                    )
                    run_once(target_cel, source_cel)
                end
                animated_backups = {}
                app.refresh()
            end,
        })
        :show({ wait = false })

    return dialog
end

return streaks
