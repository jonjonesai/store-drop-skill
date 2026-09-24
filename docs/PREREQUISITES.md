# Prerequisites

| Component | Required | Purpose |
|---|---:|---|
| WordPress | Yes | Storefront platform |
| Mega Kadence Bridge 1.4.0+ | Yes | Authenticated read, mutation, render, snapshot, and rollback API |
| Kadence Theme | Yes | Base theme |
| Kadence Blocks | Yes | Page block primitives |
| WooCommerce | Yes | Catalog and shop pages |
| Fluent Forms | Yes, auto-install supported | Contact and newsletter forms |
| Kadence Theme Pro | No | Optional licensed theme features |
| Kadence Blocks Pro | No | Optional licensed blocks |
| Rank Math / Pro | No | Optional SEO layer |
| LiteSpeed Cache | No | Optional host cache; its settings are applied only when present |
| MEGA account/token | No for storefront build | Needed only for licensed premium delivery or separate product-generation integration |

Local execution requires Python 3, curl, Archon 0.10.1+, and one configured AI
adapter for live AI nodes. Deterministic validation and dry-run selection do not
require AI authentication.

Store Drop currently builds a branded WordPress/Kadence/WooCommerce storefront,
safe placeholder catalog, forms, navigation, legal drafts, theme configuration,
and a read-back certificate. It does not automatically hand credentials to the
MEGA product generator, connect payments or fulfillment, approve policies, or
make placeholder products purchasable.
