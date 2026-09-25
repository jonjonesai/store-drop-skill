# MEGA Store — Student Intake

Operators use this intake with the selected Store Drop agent. The agent asks the six core questions, records facts and launch approval separately, then builds.

---

## The Paste (students copy this exactly)

```
I'm setting up my MEGA store. Please ask me the 6 setup questions
one at a time, then build everything when you have my answers.

Load the Store Drop Skill from:
https://raw.githubusercontent.com/jonjonesai/store-drop-skill/main/SKILL.md

My .env file is in this project folder with my bridge credentials.
```

---

## Agent 6-Question Flow

Ask these in order. Wait for each answer before asking the next. Keep it conversational, not robotic.

**Q1 -- Store Name**
> "What's your store name? This will appear in the browser tab,
> footer, and SEO titles."

**Q2 -- Niche**
> "What's your niche? Be specific -- not just 'pets' but
> 'funny golden retriever shirts' or 'tactical hunting gear'.
> The more specific, the better your store copy and product
> categories."

**Q3 -- Style: Light or Dark?**
> "Pick your vibe:
>
> DARK -- bold, dramatic, premium. Great for: streetwear,
> gaming, hunting, coffee, gym, skulls, anything edgy.
>
> LIGHT -- clean, bright, friendly. Great for: pets, baby,
> home decor, flowers, food, inspirational quotes, nature.
>
> Which fits your niche better? (or just say dark/light)"

**Q4 -- Brand Color**
> "What's your primary brand color?
> You can say a hex code (#FF5500), a color name (deep red,
> forest green, hot pink), or just say 'I don't know' and
> I'll pick something great for your niche."

**Q5 -- Product Categories**
> "What are your main 2-3 product categories?
> Examples: 'T-Shirts, Hoodies, Mugs' or 'Wall Art, Phone Cases, Totes'.
> This helps me set up your shop with the right categories."

**Q6 -- Logo**
> "Do you have a logo ready?
> - YES: upload it now (PNG with transparent bg is best)
> - NO: I'll use a clean text logo for now. You can swap
>   it any time by uploading one and telling me."

---

## After All 6 Answers -- The Agent Executes

After the six design answers, record confirmed facts, approved policies, and
launch approval separately. Missing policy text remains a visible draft;
`launch.enable_sales` defaults to false. Then run the provider-neutral Archon
workflow with `./deploy.sh`.

1. Apply palette (set-palette recipe)
2. Apply fonts by tone (set-fonts-by-tone recipe, inferred from niche)
3. Create WC product categories from Q5 answers
4. Create 4 category-aware, non-purchasable placeholder products if none exist
5. Build the 7-section homepage (deploy-homepage recipe)
6. Build About page (deploy-about recipe)
7. Build Contact page (deploy-contact recipe)
8. Generate prelaunch legal drafts unless approved policy text was supplied
9. Wire primary + footer nav menus (build-nav-menus recipe)
10. Set homepage as front page
11. Upload logo if provided
12. Flush all caches
13. Verify every page via /render
14. Write a final certificate from API and rendered read-back state

The operator gets a verified storefront build. Sales launch remains blocked
until the certificate reports `launch.certified: true`.

---

## Handling Edge Cases

**"I don't know" for brand color:** Use the mode default -- `#FF5500` for dark, `#1B4F8A` for light. Don't ask follow-up questions. Just pick it and tell them what you chose.

**No logo:** Use text-based site title. Set `custom_logo` to empty. The header displays the site name in the heading font.

**Vague niche:** If they say just "pets" or "clothes", ask ONE follow-up: "Can you narrow it down? 'Funny cat shirts' or 'minimalist dog portraits' helps me write much better copy for your store." Accept whatever they give after that -- don't push further.

**Only 1 product category:** That's fine. Create it. Add a generic "All Products" category alongside it.
