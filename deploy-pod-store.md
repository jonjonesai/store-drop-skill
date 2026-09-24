# Deploy Storefront

The executable specification is the 49-node workflow at
`.archon/workflows/deploy-pod-store.yaml`. Do not reproduce it as a loose
one-agent checklist; doing so bypasses validators, stop-on-failure ordering,
retries, mutation read-back, and certification.

Use:

```bash
./deploy.sh --dry-run
./deploy.sh --validate
./deploy.sh
```

Codex is the default. Select Claude with `--provider claude`, or a configured
Pi/OpenAI-compatible backend with `--provider pi --model <backend/model>`.

The workflow builds the branded theme, safe draft catalog, pages, forms,
navigation, header/footer, legal drafts, and final certificate. It does not
connect the separate MEGA product generator, approve policies, connect payment
or fulfillment accounts, or make placeholder products purchasable.

All live calls must go through `.archon/lib/bridge.sh`; raw credential-bearing
curl examples are intentionally excluded. Read `docs/ARCHITECTURE.md`,
`docs/PREREQUISITES.md`, and `references/editorial-safety.md` before changing
the workflow.
