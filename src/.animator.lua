-- Animation helpers: run an effect across a range of frames on a target layer.
-- Creates the layer / cel if missing so the user's base artwork stays intact.

animator = {}

-- Find a layer by name or create a new empty one. Returns the Layer.
animator.get_or_create_layer = function(name)
    for _, layer in ipairs(app.activeSprite.layers) do
        if layer.name == name then
            return layer
        end
    end
    local layer = app.activeSprite:newLayer()
    layer.name = name
    return layer
end

-- Get the cel on layer at frame_number, creating an empty sprite-sized cel if none.
animator.get_or_create_cel = function(layer, frame_number)
    local cel = layer:cel(frame_number)
    if cel then
        return cel
    end
    local spec = app.activeSprite.spec
    local img = Image(spec.width, spec.height, spec.colorMode)
    return app.activeSprite:newCel(layer, frame_number, img, Point(0, 0))
end

-- Clear any previous content on a cel (used so re-applies don't stack).
animator.clear_cel = function(cel)
    local spec = app.activeSprite.spec
    cel.image = Image(spec.width, spec.height, spec.colorMode)
    cel.position = Point(0, 0)
end

-- Run effect_fn(cel, frame_number) for each frame in [from_frame, to_frame].
-- The active frame is restored when done.
animator.run_across_frames = function(from_frame, to_frame, layer, effect_fn)
    local original_frame = app.activeFrame.frameNumber
    local sprite = app.activeSprite
    local last_frame = #sprite.frames

    local lo = math.max(1, math.min(from_frame, to_frame))
    local hi = math.min(last_frame, math.max(from_frame, to_frame))

    for f = lo, hi do
        app.activeFrame = sprite.frames[f]
        local cel = animator.get_or_create_cel(layer, f)
        effect_fn(cel, f)
    end

    app.activeFrame = sprite.frames[original_frame]
    app.refresh()
end

return animator
