# Store Drop operator guide

Store Drop builds and validates a WordPress, Kadence, and WooCommerce
storefront. It does not connect the MEGA product generator, payments, or
fulfillment, and it does not approve legal or commercial policies.

## 1. Prepare WordPress

Install and activate Mega Kadence Bridge 1.4.0+, then copy its environment
variables into a local ignored `.env`. Required and optional components are in
[PREREQUISITES.md](PREREQUISITES.md). A MEGA account is not required to build
the storefront.

## 2. Prepare a runtime

Install Archon 0.10.1+ and one supported adapter. Codex is the default:

```bash
npm install -g @openai/codex
codex login
curl -fsSL https://archon.diy/install | bash
```

Claude users may authenticate with `claude` and select `--provider claude`.
Other supported/OpenAI-compatible backends use Archon's Pi adapter.

## 3. Inspect before running

```bash
cp .env.example .env
cp intake.json.example intake.json
./deploy.sh --dry-run
./deploy.sh --validate
```

The dry run prints provider/model and whether credentials are present without
revealing values. Validation does not contact an AI provider or WordPress.

## 4. Build

```bash
./deploy.sh
```

The 49-node DAG stops on failures and can be re-run. It validates the palette,
tagline, products, required pages, Gutenberg blocks, menus, header, footer,
logo, dark-mode rules, cache behavior, form titles, and seven rendered URLs.

The build produces safe category-aware placeholder products. They are not
purchasable. Legal pages remain visible prelaunch drafts unless exact approved
policy text is supplied in intake.

## 5. Read the certificate

The final `final-report.json` contains actual read-back state. A successful
build is not the same as launch certification: unresolved legal/editorial
drafts, visible demo labels, unsafe placeholders, missing page renders, or lack
of explicit sales approval keep `launch.certified` false.

Before sales, replace placeholders with approved products, connect and test
payments and fulfillment, approve shipping/returns/privacy/terms and any
cause-related language, then explicitly set the launch fields in intake.
