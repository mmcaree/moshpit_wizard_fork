# Moshpit

An Aseprite tool for glitch art.

> **Fork notice**: This is a fork of the original [Moshpit by jgollenz](https://github.com/jgollenz/moshpit), maintained by [mmcaree](https://github.com/mmcaree). All credit for the original tool, pixel-shift, and pixel-sort effects goes to jgollenz. This fork adds animation-aware glitch effects (Glitch Blocks, Glitch Streaks, Chromatic Aberration, Scanlines) for producing animated glitch art such as looping logo animations.

## What's new in this fork

- **Glitch Blocks** — colored rectangle fragments scattered around your art's edges, with size presets and a customizable palette.
- **Glitch Streaks** — long, thin motion streaks with directional bias.
- **Chromatic Aberration** — per-channel R/G/B offset fringe.
- **Scanlines** — CRT-style horizontal lines with optional rolling animation.
- **Animate across frames** — every new effect can re-roll its randomization across a frame range, drawing each frame into a dedicated non-destructive layer so animated GIFs are easy to assemble.

## Installation

You need at least Aseprite v1.2.10 for this tool to work

1. Download `moshpit-[version].zip`
2. Unzip and move the `moshpit` folder into the Aseprite scripts folder. If you are unsure where that folder is located, you can open it with `File > Scripts > Open Scripts Folder` 

![alt text](https://github.com/jgollenz/moshpit/blob/main/img/open-scripts-folder.png)

3. Refresh the scripts with `File > Scripts > Rescan Scripts Folder`
4. Start the script with `File > Scripts > moshpit > moshpit`

![alt text](https://github.com/jgollenz/moshpit/blob/main/img/run-moshpit.png)

5. (optional) Navigate to `Edit > Keyboard Shortcuts` search for `moshpit`. Assign a hotkey of your choice  

## Effects

### Line shifting

![alt text](https://github.com/jgollenz/moshpit/blob/main/img/pixel-shift-preview.gif)

### Pixel sorting

DISCLAIMER: do NOT switch tabs while selecting the threshold. Currently not working correctly in Indexed and Grayscale mode

![alt text](https://github.com/jgollenz/moshpit/blob/main/img/pixel-sort-preview.gif)

### Glitch Blocks

Scatter small colored rectangles around the non-transparent edges of your art (or within a selection / across the whole canvas). Size presets match common glitch-art fragment sizes (Tiny 8×3, Small 25×6, Medium 60×10, Large 100×14) and you control density, horizontal-vs-vertical bias, and the palette. By default the blocks are drawn onto a dedicated `Glitch Blocks` layer so your original art is preserved.

### Glitch Streaks

Long, thin motion streaks that shoot away from the logo edges. Configure length and thickness ranges and a directional bias (Right / Left / Up / Down) so you can trail streaks off the arrow tip, cut them across the middle, etc. Drawn onto a dedicated `Glitch Streaks` layer by default.

### Chromatic Aberration

Splits the red, green, and blue channels with per-channel (dx, dy) offsets to create a fringe-like shift on edges. Supports mirrored R/B offsets for classic symmetric aberration.

### Scanlines

Adds horizontal CRT-style scanlines with configurable spacing, thickness, and darkness. Supports three modes: Darken (reduce brightness), Black (solid black rows), and Transparent (cut rows — useful on a separate scanlines layer).

## Animation workflow

Every new effect (Glitch Blocks, Glitch Streaks, Chromatic Aberration, Scanlines) has an **Animate across frames** checkbox plus `From` / `To` frame sliders. When enabled, the effect re-rolls its randomization for each frame in the range, producing a continuously glitching animation over the same base art.

Recipe for animating something like a Discord logo:

1. Draw your logo on frame 1 of its own layer (e.g. `Logo`).
2. In the timeline, duplicate the logo cel to every frame you want in the animation (e.g. 12 frames).
3. Open Moshpit and run each effect you want, enabling `Animate across frames` with the full frame range on each Apply. Blocks and streaks will stack on their own layers so you can re-run them as many times as you want.
4. Export as GIF via Aseprite's `File > Export Animated GIF`.

## Upcoming

- Vertical line shifting / pixel sorting
- Randomization
- Variable line thickness (for line shifting)
- V-sync issues / screen tearing
- Corruption artefacts

## Requesting features & reporting bugs

Have an idea for another glitch effect, or hit a bug? Please [open an issue on the fork's GitHub](https://github.com/mmcaree/moshpit_wizard_fork/issues) with:

- A short description of what you'd like to see (or what went wrong).
- For bugs: your Aseprite version, the color mode of your sprite (RGB / Indexed / Grayscale), and a screenshot or sample sprite if possible.

Pull requests are welcome too.

## Credits

- Original [Moshpit](https://github.com/jgollenz/moshpit) by **[jgollenz](https://github.com/jgollenz)** — Pixel Shift, Pixel Sort, dialog scaffolding, project foundation.
- Fork additions by **[mmcaree](https://github.com/mmcaree)** — Glitch Blocks, Glitch Streaks, Chromatic Aberration, Scanlines, frame-aware animation system.

