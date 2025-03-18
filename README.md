# Nursory

Nursory is a new kind of cursor—attempting to break free from the bonds of convention, it leans into a more abstract and intuitive design.

## Building

In order to build the Nursory cursor theme, an up-to-date installation of Inkscape is required. Besides this, only commands commonly available on most Linux systems are used.

Executing `./gen.sh` will build the cursor theme in the `dist` directory. From there, `dist` can be copied into a user-specific directory like `~/.local/share/icons/` or `~/.icons/` and ideally renamed for clarity, though the theme name contained in the theme configuration is what will show when changing cursor themes.

## Structure

The information required to build the cursor theme from source is contained entirely within the `.svg` files themselves. The source SVG can be split into multiple files as long as they're within the `source` directory, though currently there is only `source/cursors.svg`. Each cursor is defined in its own top-level layer (`<g>` elements). Each layer's label is formatted as:

```
(cursor-name) (hotspot-x) (hotspot-y) (animation-time)
```

The cursor names generally follow CSS cursor naming, but any valid name can be used (valid aliases can be found within `addmissing.sh`). The hot-spot coordinates are defined as fractions of ninety-six (for better divisibility but close parity with percentage). So a label with a hot-spot in the very center would contain `48 48` in the label. Animated cursors are handled slightly differently. Instead each layer is a new frame, ordered reverse-chronologically.