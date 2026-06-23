# Nursory

![Nursory Preview](https://raw.githubusercontent.com/frigorific44/Nursory/refs/heads/main/preview.webp)

Nursory is a new kind of cursor, attempting to rethink convention and lean into a more abstract design.

I've abided by several tenants developed over the course of its creation. The first is there must be no midtones used—only black and white. This is for easy programmatic recoloring, and ensures strongly distinguished shapes. The second tenant is no hands. Historically, the hand and the arrow have held the same meaning, and in early graphical computers, either the hand or the arrow would be used. For me, the compromise of using both for slightly differentiated meanings is an unsatisfying solution. Therefore, no hands. The final tenant is that each cursor should be singular in its form; more than a layered composition, additions to refine the meaning should be incorporated into the original shape. So a cursor like `context-menu` (though little used) incorporates the menu symbol inside the body of the puck rather than tacking it on outside.

A major consequence of these restrictions is that for several cursors, movement is relied upon to convey their function to the user. Also, in order to have space within the arrow's body, it has been further simplified. The arrow, having lost its fletching, now losses the shaft. Rounded, it's merely a puck. Embrace the puck.

## Building

In order to build the Nursory cursor theme, an up-to-date installation of Inkscape is required. Besides this, only commands commonly available on most Linux systems are used.

Executing `./gen.sh` will build the cursor theme in the `dist` directory. From there, `dist` can be copied or sym-linked into a user-specific directory like `~/.local/share/icons/` or `~/.icons/` and ideally renamed for clarity, though the theme name contained in the theme configuration is what will show when changing cursor themes.

### Dependencies

The `gen.sh` scripts requires `imagemagick`, `webpmux`, `xorg-xcursorgen`, and `xml` from XMLStarlet.

## Structure

The information required to build the cursor theme from source is contained entirely within the `.svg` files themselves. Each cursor is defined in its own top-level layer (`<g>` elements). Each layer's label is formatted as:

```
(cursor-name) (hotspot-x) (hotspot-y) (animation-time)
```

The cursor names generally follow CSS cursor naming, but any valid name can be used (valid aliases can be found within `addmissing.sh`). The hot-spot coordinates are defined as fractions of ninety-six (for better divisibility but close parity with percentage). So a label with a hot-spot in the very center would contain `48 48` in the label. Animated cursors are handled slightly differently. Each layer is a new frame, ordered reverse-chronologically.
