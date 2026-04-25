-- Default neon glitch palette (hot pink, cyan, yellow, green, red, blue).
-- Returned as packed rgba ints via util.hex_to_rgba.

palette = {}

palette.default_hex = {
    "#ff00cc",
    "#00eaff",
    "#fff200",
    "#00ff5a",
    "#ff0033",
    "#005bff",
}

palette.default_rgba = function()
    local colors = {}
    for _, hex in ipairs(palette.default_hex) do
        table.insert(colors, util.hex_to_rgba(hex))
    end
    return colors
end

return palette
