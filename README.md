# Store Drop Skill

Deploy a fully branded WordPress + Kadence + WooCommerce print-on-demand store in ~15 minutes.

The deploy is run by an Archon workflow with deterministic bash validators after every step. If anything goes wrong, the workflow halts loud — your site never ends up silently broken.

Part of the [MEGA](https://mega.management) ecosystem alongside [Mega Kadence Bridge](https://github.com/jonjonesai/mega-kadence-bridge) (the WordPress plugin that exposes the REST API).

## Prerequisites

A WordPress site (Hostinger or similar) with these plugins installed and active:

- Kadence theme + Pro
- Kadence Blocks + Pro
- WooCommerce
- [Mega Kadence Bridge](https://github.com/jonjonesai/mega-kadence-bridge/releases/latest)
- Fluent Forms
- Rank Math SEO
- LiteSpeed Cache

Locally:

- [Claude Code](https://claude.com/claude-code) installed (`claude` on your PATH)
- [Archon CLI](https://github.com/coleam00/Archon) installed (`archon` on your PATH)
- This repo cloned to `~/kadence-skill/store-drop-skill`

## One-time setup (do this once, ever)

If you're on Windows: install WSL first.

```powershell
# In PowerShell as administrator (Windows only):
wsl --install
# Restart Windows. Open Ubuntu from Start menu — that's your terminal from now on.
```

Then in your unix terminal (WSL on Windows / Terminal on Mac / any shell on Linux):

```bash
# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Authenticate Claude Code once (opens a browser)
claude
# log in, then exit (Ctrl+D or type "exit")

# Install Archon CLI
curl -fsSL https://archon.diy/install | bash

# Clone this repo to the expected path
mkdir -p ~/kadence-skill
cd ~/kadence-skill
git clone https://github.com/jonjonesai/store-drop-skill
cd store-drop-skill
```

You're now in the repo. Setup is done.

## Per-deploy (do this for each new store)

### 1. Install the bridge plugin

Download the [latest release ZIP](https://github.com/jonjonesai/mega-kadence-bridge/releases/latest), upload via WP Admin → Plugins → Add New → Upload Plugin, activate.

### 2. Get bridge credentials

In WordPress: **Settings → Mega Kadence Bridge → "Copy Environment Variables"**. The button copies a small block of text to your clipboard.

### 3. Run the deploy

From the repo root:

```bash
./deploy.sh
```

The script walks you through everything — no editor required:

1. **First it asks for your bridge credentials.** Paste the env block you just copied, then press `Ctrl+D` on a new line.
2. **Then it asks 6 questions about your store** — brand name, what you sell, light or dark mode, your brand color, product categories, optional logo URL. Just type the answers as it asks.
3. **Then it deploys.** ~15 minutes, prints `[node] Started/Completed` for each of 43 steps, ends with `DEPLOYMENT SUCCESSFUL`.

Visit your site — homepage, about, contact, shop, and 3 legal pages, all live.

### Re-running

`./deploy.sh` is idempotent — running it again with no changes won't break anything. To change your answers:

- `./deploy.sh --intake` — re-prompts the 6 store questions, keeps your bridge creds
- `./deploy.sh --reset` — re-prompts everything from scratch

## Tweaking after the deploy

Any change you want — a new headline, swap an image, add a section — just ask Claude one-off:

```bash
claude
```

Then in plain English:

> On cutemerch.love, change the homepage headline to "Cute Merch For Everyone".

> Add a customer-reviews section above the footer.

> Replace the hero image with this one: https://cdn.example.com/new-hero.jpg.

Claude uses the bridge directly for one-off edits — no workflow run needed.

## How the harness works

The deploy is a 43-node DAG. Most nodes are deterministic bash; a few are AI sessions for things that need judgment (page copy generation). After every state-changing node, a validator hits the live site and checks the change actually took effect. If it didn't, the workflow halts loud — failure is impossible to ship.

Major validation gates:

| Gate | Catches |
|---|---|
| `check-palette` | Palette actually applied |
| `check-products` | 4+ products exist |
| `check-homepage`, `check-about`, `check-contact`, `check-legal-pages` | Each page renders 200 with required markup |
| `check-no-block-warnings` | Zero "Attempt Block Recovery" warnings |
| `check-menus`, `check-header-config`, `check-footer-config` | Header/footer/nav structurally correct |
| `check-body-text-color`, `check-logo-color`, `check-hero-padding`, `check-drawer-colors` | Dark-mode CSS rules actually present in rendered HTML |
| `final-check` | All 7 site URLs return 200 |

The last 4 are the dark-mode failure modes that used to require Claude to remember 11+ gotchas across 300 lines of doc. Now they're enforced by bash.

## Troubleshooting

- **Workflow halts with `FAIL: ...`** — read the message. It tells you exactly which step failed and why. Fix the underlying issue and re-run; the deploy is idempotent (existing pages/menus/products are detected and reused).
- **`OAuth token expired`** — run `claude` once to refresh.
- **`Bridge not reachable`** — confirm the URL in `.env`, that the plugin is active, and that app passwords are enabled in WP.
- **Site still looks broken visually** — that shouldn't happen, every visual concern is enforced by deterministic validators. If something does slip through, open an issue with the rendered HTML attached.

## Repository layout

```
.archon/
├── workflows/deploy-pod-store.yaml    # The 43-node DAG
├── commands/                          # 7 atomic AI command files
├── lib/                               # Shared bash (bridge, chrome, dark-mode-css, ...)
└── scripts/run-archon.sh              # OAuth wrapper for Archon
boilerplate/                           # Legal page text templates
references/                            # Tone/font pairings, gotchas, API ref
recipes/                               # Per-page deploy recipes (kept for reference)
templates/                             # Golden HTML for home/about/contact pages
intake.json.example                    # Copy + edit
.env.example                           # Copy + edit
SKILL.md                               # Old monolithic skill — kept for one-off Claude edits
```

## License

GPL v2 or later. See [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome at [github.com/jonjonesai/store-drop-skill](https://github.com/jonjonesai/store-drop-skill).

---

Built by [Jon Jones](https://github.com/jonjonesai) with Claude Code.
