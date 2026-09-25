# Architecture

## Portable core

`.archon/workflows/deploy-pod-store.yaml` is the portable 49-node specification.
It deliberately declares no provider or model. The DAG retains ordered,
resumable, stop-on-failure execution; deterministic validators; cache retries;
Gutenberg normalization; header, footer, menu, logo, dark-mode, product, page,
and final rendered checks.

## Provider contract

`scripts/run-store-drop.py` resolves the provider and model, verifies provider
authentication, creates a run-scoped Archon config, and launches Archon with a
clean allowlisted environment. An AI node receives its command prompt and
Archon context, the repository working directory, the declared model, only the
allowlisted environment, Archon's normal exit status, and provider diagnostics.
Command files constrain side effects and artifact formats. Deterministic nodes
consume structured JSON artifacts rather than parsing conversational prose.

The interactive entrypoint asks the operator which provider account to use.
For direct runner and automation use, precedence is CLI `--provider/--model`,
then `AI_PROVIDER/AI_MODEL`, then the backward-compatible Codex runner fallback
with `gpt-5.6-sol`. The checked-in workflow never changes when a provider is
added; the runner maps selection into Archon's provider registry.

## Adapters

- `codex` is first class and is the direct-runner compatibility fallback. The
  interactive entrypoint still asks. It uses Archon's native Codex adapter and
  normal `codex login` or an explicitly allowlisted `OPENAI_API_KEY`.
- `claude` uses Archon's native Claude adapter and normal Claude login or an
  explicitly allowlisted `ANTHROPIC_API_KEY`. Store Drop no longer reads
  `~/.claude/.credentials.json` or exports Claude OAuth tokens.
- `pi` is the extension point for Archon-supported backends. OpenAI-compatible
  local or hosted endpoints are registered in Pi's own model configuration and
  selected as `<backend>/<model>`. Archon does not expose a safe arbitrary
  `AI_COMMAND` workflow provider, so Store Drop does not invent one.

Archon 0.10.1 or newer is required for the tested provider/config and dry-run
contract. The interactive entrypoint verifies the provider command,
authentication, and Archon version before it reads bridge state or performs any
WordPress mutation.

## Deterministic operations and certification

Shell/Python code owns dotenv parsing, payload encoding, retries, snapshots,
cache invalidation, read-back, editorial scanning, placeholder safety, and the
final certificate. AI remains limited to copy and judgment-heavy composition.
The certificate is produced from live API/render read-back and can report a
successful build while correctly refusing launch certification.
