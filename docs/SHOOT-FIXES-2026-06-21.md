# GenerationX shoot — issues flagged & fixed (2026-06-21)

Every problem Jon hit while filming the live store-drop, locked into the skill:

| # | Symptom | Root cause | Fix (committed) |
|---|---------|-----------|-----------------|
| 1 | Store showed "coming soon" placeholder to the public | WooCommerce 9.1+ defaults a fresh store to coming-soon | `enforce-content-style` node sets `woocommerce_coming_soon=no` |
| 2 | Shop missing from top nav | menu lookup used slug `shop`; the real Woo shop page id/slug differed (gx case was a wipe artifact) | recreated shop page + added to primary menu (gx); menu robustness is a follow-up |
| 3 | Product-page breadcrumbs covered by header | transparent header on single/archive + hidden content vertical-padding | `transparent_header_enable=False` (chrome.sh) + 2rem top padding on `.kadence-breadcrumbs` (LAYOUT_CSS) |
| 4 | Size-guide page whited-out in dark mode | size charts sit in a near-white `.product-section` with transparent cells; light dark-mode text vanished | dark bundle: tables + `.product-section`/`.tab-content`/`.unit-tabs` → transparent bg + palette text |

All verified visually on the live store. Light-mode stores unaffected by the dark-only rules.
