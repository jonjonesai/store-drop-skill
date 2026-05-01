# Mega Kadence Skill

A Claude Code skill that deploys fully branded POD (print-on-demand) stores on WordPress + Kadence + WooCommerce through natural language. Paired with [Mega Kadence Bridge](https://github.com/jonjonesai/mega-kadence-bridge) (the WordPress plugin that provides the REST API).

## What It Does

You describe your store. Claude builds it. In under 15 minutes you get:

- A 7-section branded homepage (hero, products, story, trust row, CTA, newsletter, footer)
- About, Contact, and Shop pages
- Privacy Policy, Terms of Service, Returns & Refunds pages
- Navigation menus wired up
- Brand colors, fonts, and logo applied globally
- 4 placeholder products in WooCommerce
- Everything WCAG 2.1 AA accessible

All through conversation with Claude -- no WordPress knowledge required.

## Prerequisites

1. A Hostinger WordPress hosting account ($2.99/mo)
2. Kadence Theme (free) and Kadence Blocks (free) installed
3. WooCommerce installed
4. [Mega Kadence Bridge](https://github.com/jonjonesai/mega-kadence-bridge/releases/latest) plugin installed and activated
5. [Claude Code](https://claude.ai/code) installed on your computer

## Quick Start

### 1. Install the bridge plugin

Download the [latest release ZIP](https://github.com/jonjonesai/mega-kadence-bridge/releases/latest), upload via WP Admin > Plugins > Add New > Upload Plugin, activate.

### 2. Get your credentials

Go to Settings > Mega Kadence Bridge, click "Copy as .env", paste into a file called `.env` in your project folder.

### 3. Start Claude Code and paste this

```
I'm setting up my MEGA store. Please ask me the 6 setup questions
one at a time, then build everything when you have my answers.

Load the Mega Kadence Skill from:
https://raw.githubusercontent.com/jonjonesai/mega-kadence-skill/main/SKILL.md

My .env file is in this project folder with my bridge credentials.
```

### 4. Answer 6 questions

Claude asks about your store name, niche, style preference, brand color, product categories, and logo. Answer each one and Claude builds your entire store.

## Repository Structure

```
mega-kadence-skill/
├── SKILL.md                        Main skill (what Claude loads)
├── INTAKE.md                       6-question student intake wizard
├── deploy-pod-store.md             End-to-end deployment orchestrator
├── recipes/
│   ├── deploy-homepage.md          7-section homepage builder
│   ├── deploy-about.md             About page builder
│   ├── deploy-contact.md           Contact page builder
│   ├── deploy-legal-pages.md       Legal pages (Privacy, Terms, Returns, Cookie)
│   ├── set-palette.md              9-slot color palette (light + dark mode)
│   ├── set-fonts-by-tone.md        10 tone-based font pairings
│   ├── build-nav-menus.md          Primary + footer menu wiring
│   └── verify-deployment.md        Render-and-grep verification loop
├── boilerplate/
│   ├── privacy-policy.md           Template with {brand_name} placeholders
│   ├── terms-of-service.md
│   ├── returns-and-refunds.md
│   └── cookie-policy.md
├── references/
│   ├── mkb-api-reference.md        MKB v1.0.0 endpoint cheat sheet
│   ├── kadence-block-patterns.md   Proven block markup snippets
│   ├── tone-font-pairings.md       Font pairing matrix
│   └── hostinger-gotchas.md        Hosting-specific fixes
├── LICENSE                         GPL v2+
└── .gitignore
```

## The MEGA Ecosystem

This skill is part of the [MEGA](https://mega.management) print-on-demand ecosystem:

- **MEGA Wholesale** (app.mega.management) -- AI-powered POD product generation
- **Mega Kadence Bridge** -- WordPress REST API plugin for Claude control
- **Mega Kadence Skill** -- This repo. The brain that drives deployment

Together, they let anyone launch a branded POD store in a weekend at $3/month hosting instead of $40/month on Shopify.

## Known Issues (v1)

- **Placeholder product guard checks `product_count == 0`.** If the site already has products from a prior test run or manual creation, the 4 placeholder products won't be created. Manual cleanup of stale test products may be needed before re-running the deploy.

## License

GPL v2 or later. See [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome at [github.com/jonjonesai/mega-kadence-skill](https://github.com/jonjonesai/mega-kadence-skill).

---

Built by [Jon Jones](https://github.com/jonjonesai) with Claude Code.
