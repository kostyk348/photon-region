## Photon Region — Tile-Based Region Algebra for Wayland Compositors

A clean-room reimplementation of QNX Photon microGUI tile/region clipping,
optimized for **occlusion culling** in Wayland compositors (weston, wlroots).

Photon Region tracks dirty regions as linked lists of non-overlapping rectangles
(**tiles**) instead of pixman's region boxes. This gives:

- **Exact visible tile lists** per view — skip compositing fully occluded windows
- **~2.7x faster** subtract/intersect, **~1.7x faster** union vs pixman on desktop loads
- **~1.45x faster** end-to-end on 20-window scene cycles
- **Zero pixman dependency** for the core library (benchmarks除外)

### Quick Start

```sh
make        # build everything
make test   # run unit tests
make bench  # run pixman comparison benchmarks (requires pixman-1)
make demo   # run Weston-style repaint demo
```

### Core API

```c
#include "ph_region.h"

// Create a tile from a rectangle
pr_tile_t *t = pr_rect_to_tile((pr_rect_t){{0,0},{1919,1079}});

// Occlusion culling: visible tiles behind opaque windows
pr_tile_t *visible = pr_calculate_visible_tiles(region, opaque_list);

// Boolean operations
pr_tile_t *diff  = pr_subtract_tilings(a, b);
pr_tile_t *inter = pr_intersect_tilings(a, b, NULL);
pr_tile_t *union = pr_merge_tiles(a, b);
pr_tile_t *merged = pr_coalesce_tiles(union);  // merge adjacent tiles

// Memory: thread-local freelist, zero-malloc steady state
pr_free_tiles(tiles);
```

### Types

| Type | Description |
|------|-------------|
| `pr_point_t` | `{int16_t x, y}` |
| `pr_rect_t` | `{pr_point_t ul, lr}` — upper-left / lower-right |
| `pr_tile_t` | `{pr_rect_t rect; pr_tile_t *next}` — linked list node |

### Operations

| Function | Description |
|----------|-------------|
| `pr_calculate_visible_tiles()` | Occlusion culling — the key function |
| `pr_subtract_tilings()` | A minus B (tile lists) |
| `pr_intersect_tilings()` | A intersect B |
| `pr_merge_tiles()` | Concatenate two lists |
| `pr_coalesce_tiles()` | Merge adjacent/overlapping tiles |
| `pr_clip_tilings()` | Subtract with optional intersection output |
| `pr_translate_tiles()` | Offset all tiles by (dx, dy) |

### Integration

Ready-to-apply patches for weston and wlroots:

- `0001-weston-occlusion-culling.patch` — `weston_view_damage_below()` with tile-based culling
- `0002-wlroots-occlusion-culling.patch` — `scene_node_update_iterator()` with pr_region

### Architecture

```
pr_tile_t *visible = pr_calculate_visible_tiles(view_bounds, opaque_above);
if (!visible) { /* fully occluded — skip compositing */ }
```

The algorithm:
1. Start with the view's bounding rectangle as a single tile
2. For each opaque window in front, **subtract** its rectangle from the tile list
3. Partial overlaps split into up to 4 smaller tiles (L-shaped decomposition)
4. **Coalesce** adjacent tiles back into larger rectangles
5. Return `NULL` if nothing is visible

### License

Apache 2.0
