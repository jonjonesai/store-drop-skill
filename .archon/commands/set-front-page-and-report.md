# Set Front Page and Generate Report

Bridge credentials are already present in the allowlisted environment. Never
read a credentials file, print a secret, or put a secret in a prompt or argument.

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

### 3. Do not synthesize the final certificate

Print the page URLs as a convenience, but do not claim that requested colors,
copy, products, forms, or settings are live. The deterministic `final-check`
node reads the resulting site back and writes the machine-readable certificate.

Output this table:

```
Store build completed; launch certification follows read-back.

| Page              | URL                        |
|-------------------|----------------------------|
| Homepage          | SITE_URL/                  |
| About             | SITE_URL/about/            |
| Contact           | SITE_URL/contact/          |
| Shop              | SITE_URL/shop/             |
| Privacy Policy    | SITE_URL/privacy-policy/   |
| Terms of Service  | SITE_URL/terms-of-service/ |
| Returns & Refunds | SITE_URL/returns-and-refunds/ |

The deterministic report will list actual read-back values and unresolved drafts.
```
