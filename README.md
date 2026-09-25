# Store Drop

Store Drop is a provider-neutral, 49-node Archon harness that builds, validates,
and certifies a Kadence and WooCommerce storefront through Mega Kadence Bridge.
Interactive runs ask whether to use Codex, Claude, or Archon's Pi adapter for a
supported OpenAI-compatible backend. The selected provider uses the operator's
own authenticated account.

The workflow is more than a prompt: mutations are ordered and resumable,
failures halt downstream work, deterministic validators inspect API and rendered
state, cache failures retry, and the final JSON certificate is based on live
read-back rather than requested values.

## Requirements

Use Archon 0.10.1 or newer, Python 3, curl, and one AI adapter for live AI
nodes. The required WordPress stack is Kadence Theme, Kadence Blocks,
WooCommerce, Mega Kadence Bridge 1.4.0+, and Fluent Forms. Pro extensions,
Rank Math, LiteSpeed, a MEGA account, payments, and fulfillment are optional or
separate. See [the prerequisite matrix](docs/PREREQUISITES.md).

## Setup

```bash
curl -fsSL https://archon.diy/install | bash
git clone https://github.com/jonjonesai/store-drop-skill
cd store-drop-skill
cp .env.example .env
cp intake.json.example intake.json
```

Paste bridge values into `.env` and edit `intake.json`. Dotenv is parsed as
data, never sourced as shell. Application passwords containing spaces, quotes,
hashes, or empty values are supported.

Inspect the selection without credentials or network mutation:

```bash
./deploy.sh --dry-run
./deploy.sh --validate
```

Start an interactive run:

```bash
./deploy.sh
```

Store Drop asks which AI to use. If that provider is not authenticated, it
offers to open the provider's native, secure login before collecting WordPress
credentials or changing the site. For an explicit or automated Codex run:

```bash
./deploy.sh --provider codex --model gpt-5.6-sol
```

Run the backward-compatible Claude adapter:

```bash
claude  # complete /login once
./deploy.sh --provider claude --model sonnet
```

For an OpenAI-compatible backend supported by Pi, authenticate/configure that
backend in Pi, then select it without editing the DAG:

```bash
./deploy.sh --provider pi --model openai/gpt-5.6
```

Archon does not currently expose a safe arbitrary-command provider contract, so
Store Drop intentionally does not advertise an unsupported `AI_COMMAND` mode.

## Safety defaults

- Placeholder products derive names from the requested taxonomy and remain
  draft/private/out of stock.
- Sales require explicit `launch.enable_sales` and `launch.approved_by` intake.
- Unconfirmed shipping, returns, guarantees, donation impact, organization
  claims, production times, and service levels remain visible drafts.
- Visible demo form titles and unsafe placeholders block certification.
- AI subprocesses receive an explicit environment allowlist. Secrets are not
  placed in prompts, logs, command arguments, reports, or snapshots.

A build may complete while launch certification remains false. That is the
expected result when legal drafts or launch approval remain unresolved.

## Architecture and scope

See [architecture](docs/ARCHITECTURE.md) for the portable core, provider
contract, adapters, and deterministic boundary. Store Drop builds the
storefront; automatic MEGA product-generator credential handoff remains an
unfinished Phase 2 item. Mega Kadence Bridge is a WordPress control plane, not
the product generator.

## Validation

```bash
python3 -m unittest discover -s tests -v
archon validate workflows deploy-pod-store
archon validate commands
./deploy.sh --archon-dry-run
```

The last command exercises Archon's DAG simulation and does not contact an AI
provider or WordPress site. A real deployment writes `final-report.json` to the
Archon artifacts directory after checking all seven required URLs.

## License

GPL v2 or later. See [LICENSE](LICENSE).
