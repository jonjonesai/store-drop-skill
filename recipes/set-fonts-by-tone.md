# Recipe: Set Fonts by Tone

> Applies the correct heading + body font pair based on the student's brand tone or niche.

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `tone` | Intake Q3 style answer, or inferred from Q2 niche | `Bold & Rebellious` |

## Tone Resolution

If the student provides an explicit tone from the 10 options, use it directly.

If they provide only a niche, infer the tone using the mapping in `references/tone-font-pairings.md`.

If ambiguous, default to **Modern & Minimal** (Manrope / Manrope).

## Execution

### Step 1: Look up the font pair

Reference `references/tone-font-pairings.md` for the full matrix. Example for "Bold & Rebellious":
- Heading: Anton (weight 400)
- Body: Inter (weight 400)

### Step 2: Apply via bridge

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "heading_font": {
        "family": "${HEADING_FONT}",
        "google": true,
        "weight": "${HEADING_WEIGHT}",
        "variant": "${HEADING_VARIANT}"
      },
      "base_font": {
        "family": "${BODY_FONT}",
        "google": true,
        "weight": "400",
        "variant": "400",
        "size": {
          "desktop": 17,
          "tablet": 16,
          "mobile": 15
        },
        "lineHeight": {
          "desktop": 1.6,
          "tablet": 1.6,
          "mobile": 1.6
        }
      },
      "h1_font": {
        "size": {"desktop": 32, "tablet": 28, "mobile": 24},
        "sizeType": "px",
        "lineHeight": {"desktop": 1.2, "tablet": 1.2, "mobile": 1.2},
        "lineType": "em",
        "family": "inherit",
        "weight": "700"
      },
      "h2_font": {
        "size": {"desktop": 28, "tablet": 24, "mobile": 22},
        "sizeType": "px",
        "lineHeight": {"desktop": 1.3, "tablet": 1.3, "mobile": 1.3},
        "lineType": "em",
        "family": "inherit",
        "weight": "700"
      },
      "h3_font": {
        "size": {"desktop": 22, "tablet": 20, "mobile": 18},
        "sizeType": "px",
        "lineHeight": {"desktop": 1.4, "tablet": 1.4, "mobile": 1.4},
        "lineType": "em",
        "family": "inherit",
        "weight": "700"
      }
    }
  }'
```

### Step 3: Flush cache

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

### Step 4: Verify

```bash
curl -s "${BRIDGE_URL}/render?url=/" -u "claude-bot:${BRIDGE_PASS}" \
  | jq -r '.html' | grep -o "font-family:[^;]*" | head -5
```

Confirm the heading and body fonts appear in the rendered CSS.

## Typography Standards (Non-Negotiable)

These sizes apply regardless of which font pair is chosen:

| Element | Desktop | Tablet | Mobile |
|---|---|---|---|
| H1 | 32px | 28px | 24px |
| H2 | 28px | 24px | 22px |
| H3 | 22px | 20px | 18px |
| Body | 17px | 16px | 15px |
| Line height (body) | 1.6 | 1.6 | 1.6 |
| Line height (headings) | 1.2-1.4 | 1.2-1.4 | 1.2-1.4 |

**Never tiny text. Err larger.**

## Gotchas

1. **`heading_font` sets the default for all h1-h6.** Individual `h1_font`, `h2_font`, `h3_font` entries inherit from it via `"family": "inherit"`. Only override the family at the individual level if you need a mixed-font heading hierarchy (rare).

2. **Single-weight fonts (Anton, Archivo Black, Abril Fatface) only have weight 400.** Setting weight to 700 or 800 has no visual effect and may cause a font-loading warning. Use the font's only available weight and rely on the font's inherent boldness.

3. **`"google": true` is required** for all Google Fonts entries. Without it, Kadence won't enqueue the font from Google Fonts CDN and the browser falls back to system fonts.

4. **`variant` vs `weight`:** For single-weight fonts, use `"variant": "regular"`. For multi-weight fonts, use `"variant": "400"` (matching the weight number as a string).
