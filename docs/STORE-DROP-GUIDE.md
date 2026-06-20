# Drop a Fully-Built Branded Store in ~15 Minutes

**Watch the video, then follow along here.** This is the written companion to the deploy video — read it, do it, ship it.

You give it six answers. It hands you back a complete, branded WordPress + WooCommerce storefront: homepage, About, Contact, Shop, legal pages, header with your logo, a legible footer, your color palette in light *or* dark mode, starter products, and working contact + newsletter forms. No page builders, no theme wrestling, no copy-paste from a template kit.

> **Where this fits.** Dropping the store is **step one** of a self-running merch business:
> 1. **Drop a store** ← *you are here*
> 2. A fully built-out, ready-to-sell branded site
> 3. Set up a MEGA account and buy credits
> 4. Integrate MEGA with your branded site
> 5. Generate real print-on-demand products with MEGA
> 6. Hook up **JonOps** — a container on cron doing market intelligence, keyword + content research, blogs, and social posting, building impressions while you sleep
>
> This guide gets you through step 1 (and sets up 2). The rest is the ecosystem.

---

## What you need first

- **A domain with a fresh WordPress install.** Any host works; a one-click WordPress on Hostinger is the easy path. You just need a clean WP site and admin login.
- **A computer with a terminal.** Mac/Linux already have one. On **Windows**, you'll turn on WSL (one command — covered below).
- **About 20 minutes**, most of which is the build running on its own.
- *(For the products step later)* a **MEGA account** at mega.management with credits. You don't need it to drop the store — only to fill it with real designs afterward.

---

## Step 1 — Install the Bridge (this is where your keys are born)

The store builder talks to your site through one small plugin: the **Mega Kadence Bridge**.

1. In **wp-admin → Plugins → Add New → Upload Plugin**, upload the Mega Kadence Bridge zip and **Activate** it.
2. Go to **Settings → Mega Kadence Bridge** and click **“Copy Environment Variables.”**

That copies a short block of text — your site URL plus a secure application password. **This is the only credential you'll need.** Paste it somewhere for a second; you'll hand it to the builder shortly.

> 🔑 Those keys *are* the connection. Nothing else logs into your site. You can revoke them anytime by deleting the application password in WordPress.

---

## Step 2 — Set up your terminal (one command)

**Windows only:** open **PowerShell** and run `wsl --install`, reboot, then open **Ubuntu** from the Start menu. (Mac/Linux: just open Terminal.)

Then run the bootstrap — it installs everything you need (Claude Code, the Archon workflow runner, and the store-drop skill) and puts them on your PATH:

```bash
curl -fsSL https://raw.githubusercontent.com/jonjonesai/store-drop-skill/main/setup.sh | bash
```

Open a **fresh terminal window**, run `claude`, and log in when prompted. That's the setup done — you only do this once per machine.

---

## Step 3 — Install the store stack

Your fresh WordPress doesn't have the theme and plugins a real store needs yet. One command installs them all onto your site through the bridge — the Kadence theme + Pro blocks, WooCommerce, Stripe, Printful, and the Fluent forms/CRM stack:

```bash
cd ~/kadence-skill/store-drop-skill
./install-stack.sh
```

It checks each install and retries automatically if a download hiccups, so let it run to “stack install complete.”

---

## Step 4 — Drop the store

```bash
./deploy.sh
```

It asks two things:

1. **Paste your bridge keys** (the block you copied in Step 1).
2. **Answer six questions** about your brand:
   - **Brand name** — e.g. `generationx.art`
   - **Niche / description** — one or two sentences in your brand's voice. The richer this is, the better your copy. *(e.g. “bold pop-art comic-book merch for Gen X — 80s/90s nostalgia as halftone-dotted, heavy-ink statement pieces; cool, dry, edgy.”)*
   - **Light or dark** — the whole site's mode
   - **Accent color** — a hex code, e.g. `#E5322B`
   - **Product categories** — comma-separated, e.g. `T-Shirts, Hoodies, Posters, Mugs, Stickers`
   - **Logo URL** — a public link to your logo (transparent PNG is best)

Then it builds — about 15 minutes, fully automated. You'll watch it work through ~47 steps, and after each one it **re-checks your live site and stops loudly if anything's wrong**, so a finished run means a verified store.

---

## Step 5 — You have a store

When it prints **“DEPLOYMENT SUCCESSFUL,”** open your domain. You'll have:

| Page | What's on it |
|---|---|
| **Home** | Hero, trust badges, brand story, featured products, newsletter signup |
| **About** | Your story + values, all in your brand voice |
| **Contact** | Contact info + a working message form |
| **Shop** | Your product catalog |
| **Privacy / Terms / Returns** | Standard legal pages |

…with your logo in the header, your palette throughout, light or dark mode, a clean footer, and starter products labeled *“Replace with MEGA.”* Everything is real WordPress you fully own and can edit.

---

## Step 6 — Make it yours (the ecosystem from here)

The store is the launchpad, not the finish line:

1. **Add real products.** Replace the starter products with designs generated from your **MEGA** credits — on-brand art, mockups, and listings.
2. **Turn on payments + fulfillment.** Connect Stripe (checkout) and Printful (print-on-demand shipping).
3. **Hook up JonOps.** Drop a small Linux container on a cron schedule that runs your market intelligence, keyword and content research, writes blogs, and posts to socials — compounding impressions and traffic on autopilot.

That's the whole arc: **drop a store, fill it from MEGA, let JonOps run it.**

---

## Notes & troubleshooting

- **“Could not reach bridge.”** The Mega Kadence Bridge plugin must be **active**, and you must paste the keys exactly as copied. Re-copy from Settings → Mega Kadence Bridge.
- **A plugin install 500s.** Transient host timeouts on plugin downloads are retried automatically; just let `install-stack.sh` finish.
- **The build halts on a check.** That's by design — every step is validated. The error names the exact problem; fix it and re-run. Re-running is safe (pages overwrite, nothing duplicates).
- **Everything is reversible.** It's your WordPress. Edit any page, swap the logo, change colors — or ask Claude to fix anything for you.
