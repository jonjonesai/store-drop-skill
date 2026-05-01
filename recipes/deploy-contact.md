# Recipe: Deploy Contact Page

> Builds the Contact page with hero section, two-column info + form layout. Phase 1 uses a form placeholder; Phase 2 wires Fluent Forms.

## Inputs Required

| Input | Source | Example |
|---|---|---|
| `brand_name` | Intake Q1 | `CuteMerch` |
| `email` | Intake (business email) | `hello@cutemerch.love` |
| `mode` | Intake Q3 | `dark` |
| `location` | Intake (optional) | `Los Angeles, CA` |
| `social_handles` | Intake (optional) | `@cutemerch on Instagram` |

## Page Structure

3 sections:

1. **Page Hero** — H1 "Get in Touch" + subtitle
2. **Two-Column Body** — Left: contact info (email, location, socials). Right: form placeholder.
3. **CTA Band** — "Rather browse? Check out the shop." + Shop button

## Execution

### Step 1: Generate content

#### Hero Subtitle
Simple, direct. Example: `"Questions, custom orders, or just want to say hi? We'd love to hear from you."`

#### Contact Info Column
Build from intake answers:

```
Email: ${email}
Location: ${location} (if provided, otherwise omit)
Social: ${social_handles} (if provided, otherwise omit)
Response time: "We respond within 24 hours on business days."
```

#### Form Column (Phase 1 — Placeholder)
A simple message encouraging direct email:

```
"Send us a message at ${email} and we'll get back to you within 24 hours.

For order issues, include your order number for faster help."
```

Phase 2 replaces this with an embedded Fluent Forms contact form with reCAPTCHA.

### Step 2: Build page content

#### Section 1: Page Hero

Use the **Page Hero** pattern from `kadence-block-patterns.md`. 80px top padding.

- H1: `"Get in Touch"`
- Subtitle: Generated from step 1

#### Section 2: Two-Column Body

```html
<!-- wp:kadence/rowlayout {"uniqueID":"${UID_ROW}","kbVersion":2,"columns":2,"colLayout":"equal","align":"full","padding":["60","60","60","60"],"maxWidth":1290,"bgColor":"palette8","tabletColumns":"1","mobileColumns":"1"} -->
<div class="wp-block-kadence-rowlayout alignfull">

<!-- wp:kadence/column {"id":1,"uniqueID":"${UID_C1}","kbVersion":2} -->
<div class="wp-block-kadence-column inner-column-1">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H3}","level":3,"color":"palette1","fontSize":["22","20","18"],"fontWeight":"700","margin":["","","15",""]} -->
<h3 class="wp-block-kadence-advancedheading">Contact Info</h3>
<!-- /wp:kadence/advancedheading -->

<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)"><strong>Email:</strong> ${EMAIL}</p>
<!-- /wp:paragraph -->

<!-- if location provided -->
<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)"><strong>Location:</strong> ${LOCATION}</p>
<!-- /wp:paragraph -->

<!-- if social handles provided -->
<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)"><strong>Social:</strong> ${SOCIAL_HANDLES}</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette5)"}}} -->
<p style="color:var(--global-palette5)">We respond within 24 hours on business days.</p>
<!-- /wp:paragraph -->

</div>
</div>
<!-- /wp:kadence/column -->

<!-- wp:kadence/column {"id":2,"uniqueID":"${UID_C2}","kbVersion":2} -->
<div class="wp-block-kadence-column inner-column-2">
<div class="kt-inside-inner-col">

<!-- wp:kadence/advancedheading {"uniqueID":"${UID_H3B}","level":3,"color":"palette1","fontSize":["22","20","18"],"fontWeight":"700","margin":["","","15",""]} -->
<h3 class="wp-block-kadence-advancedheading">Send a Message</h3>
<!-- /wp:kadence/advancedheading -->

<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)">Send us a message at ${EMAIL} and we'll get back to you within 24 hours.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph {"style":{"color":{"text":"var(--global-palette4)"}}} -->
<p style="color:var(--global-palette4)">For order issues, include your order number for faster help.</p>
<!-- /wp:paragraph -->

</div>
</div>
<!-- /wp:kadence/column -->

</div>
<!-- /wp:kadence/rowlayout -->
```

#### Section 3: CTA Band

Use the **Secondary CTA Band** pattern. H2: `"Rather Browse?"`. Button: `"Shop the Collection"` → `/shop/`.

### Step 3: Create the page

```bash
curl -s -X POST "${BRIDGE_URL}/pages/ensure" \
  -u "claude-bot:${BRIDGE_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Contact",
    "slug": "contact",
    "status": "publish",
    "content": "${ALL_SECTIONS}"
  }'
```

Save returned `id` as `CONTACT_ID`.

### Step 4: Set page meta

```bash
curl -s -X POST "${BRIDGE_URL}/posts/${CONTACT_ID}" \
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

Verify: page returns 200, contains "Contact" or "Get in Touch", contains `kt-row-column-wrap`.

## Phase 2 Upgrade: Fluent Forms

When Fluent Forms is installed and activated:

1. Create a contact form via Fluent Forms admin or API
2. Get the form shortcode (e.g. `[fluentform id="1"]`)
3. Replace the "Send a Message" placeholder column with:

```html
<!-- wp:shortcode -->
[fluentform id="1"]
<!-- /wp:shortcode -->
```

4. Add Google reCAPTCHA v3 integration in Fluent Forms settings
5. Re-save the page and flush cache

## Gotchas

1. **Don't include phone number unless the student explicitly provides one.** POD stores rarely need a phone line and it creates support expectations.

2. **80px top padding on first section.** Same header clearance rule as all other pages.

3. **Conditionally include location and social.** If the student didn't provide these in intake, omit the paragraphs entirely rather than showing empty fields.
