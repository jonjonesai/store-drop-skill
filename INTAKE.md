# MEGA Store — Student Intake

Students paste the setup block below into Claude on Day 1. Claude reads it, asks the 6 questions one at a time, then builds everything.

---

## The Paste (students copy this exactly)

```
I'm setting up my MEGA store. Please ask me the 6 setup questions
one at a time, then build everything when you have my answers.

Load the Mega Kadence Skill from:
https://raw.githubusercontent.com/jonjonesai/mega-kadence-skill/main/SKILL.md

My .env file is in this project folder with my bridge credentials.
```

---

## Claude's 6-Question Flow

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

## After All 6 Answers -- Claude Executes

Once you have all answers, execute `deploy-pod-store.md` without asking for permission between steps. The student already gave you everything you need.

1. Apply palette (set-palette recipe)
2. Apply fonts by tone (set-fonts-by-tone recipe, inferred from niche)
3. Create WC product categories from Q5 answers
4. Create 4 placeholder products if none exist
5. Build the 7-section homepage (deploy-homepage recipe)
6. Build About page (deploy-about recipe)
7. Build Contact page (deploy-contact recipe)
8. Generate 4 legal pages (deploy-legal-pages recipe)
9. Wire primary + footer nav menus (build-nav-menus recipe)
10. Set homepage as front page
11. Upload logo if provided
12. Flush all caches
13. Verify every page via /render
14. Print final summary

**Student gets a live branded store. Target time: under 15 minutes.**

---

## Handling Edge Cases

**"I don't know" for brand color:** Use the mode default -- `#FF5500` for dark, `#1B4F8A` for light. Don't ask follow-up questions. Just pick it and tell them what you chose.

**No logo:** Use text-based site title. Set `custom_logo` to empty. The header displays the site name in the heading font.

**Vague niche:** If they say just "pets" or "clothes", ask ONE follow-up: "Can you narrow it down? 'Funny cat shirts' or 'minimalist dog portraits' helps me write much better copy for your store." Accept whatever they give after that -- don't push further.

**Only 1 product category:** That's fine. Create it. Add a generic "All Products" category alongside it.
