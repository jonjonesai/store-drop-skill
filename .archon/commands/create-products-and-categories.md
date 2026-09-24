# Create Products and Categories

Credentials are already present in the allowlisted environment. Never read a
credentials file, print a secret, or put a secret in a prompt or argument.

Read the intake answers from `$ARTIFACTS_DIR/intake.json`.

## Steps

### 1. Create product categories

Parse the `categories` field (comma-separated). For each category:

```
POST /woo/categories/create with {"name": "Category Name", "slug": "category-name"}
```

Save returned category IDs.

### 2. Check existing products

```
GET /woo/products
```

If total > 0, skip product creation (idempotent).

### 3. Create 4 safe, category-aware placeholders (if none exist)

**Field names for the bridge (NOT WC REST API format):**
- Use `name` (NOT `title`)
- Use `categories` as a flat array of term IDs: `[16]` (NOT `[{"id": 16}]`)
- Bridge does NOT support `featured` flag during creation

Derive each placeholder name from the requested taxonomy. Cycle through the
actual category names from intake, for example `Sample Wall Art — Draft
Placeholder` in the Wall Art category and `Sample Apparel — Draft Placeholder`
in Apparel. Do not map a generic product type into an unrelated category.

Every placeholder MUST use `status: "draft"`, `stock_status: "outofstock"`, an
empty price, and the description `Prelaunch placeholder. Not available for
purchase.` Enabling sales requires `launch.enable_sales=true` plus
`launch.approved_by` in intake and real, non-placeholder products. Store Drop
never turns sample products purchasable.

Example shape:

```json
{"name": "Sample Wall Art — Draft Placeholder", "status": "draft", "stock_status": "outofstock", "regular_price": "", "short_description": "Prelaunch placeholder. Not available for purchase.", "categories": [WALL_ART_CATEGORY_ID]}
```

### 4. Do not feature placeholders

Do not set `_featured` on a placeholder product.

### 5. Flush cache

```
POST /cache/flush
```

Save product IDs and category IDs to `$ARTIFACTS_DIR/products.json`.
