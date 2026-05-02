# Golden Templates

These are **proven-good** block content templates extracted from a working cutemerch.love deployment. They passed WordPress block validation with zero "Attempt Block Recovery" warnings.

## How to use

1. Read the template for the page you're building
2. Replace the variable text (brand name, tagline, copy, etc.) with the student's intake answers
3. Replace `uniqueID` values with fresh unique strings if deploying to a different site
4. Send the content via `POST /posts/create` or `POST /pages/ensure`
5. Call `POST /posts/{id}/normalize-blocks` after creation
6. Set page meta: `_kad_post_title: hide`, `_kad_post_layout: fullwidth`, etc.

## Files

| Template | Sections | Variables to replace |
|---|---|---|
| `homepage.html` | Hero, Trust Row (3), Brand Story (2-col), Featured Products (carousel), CTA Band, Newsletter (Fluent Form) | Brand name, tagline, hero H1, hero subtitle, brand story copy, Fluent Form ID |
| `about.html` | Hero, Brand Story (2-col), Values (3), CTA | Brand name, subtitle, story copy, value titles + descriptions |
| `contact.html` | Hero, Two-col (info + Fluent Form), CTA | Brand name, email, Fluent Form ID |

## Block format rules baked into these templates

- Every `kadence/rowlayout` and `kadence/column` has `kbVersion:2`
- Column class: `kadence-column${uniqueID}` (NO `inner-column-N`)
- Heading class: `kt-adv-heading${uniqueID} wp-block-kadence-advancedheading`
- Heading `data-kb-block`: `kb-adv-heading${uniqueID}`
- advancedbtn class: `wp-block-kadence-advancedbtn kb-buttons-wrap kb-btns${uniqueID}`
- Dynamic blocks (singlebtn, productcarousel, infobox): empty inner HTML
- Padding as array: `["top","right","bottom","left"]`
- fontSize as array: `["desktop","tablet","mobile"]`
- No `kadence/infobox` — uses heading + paragraph instead
- No trailing empty paragraph blocks
