# Create Products and Categories

**Credentials:** Read bridge credentials from `~/kadence-skill/store-drop-skill/.env` or `/tmp/archon-bridge/.env`. Source the file to get BRIDGE_URL, BRIDGE_USER, BRIDGE_PASS, BRIDGE_SITE. Use HTTP Basic Auth with BRIDGE_USER:BRIDGE_PASS for all API calls.

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

### 3. Create 4 placeholder products (if none exist)

**Field names for the bridge (NOT WC REST API format):**
- Use `name` (NOT `title`)
- Use `categories` as a flat array of term IDs: `[16]` (NOT `[{"id": 16}]`)
- Bridge does NOT support `featured` flag during creation

Create these 4:

```json
{"name": "Sample Tee -- Replace with MEGA", "status": "publish", "regular_price": "29.99", "short_description": "Placeholder product. Generate real ones at app.mega.management.", "categories": [FIRST_CAT_ID]}
{"name": "Sample Hoodie -- Replace with MEGA", "status": "publish", "regular_price": "49.99", "short_description": "Placeholder product. Generate real ones at app.mega.management.", "categories": [FIRST_CAT_ID]}
{"name": "Sample Mug -- Replace with MEGA", "status": "publish", "regular_price": "18.99", "short_description": "Placeholder product. Generate real ones at app.mega.management.", "categories": [SECOND_CAT_ID]}
{"name": "Sample Tote -- Replace with MEGA", "status": "publish", "regular_price": "19.99", "short_description": "Placeholder product. Generate real ones at app.mega.management.", "categories": [THIRD_CAT_ID]}
```

### 4. Set featured flag

After creation, set each product as featured:

```
POST /posts/{product_id} with {"meta": {"_featured": "yes"}}
```

### 5. Flush cache

```
POST /cache/flush
```

Save product IDs and category IDs to `$ARTIFACTS_DIR/products.json`.
