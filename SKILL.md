---
name: store-drop
description: Build, validate, and certify a Kadence and WooCommerce storefront through Mega Kadence Bridge using Codex, Claude, or a supported Archon provider. Use for a full Store Drop deployment or deterministic storefront validation; do not use for ordinary one-off WordPress edits.
---

# Store Drop

Store Drop is a 49-node Archon deployment and certification harness. The
portable workflow is provider-neutral.

Before a deployment:

1. Read [architecture](docs/ARCHITECTURE.md) for the provider boundary and
   supported adapters.
2. Read [prerequisites](docs/PREREQUISITES.md) and verify the required bridge,
   theme, blocks, and WooCommerce components. Treat Pro extensions as optional.
3. Read [editorial safety](references/editorial-safety.md) before generating
   copy or policies.
4. Before a live deployment, ask which AI account the user wants to use:
   Codex, Claude, or Pi for another supported/OpenAI-compatible backend. Do not
   silently choose for them. Pass the answer with `--provider` so the CLI does
   not ask twice. If they run the CLI directly, its onboarding prompt makes the
   same choice and opens the provider's native login when needed. Require the
   provider adapter, authentication, and Archon version preflight to pass before
   any bridge request or WordPress mutation.
5. Obtain explicit authorization for the target site. A dry run or validation
   does not authorize a live deployment.

Run `./deploy.sh --dry-run` to inspect the selected provider/model and missing
requirements without contacting an AI provider or a WordPress site. Run
`./deploy.sh --validate` for deterministic repository checks. A real interactive
deployment uses `./deploy.sh`, asks which provider account to use, and checks
login before touching WordPress. `--provider codex`, `--provider claude`, or
`--provider pi --model <backend/model>` makes the selection explicitly.

Never source `.env`. The runner parses it as data and passes only the documented
allowlist. Never print credentials or put them in prompts, arguments, reports,
fixtures, or snapshots.

Preserve the DAG's stop-on-failure behavior and validators. Every live mutation
must read current state, validate a non-empty payload, apply the smallest
change, flush caches with bounded retry, read API state back, check rendered
state where applicable, and report only the verified result. Use the bridge
helpers rather than raw credential-bearing curl commands.

Placeholder products remain draft, private, or out of stock. Do not enable
sales without explicit `launch.enable_sales` and `launch.approved_by` intake.
Unverified legal, shipping, returns, guarantee, donation-impact, organization,
or service-level claims remain visible drafts and block launch certification.

The final machine-readable certificate is authoritative. It records read-back
palette, tagline, pages, products, and form titles; requested values are not
proof of deployed state. MEGA product generation and credential handoff remain
a separate, unfinished integration described in `docs/STORE-DROP-PHASE-2.md`.
