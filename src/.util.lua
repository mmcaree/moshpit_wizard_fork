util = {}

util.debug = false

util.dprint = function(string)
    if util.debug then
        print(string)
    end
end

util.count = function(table)
    local amount = 0
    for _ in pairs(table) do
        amount = amount + 1
    end
    return amount
end

-- exclusive
util.in_range = function(value, lower, upper)
    return (value > lower and value < upper)
end

util.toggle_ui_elements = function(toggle_state, elements, dialog)
    for _, element in pairs(elements) do
        dialog:modify({
            id = element,
            visible = toggle_state,
            enabled = toggle_state,
        })
    end
end

-- todo: put image first
-- returns a table where each element is a pixel of a row
util.get_row = function(row_number, image)
    local row = {}

    for x = 0, image.width - 1, 1 do
        table.insert(row, image:getPixel(x, row_number))
    end

    return row
end

-- returns a table where each element is a table representing a row
util.get_rows = function(starting_row, row_amount, image)
    local rows = {}
    for row_number = starting_row, starting_row + (row_amount - 1), 1 do
        table.insert(rows, util.get_row(row_number, image))
    end

    return rows
end

util.contains = function(table, value)
    for _, element in pairs(table) do
        if element == value then
            return true
        end
    end

    return false
end

-- Expand a cel's image to the given dimensions so out-of-bounds writes fit.
-- x_image_target / y_image_target: where the original image lands in the new image.
-- x_origin / y_origin: new cel position on the sprite.
util.expand_cel_bounds = function(
    cel,
    cel_width,
    cel_height,
    x_image_target,
    y_image_target,
    x_origin,
    y_origin
)
    local expanded_image = Image(cel_width, cel_height, cel.image.colorMode)
    expanded_image:drawImage(cel.image, x_image_target, y_image_target)
    cel.image = expanded_image
    cel.position = Point(x_origin, y_origin)

    return cel
end

-- True when the pixel at (x, y) in image is non-transparent.
-- Currently only reliable in RGB color mode.
util.is_opaque = function(image, x, y)
    if x < 0 or y < 0 or x >= image.width or y >= image.height then
        return false
    end
    local px = image:getPixel(x, y)
    return app.pixelColor.rgbaA(px) > 0
end

-- Returns a list of {x = , y = } points of non-transparent pixels that sit
-- adjacent to a transparent (or out-of-bounds) pixel, i.e. the logo's silhouette.
-- step samples every Nth pixel to keep this cheap on large sprites.
util.get_edge_pixels = function(image, step)
    step = step or 1
    local edges = {}
    for y = 0, image.height - 1, step do
        for x = 0, image.width - 1, step do
            if util.is_opaque(image, x, y) then
                if
                    not util.is_opaque(image, x - 1, y)
                    or not util.is_opaque(image, x + 1, y)
                    or not util.is_opaque(image, x, y - 1)
                    or not util.is_opaque(image, x, y + 1)
                then
                    table.insert(edges, { x = x, y = y })
                end
            end
        end
    end
    return edges
end

-- Draw a filled rectangle on image, clipped to bounds. color is a packed rgba int.
util.draw_rect = function(image, x, y, w, h, color)
    local x0 = math.max(0, x)
    local y0 = math.max(0, y)
    local x1 = math.min(image.width - 1, x + w - 1)
    local y1 = math.min(image.height - 1, y + h - 1)
    for py = y0, y1 do
        for px = x0, x1 do
            image:drawPixel(px, py, color)
        end
    end
end

-- Parse a hex string like "#ff00cc" or "ff00cc" into a packed rgba int.
util.hex_to_rgba = function(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return app.pixelColor.rgba(r, g, b, 255)
end

-- Pick a random element from a non-empty list.
util.random_choice = function(list)
    if #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

-- Assert RGB color mode; alerts and returns false on other modes.
util.require_rgb = function()
    if app.activeSprite.colorMode ~= ColorMode.RGB then
        app.alert("This effect requires RGB color mode.")
        return false
    end
    return true
end

return util
