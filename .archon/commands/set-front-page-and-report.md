# Set Front Page and Generate Report

Read page IDs from `$ARTIFACTS_DIR/pages.json` and intake from `$ARTIFACTS_DIR/intake.json`.

## Steps

### 1. Set homepage as front page

```
POST /option/show_on_front with {"value": "page"}
POST /option/page_on_front with {"value": HOMEPAGE_ID}
```

### 2. Flush all caches

```
POST /cache/flush
```

### 3. Print final summary

Output a verification table to the student:

```
Your store is live!

| Page              | URL                        |
|-------------------|----------------------------|
| Homepage          | SITE_URL/                  |
| About             | SITE_URL/about/            |
| Contact           | SITE_URL/contact/          |
| Shop              | SITE_URL/shop/             |
| Privacy Policy    | SITE_URL/privacy-policy/   |
| Terms of Service  | SITE_URL/terms-of-service/ |
| Returns & Refunds | SITE_URL/returns-and-refunds/ |

Brand: BRAND_NAME
Mode: light/dark
Palette: PRIMARY_COLOR
Fonts: HEADING_FONT / BODY_FONT

What's next:
1. Open your site in a browser and check each page
2. Replace the 4 placeholder products with real designs from MEGA
3. Upload your logo if you haven't already
4. Everything is reversible — just tell me to fix anything
```
