# Recipe: Set Palette

> Applies the 9-slot Kadence global color palette based on the student's mode (light/dark) and brand color.

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `mode` | Intake Q3 | `dark` or `light` |
| `primary_color` | Intake Q4 | `#FF5500`, `forest green`, or `"I don't know"` |

## The 9-Slot Palette System

Every Kadence site uses 9 palette slots. The skill assigns them by role, not by color name:

| Slot | Role | Dark Mode | Light Mode |
|---|---|---|---|
| palette1 | Primary CTA (buttons, accents, stat numbers) | Student's color | Student's color |
| palette2 | CTA Hover | Darkened primary (-15% lightness) | Darkened primary (-15% lightness) |
| palette3 | Headings (h1-h6) | `#FFFFFF` | `#0A0A0A` |
| palette4 | Body text (paragraphs) | `#E0E0E0` | `#2D2D2D` |
| palette5 | Muted text (captions, meta) | `#999999` | `#6B6B6B` |
| palette6 | Borders (dividers, inputs) | `#333333` | `#E0E0E0` |
| palette7 | Light surface (section backgrounds) | `#1A1A1A` | `#F5F5F5` |
| palette8 | Page background | `#0A0A0A` | `#FAFAFA` |
| palette9 | Pure white (text on dark, button labels) | `#FFFFFF` | `#FFFFFF` |

## Default Colors

When the student says "I don't know" for their brand color:

- **Dark mode default:** `#FF5500` (orange) — visible on dark, energetic, works for any niche
- **Light mode default:** `#1B4F8A` (deep navy) — visible on light, professional, works for any niche

## Color Name Resolution

When the student gives a color name instead of a hex code, resolve it:

| Student says | Hex |
|---|---|
| forest green | `#228B22` |
| deep red / crimson | `#C62828` |
| hot pink | `#FF1493` |
| royal blue | `#1B4F8A` |
| burnt orange | `#CC5500` |
| rose gold | `#B76E79` |
| teal | `#008080` |
| lavender | `#967BB6` |
| charcoal | `#36454F` |
| gold | `#D4A017` |

For any other description ("something that feels like autumn", "ocean vibes"), pick an appropriate hex, explain the choice briefly, and apply it. Don't ask for approval — they can iterate.

## Auto-Brightening (Dark Mode)

In dark mode, if the student's primary color has HSL lightness < 40%, it won't be visible against the dark background. Auto-brighten:

1. Convert hex to HSL
2. If lightness < 40%, shift lightness to 65%
3. Use the brightened version as palette1
4. Generate palette2 by reducing lightness by 15% from palette1

Example: Student picks `#1B4F8A` (navy, L=32%) for dark mode → brighten to `#4A8FD4` (L=65%) so it reads on `#0A0A0A`.

## WCAG Contrast Check

Before applying, verify:
- palette1 on palette8 (CTA on background): contrast ratio >= 4.5:1
- palette3 on palette8 (headings on background): contrast ratio >= 4.5:1
- palette4 on palette8 (body text on background): contrast ratio >= 4.5:1

If any fail, adjust the offending slot toward higher contrast.

## Execution

### Step 1: Apply palette via bridge

```bash
curl -s -X POST "${BRIDGE_URL}/palette" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "palette": {
      "active": "palette",
      "palette": [
        {"slug": "palette1", "color": "${PRIMARY}",  "name": "Primary CTA"},
        {"slug": "palette2", "color": "${HOVER}",     "name": "CTA Hover"},
        {"slug": "palette3", "color": "${HEADINGS}",  "name": "Headings"},
        {"slug": "palette4", "color": "${BODY}",      "name": "Body Text"},
        {"slug": "palette5", "color": "${MUTED}",     "name": "Muted Text"},
        {"slug": "palette6", "color": "${BORDERS}",   "name": "Borders"},
        {"slug": "palette7", "color": "${SURFACE}",   "name": "Light Surface"},
        {"slug": "palette8", "color": "${BACKGROUND}","name": "Page Background"},
        {"slug": "palette9", "color": "#FFFFFF",       "name": "Pure White"}
      ]
    }
  }'
```

### Step 2: Set mode-appropriate theme_mods

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "buttons_background": {"color": "palette1", "hover": "palette2"},
      "buttons_color": {"color": "palette9", "hover": "palette9"},
      "primary_navigation_color": {"color": "palette4", "hover": "palette1", "active": "palette1"},
      "header_main_background": {"desktop": {"color": "${MODE_HEADER_BG}"}},
      "header_sticky_background": {"desktop": {"color": "${MODE_HEADER_BG}"}},
      "mobile_trigger_color": {"color": "palette9", "background": "palette1"},
      "mobile_trigger_background": {"color": "palette1", "hover": "palette2"}
    }
  }'
```

Where `${MODE_HEADER_BG}` is:
- Dark mode: `palette8` (dark header)
- Light mode: `palette9` (white header)

### Step 3: Set background color for dark mode

For dark mode only — set the site background and content background:

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "site_background": {"desktop": {"color": "palette8"}},
      "content_background": {"desktop": {"color": ""}},
      "mobile_navigation_color": {"color": "palette9", "hover": "palette1", "active": "palette1", "background": "palette8", "divider": "palette6"}
    }
  }'
```

**Gotcha:** `content_background` must be empty string for dark mode. If set to a color, it creates a white/light content box that breaks the dark theme.

### Step 3b: Inject dark mode text CSS

Kadence does NOT have theme_mods for body text color or site title color — there are no keys like `brand_typography_color` or `heading_color` or `base_font_color`. These do not exist. Kadence relies on the palette CSS custom properties, but several wrapper elements inherit dark defaults that override the palette.

**You MUST inject custom CSS via `POST /css` to force all text light:**

```bash
curl -s -X POST "${BRIDGE_URL}/css" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"css": "body, .entry-content, .entry-content-wrap, p, h1, h2, h3, h4, h5, h6 { color: var(--global-palette4) !important; } h1, h2, h3, h4, h5, h6, .kt-adv-heading, .kt-blocks-info-box-title { color: var(--global-palette3) !important; } .site-title, .site-title a, .site-branding .brand, .site-branding a.brand { color: var(--global-palette9) !important; } .site-header-wrap, #masthead { background: var(--global-palette8) !important; } .entry-content-wrap { padding: 0 !important; background: transparent !important; } .content-area { margin-top: 0 !important; margin-bottom: 0 !important; } a { color: var(--global-palette1); } a:hover { color: var(--global-palette2); }"}'
```

**Without this CSS, dark mode sites WILL have invisible text and white gaps. There is no theme_mod alternative.**

### Step 4: Flush cache

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

### Step 5: Verify

```bash
curl -s "${BRIDGE_URL}/palette" -u "claude-bot:${BRIDGE_PASS}"
```

Confirm palette1 matches the intended primary color.

## Gotchas

1. **Kadence stores the palette as a JSON string** in `wp_options['kadence_global_palette']`, not a PHP array. The bridge handles serialization — send a JSON object.

2. **Content background + boxed layout = white border on dark mode.** Always set `content_background` to empty string for dark mode sites.

3. **Sticky header background must match main header background.** If you set `header_main_background` but forget `header_sticky_background`, the header flashes white on scroll.

4. **Mobile nav text defaults to black.** On dark mode, explicitly set `mobile_navigation_color` or the mobile drawer is invisible.
