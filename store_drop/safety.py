"""Editorial and launch-readiness rules shared by workflow and tests."""

from __future__ import annotations

import re
from typing import Any, Iterable


RISK_PATTERNS = {
    "guarantee": re.compile(r"\b(satisfaction guarantee|money[- ]back guarantee|guaranteed)\b", re.I),
    "shipping": re.compile(r"\b(free shipping|ships? in \d+|production time|delivery in \d+)\b", re.I),
    "donation_impact": re.compile(r"\b(proceeds (?:go|support)|every purchase supports|donated to)\b", re.I),
    "organization": re.compile(r"\b(designed by (?:our|the) organization|cultural advisor|scholarships?|exchanges?|community classes)\b", re.I),
    "service_levels": re.compile(r"\b(response within \d+|respond within \d+|\d+[- ]hour response)\b", re.I),
    "returns": re.compile(r"\b(returns? within \d+|refunds? within \d+|\d+[- ]day returns?)\b", re.I),
}


def intake_errors(intake: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    required = ("brand_name", "niche", "mode", "color", "categories", "logo")
    for key in required:
        if intake.get(key) in (None, ""):
            errors.append(f"missing intake field: {key}")
    launch = intake.get("launch", {})
    if launch and not isinstance(launch, dict):
        errors.append("launch must be an object")
    if isinstance(launch, dict) and launch.get("enable_sales") and not launch.get("approved_by"):
        errors.append("launch.enable_sales requires launch.approved_by")
    facts = intake.get("facts", {})
    if facts and not isinstance(facts, dict):
        errors.append("facts must be an object")
    return errors


def approved_claim_text(intake: dict[str, Any]) -> str:
    facts = intake.get("facts", {}) if isinstance(intake.get("facts", {}), dict) else {}
    values: list[str] = []
    for value in facts.values():
        if isinstance(value, str):
            values.append(value)
        elif isinstance(value, list):
            values.extend(str(item) for item in value)
        elif isinstance(value, dict):
            values.extend(str(item) for item in value.values())
    return "\n".join(values)


def find_unverified_claims(rendered_text: str, intake: dict[str, Any]) -> list[dict[str, str]]:
    approved = approved_claim_text(intake)
    unresolved: list[dict[str, str]] = []
    for category, pattern in RISK_PATTERNS.items():
        for match in pattern.finditer(rendered_text):
            claim = match.group(0)
            if not pattern.search(approved) and claim.lower() not in approved.lower():
                unresolved.append({"category": category, "claim": claim})
    return unresolved


def placeholder_is_safe(product: dict[str, Any]) -> bool:
    name = str(product.get("name", ""))
    placeholder = bool(re.search(r"\b(sample|placeholder|replace with)\b", name, re.I))
    if not placeholder:
        return True
    status = str(product.get("status", "")).lower()
    stock = str(product.get("stock_status", "")).lower()
    purchasable = product.get("purchasable")
    return status in {"draft", "private"} or stock == "outofstock" or purchasable is False


def category_aware_placeholder_names(categories: Iterable[str], count: int = 4) -> list[str]:
    cleaned = [str(c).strip() for c in categories if str(c).strip()]
    if not cleaned:
        cleaned = ["Product"]
    return [f"Sample {cleaned[i % len(cleaned)]} — Draft Placeholder" for i in range(count)]


def build_certificate(state: dict[str, Any], intake: dict[str, Any]) -> dict[str, Any]:
    pages = state.get("pages", {})
    products = state.get("products", [])
    unresolved = list(state.get("unresolved_drafts", []))
    unresolved.extend(find_unverified_claims(state.get("rendered_text", ""), intake))
    unsafe_products = [p.get("name", "unnamed") for p in products if not placeholder_is_safe(p)]
    demo_forms = [title for title in state.get("form_titles", []) if re.search(r"\bdemo\b", title, re.I)]
    all_pages_ok = bool(pages) and all(status == 200 for status in pages.values())
    sales_requested = bool(intake.get("launch", {}).get("enable_sales", False))
    blockers: list[str] = []
    blockers.extend(f"unresolved claim: {item.get('category', 'editorial')}" for item in unresolved)
    blockers.extend(f"unsafe placeholder product: {name}" for name in unsafe_products)
    blockers.extend(f"visible demo form title: {title}" for title in demo_forms)
    if not all_pages_ok:
        blockers.append("one or more required pages failed rendered read-back")
    if not sales_requested:
        blockers.append("sales launch not explicitly approved")
    return {
        "schema_version": 1,
        "site": state.get("site"),
        "provider": state.get("provider"),
        "model": state.get("model"),
        "verified_state": {
            "tagline": state.get("tagline"),
            "palette": state.get("palette"),
            "pages": pages,
            "products": products,
            "form_titles": state.get("form_titles", []),
        },
        "unresolved_drafts": unresolved,
        "launch": {
            "sales_requested": sales_requested,
            "certified": not blockers,
            "blockers": blockers,
        },
    }
