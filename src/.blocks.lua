-- Glitch Blocks: scatter horizontal/vertical colored rectangles around the logo.
-- Mirrors the shifter module pattern (backup_img + Preview/Reset/Apply).

local dialog = -1

blocks = {}

local SIZE_PRESETS = {
    tiny = { w = 8, h = 3, label = "Tiny 8x3" },
    small = { w = 25, h = 6, label = "Small 25x6" },
    medium = { w = 60, h = 10, label = "Medium 60x10" },
    large = { w = 100, h = 14, label = "Large 100x14" },
}

-- Build the list of candidate anchor points for block origins based on placement mode.
-- source_cel is the logo cel (used for edge detection).
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
        for y = sel.y, sel.y + sel.height - 1, 2 do
            for x = sel.x, sel.x + sel.width - 1, 2 do
                table.insert(anchors, { x = x, y = y })
            end
        end
    end
    if #anchors == 0 then
        -- Fall back to whole canvas.
        local sw = app.activeSprite.width
        local sh = app.activeSprite.height
        for y = 0, sh - 1, 4 do
            for x = 0, sw - 1, 4 do
                table.insert(anchors, { x = x, y = y })
            end
        end
    end
    return anchors
end

local function collect_enabled_sizes(data)
    local sizes = {}
    for key, preset in pairs(SIZE_PRESETS) do
        if data["size_" .. key] then
            table.insert(sizes, { w = preset.w, h = preset.h })
        end
    end
    if #sizes == 0 then
        table.insert(sizes, { w = 25, h = 6 })
    end
    return sizes
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

-- Draw `count` blocks onto target_cel, sampling anchors from anchor_pool.
blocks.draw = function(target_cel, anchor_pool, count, sizes, colors, horizontal_pct)
    local img = target_cel.image:clone()
    for _ = 1, count do
        local anchor = util.random_choice(anchor_pool)
        local size = util.random_choice(sizes)
        local color = util.random_choice(colors)
        local w, h = size.w, size.h
        if math.random(1, 100) > horizontal_pct then
            w, h = size.h, size.w -- rotate to vertical
        end
        -- jitter off the anchor a little so blocks don't all sit on the exact edge
        local jx = math.random(-math.floor(w / 2), math.floor(w / 2))
        local jy = math.random(-math.floor(h / 2), math.floor(h / 2))
        local x = anchor.x - target_cel.position.x + jx - math.floor(w / 2)
        local y = anchor.y - target_cel.position.y + jy - math.floor(h / 2)
        util.draw_rect(img, x, y, w, h, color)
    end
    target_cel.image = img
end

blocks.show = function(x, y)
    if not util.require_rgb() then
        return nil
    end

    local source_layer = app.activeLayer
    local source_cel = app.activeCel
    local sprite = app.activeSprite
    local backup_img = source_cel and source_cel.image:clone() or nil

    -- per-frame backups used when resetting an animated apply
    local animated_backups = {}

    local new_dialog = Dialog({
        title = "Glitch Blocks",
        onclose = function()
            if should_apply == false then
                -- restore any modified cels
                for frame_num, entry in pairs(animated_backups) do
                    local cel = entry.layer:cel(frame_num)
                    if cel then
                        cel.image = entry.image
                        cel.position = entry.position
                    end
                end
                if source_cel and backup_img then
                    source_cel.image = backup_img
                end
                app.refresh()
            else
                should_apply = false
            end

            sub_dialogs.blocks_dialog = nil
        end,
    })

    dialog = new_dialog

    local defaults = palette.default_hex
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
        :separator({ text = "Sizes" })
        :check({ id = "size_tiny", text = SIZE_PRESETS.tiny.label, selected = true })
        :check({ id = "size_small", text = SIZE_PRESETS.small.label, selected = true })
        :check({
            id = "size_medium",
            text = SIZE_PRESETS.medium.label,
            selected = true,
        })
        :check({ id = "size_large", text = SIZE_PRESETS.large.label, selected = false })
        :separator({ text = "Density & orientation" })
        :slider({ id = "count", label = "Count", min = 1, max = 400, value = 60 })
        :slider({
            id = "horizontal_pct",
            label = "Horizontal %",
            min = 0,
            max = 100,
            value = 90,
        })
        :separator({ text = "Palette" })
    for i, hex in ipairs(defaults) do
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
            text = "Draw on 'Glitch Blocks' layer",
            selected = true,
        })
        :separator({ text = "Animation" })
        :check({
            id = "animate",
            text = "Animate across frames (re-roll per frame)",
            selected = false,
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

    local function placement_mode(data)
        if data.placement_edges then
            return "edges"
        elseif data.placement_selection then
            return "selection"
        else
            return "canvas"
        end
    end

    local function run_once(target_cel, source_image_cel)
        local data = dialog.data
        local anchors = build_anchor_pool(placement_mode(data), source_image_cel)
        local sizes = collect_enabled_sizes(data)
        local colors = collect_palette(data)
        blocks.draw(
            target_cel,
            anchors,
            data.count,
            sizes,
            colors,
            data.horizontal_pct
        )
    end

    local function resolve_target_layer(data)
        if data.use_new_layer then
            return animator.get_or_create_layer("Glitch Blocks")
        end
        return source_layer
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
                -- stash backup for this frame if we haven't yet
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
                if source_cel and backup_img then
                    source_cel.image = backup_img
                end
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
                            -- re-roll: clear then draw on a fresh cel
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
                    if not animated_backups[app.activeFrame.frameNumber] then
                        animated_backups[app.activeFrame.frameNumber] = {
                            layer = target_layer,
                            image = target_cel.image:clone(),
                            position = Point(
                                target_cel.position.x,
                                target_cel.position.y
                            ),
                        }
                    end
                    run_once(target_cel, source_cel)
                end
                -- commit backups so close() doesn't undo
                animated_backups = {}
                if source_cel then
                    backup_img = source_cel.image:clone()
                end
                app.refresh()
            end,
        })
        :show({ wait = false })

    return dialog
end

return blocks
