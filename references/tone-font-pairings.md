# Tone-Based Font Pairings

> 10 curated heading + body font pairings mapped to brand tones. Claude auto-selects based on the student's tone answer during intake (Q4 in the 13-question version, derived from niche + style in the 6-question version).

## The Matrix

| Tone | Heading Font | Body Font | Best For |
|---|---|---|---|
| Bold & Rebellious | Anton | Inter | Streetwear, skulls, motorcycles, edgy niches |
| Warm & Friendly | Fraunces | Nunito | Pets, baby, home decor, food, wholesome |
| Premium & Refined | Playfair Display | Source Sans 3 | Luxury goods, jewelry, wine, high-end |
| Playful & Quirky | Bricolage Grotesque | DM Sans | Kids, party, novelty, humor |
| Technical & Expert | Space Grotesk | Inter | Gaming, tech, fitness tracking, tools |
| Earthy & Artisan | Cormorant Garamond | Lora | Candles, ceramics, handmade, nature |
| Urban & Street | Archivo Black | Archivo | Sneakers, hip-hop, graffiti, urban art |
| Modern & Minimal | Manrope | Manrope | Clean brands, SaaS-adjacent, modern |
| Vintage & Heritage | Abril Fatface | Libre Baskerville | Retro, classic cars, barbershop, heritage |
| Sporty & Energetic | Oswald | Roboto | Gym, sports, outdoor, hunting, fishing |

## How To Apply

All 20 fonts are on Google Fonts. Set via `/theme-mods/batch`:

```bash
curl -s -X POST "${BRIDGE_URL}/theme-mods/batch" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "mods": {
      "heading_font": {
        "family": "Anton",
        "google": true,
        "weight": "400",
        "variant": "regular"
      },
      "base_font": {
        "family": "Inter",
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
      }
    }
  }'
```

## Niche → Tone Inference Rules

When the student gives a niche but not an explicit tone, infer:

| Niche keywords | Inferred tone |
|---|---|
| streetwear, skulls, tattoo, motorcycle, metal | Bold & Rebellious |
| pet, dog, cat, baby, family, home | Warm & Friendly |
| luxury, premium, jewelry, wine, boutique | Premium & Refined |
| funny, humor, meme, novelty, kids, party | Playful & Quirky |
| tech, gaming, code, fitness tracker, gadget | Technical & Expert |
| candle, handmade, ceramic, nature, organic, botanical | Earthy & Artisan |
| sneaker, hip-hop, graffiti, urban, skate | Urban & Street |
| minimal, modern, clean, studio | Modern & Minimal |
| retro, vintage, classic, barbershop, heritage, americana | Vintage & Heritage |
| gym, sports, hunting, fishing, outdoor, hiking, running | Sporty & Energetic |

When ambiguous, default to **Modern & Minimal** (Manrope / Manrope) — it works for any niche and never looks wrong.

## Font Weight Reference

| Font | Available weights | Recommended |
|---|---|---|
| Anton | 400 | 400 (only weight) |
| Fraunces | 100–900 | 700 heading |
| Playfair Display | 400–900 | 700 heading |
| Bricolage Grotesque | 200–800 | 700 heading |
| Space Grotesk | 300–700 | 600 heading |
| Cormorant Garamond | 300–700 | 600 heading |
| Archivo Black | 400 | 400 (only weight) |
| Manrope | 200–800 | 700 heading, 400 body |
| Abril Fatface | 400 | 400 (only weight) |
| Oswald | 200–700 | 700 heading |
| Inter | 100–900 | 400 body |
| Nunito | 200–1000 | 400 body |
| Source Sans 3 | 200–900 | 400 body |
| DM Sans | 100–1000 | 400 body |
| Lora | 400–700 | 400 body |
| Archivo | 100–900 | 400 body |
| Libre Baskerville | 400, 700 | 400 body |
| Roboto | 100–900 | 400 body |
