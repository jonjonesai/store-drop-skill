#!/usr/bin/env python3
"""Read the deployed site back and write a credential-free certificate."""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from store_drop.safety import build_certificate  # noqa: E402


class Bridge:
    def __init__(self) -> None:
        self.base = os.environ["BRIDGE_URL"].rstrip("/")
        raw = f"{os.environ.get('BRIDGE_USER', 'store-drop-agent')}:{os.environ['BRIDGE_PASS']}"
        self.auth = "Basic " + base64.b64encode(raw.encode()).decode()

    def request(self, path: str, body: dict | None = None) -> dict:
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(self.base + path, data=data, headers={"Authorization": self.auth, "Content-Type": "application/json"}, method="POST" if body is not None else "GET")
        last: Exception | None = None
        for attempt in range(3):
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    return json.load(response)
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                last = exc
                if attempt < 2:
                    time.sleep(attempt + 1)
        raise RuntimeError(f"bridge read-back failed for {path} after 3 attempts") from last


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--intake", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    intake = json.loads(Path(args.intake).read_text(encoding="utf-8"))
    bridge = Bridge()
    paths = ("/", "/about/", "/contact/", "/shop/", "/privacy-policy/", "/terms-of-service/", "/returns-and-refunds/")
    page_status: dict[str, int] = {}
    rendered: list[str] = []
    for path in paths:
        result = bridge.request(f"/render?url={path}")
        page_status[path] = int(result.get("status", 0))
        rendered.append(re.sub(r"<[^>]+>", " ", str(result.get("html", ""))))
    products_result = bridge.request("/woo/products")
    products = products_result.get("products", products_result if isinstance(products_result, list) else [])
    forms_code = "global $wpdb; $t=$wpdb->prefix.'fluentform_forms'; return $wpdb->get_col(\"SELECT title FROM {$t}\");"
    forms_result = bridge.request("/wp-eval", {"code": forms_code})
    form_titles = forms_result.get("result", []) if forms_result.get("success") else []
    all_text = "\n".join(rendered)
    state = {
        "site": os.environ.get("BRIDGE_SITE") or bridge.base.split("/wp-json", 1)[0],
        "provider": os.environ.get("AI_PROVIDER"),
        "model": os.environ.get("AI_MODEL"),
        "tagline": bridge.request("/option/blogdescription").get("value"),
        "palette": bridge.request("/palette").get("palette"),
        "pages": page_status,
        "products": products,
        "form_titles": form_titles,
        "rendered_text": all_text,
        "unresolved_drafts": ([{"category": "legal", "claim": "prelaunch legal drafts remain"}] if "prelaunch draft" in all_text.lower() else []),
    }
    certificate = build_certificate(state, intake)
    Path(args.output).write_text(json.dumps(certificate, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"CERTIFICATE: {args.output}")
    print("LAUNCH CERTIFIED" if certificate["launch"]["certified"] else "LAUNCH REVIEW REQUIRED")
    for blocker in certificate["launch"]["blockers"]:
        print(f"  - {blocker}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
