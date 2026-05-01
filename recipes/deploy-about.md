# Recipe: Deploy About Page

> Builds the About page with hero section, brand story, 3 values/pillars, and a CTA band. All AI-generated copy is driven by intake answers.

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `brand_name` | Intake Q1 | `CuteMerch` |
| `niche` | Intake Q2 | `funny golden retriever shirts` |
| `mode` | Intake Q3 | `dark` |
| `usp` | Intake Q6 | `Every design is original art, never resold templates` |

## Page Structure

4 sections:

1. **Page Hero** — H1 "About ${brand_name}" + one-line subtitle
2. **Brand Story** — Two-column: image placeholder + 2-3 paragraphs of AI copy
3. **Values Row** — 3 columns with H3 titles + body text
4. **CTA Band** — "Ready to see what we've got?" + Shop button

## Execution

### Step 1: Generate content

#### Hero Subtitle
AI-generated, one sentence, max 18 words. Based on niche + USP.
Example: `"Original golden retriever designs, made to order, shipped to your door."`

#### Brand Story Copy
3 paragraphs, max 60 words each. Structure:
- **P1 — Origin:** Why this brand exists. What problem it solves or passion it serves.
- **P2 — Difference:** What makes this brand different from competitors. Reference the USP.
- **P3 — Promise:** What the customer can expect. Quality, originality, service.

#### Values
3 values that reinforce the brand. Generate from niche context:

| Default Value | Icon | Example Body |
|---|---|---|
| Original Art | `fe_star` | Every design starts as an original concept -- never mass-produced, never resold. |
| Made to Order | `fe_package` | Each product is printed just for you, reducing waste and ensuring quality. |
| Customer First | `fe_heart` | Your satisfaction drives everything we do. Not happy? We make it right. |

These can be customized based on the niche (e.g. an outdoor brand might use "Adventure Ready" / "Built to Last" / "Nature Inspired").

### Step 2: Build page content

Use patterns from `references/kadence-block-patterns.md`:

1. **Page Hero** pattern — 80px top padding, palette7 background
2. **Brand Story** pattern — 60px padding, palette8 background, image left + text right
3. **Values Row** pattern — 60px padding, palette7 background, 3 columns
4. **Secondary CTA Band** pattern — 60px padding, palette1 background

Concatenate all sections into a single content string.

### Step 3: Create the page

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "About",
    "slug": "about",
    "status": "publish",
    "content": "${ALL_SECTIONS}"
  }'
```

Save returned `id` as `ABOUT_ID`.

### Step 4: Set page meta

```bash
curl -s -X POST "${BRIDGE_URL}/posts/${ABOUT_ID}" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "meta": {
      "_kad_post_title": "hide",
      "_kad_post_feature": "hide",
      "_kad_post_vertical_padding": "disable",
      "_kad_post_layout": "fullwidth"
    }
  }'
```

### Step 5: Flush and verify

```bash
curl -s -X POST "${BRIDGE_URL}/cache/flush" -u "claude-bot:${BRIDGE_PASS}"
```

Verify using `recipes/verify-deployment.md`:
- Page returns 200
- Contains "About" in rendered HTML
- Contains `kt-row-column-wrap` (kbVersion:2 active)
- Contains brand name

## Copy Generation Guidelines

| Element | Max Words | Tone Match |
|---|---|---|
| Hero subtitle | 18 | Matches selected font tone |
| Story P1 (origin) | 60 | Warm, personal |
| Story P2 (difference) | 60 | Confident, specific |
| Story P3 (promise) | 60 | Direct, customer-facing |
| Value titles | 4 each | Bold, clear |
| Value descriptions | 30 each | Practical, specific |

## Gotchas

1. **First section needs 80px top padding** for header breathing room. All subsequent sections use 60px.

2. **H3 headings in the values row need top margin (10px)** to breathe from any preceding content.

3. **Image placeholder for v1:** Use a solid-color block matching palette7 (light surface) as the brand story image. Phase D will generate a lifestyle image via Flux 2 Pro.

4. **Fullwidth layout is required** for edge-to-edge section backgrounds. Same as homepage.
