import unittest

from store_drop.safety import (
    build_certificate,
    category_aware_placeholder_names,
    find_unverified_claims,
    placeholder_is_safe,
)


class EditorialSafetyTests(unittest.TestCase):
    def test_unverified_commercial_claims_are_flagged(self):
        claims = find_unverified_claims("Free shipping and a satisfaction guarantee.", {"facts": {}})
        self.assertEqual({item["category"] for item in claims}, {"shipping", "guarantee"})

    def test_confirmed_claim_is_not_flagged(self):
        intake = {"facts": {"approved_policies": {"shipping": "Free shipping"}}}
        self.assertEqual(find_unverified_claims("Free shipping", intake), [])

    def test_placeholder_defaults_are_not_purchasable(self):
        self.assertTrue(placeholder_is_safe({"name": "Sample Tee", "status": "draft"}))
        self.assertTrue(placeholder_is_safe({"name": "Placeholder Mug", "status": "publish", "stock_status": "outofstock"}))
        self.assertFalse(placeholder_is_safe({"name": "Sample Tote", "status": "publish", "stock_status": "instock"}))

    def test_category_names_come_from_taxonomy(self):
        names = category_aware_placeholder_names(["Wall Art", "Apparel"])
        self.assertIn("Wall Art", names[0])
        self.assertIn("Apparel", names[1])

    def test_certificate_uses_verified_state_and_blocks_demo_labels(self):
        intake = {"launch": {"enable_sales": True, "approved_by": "operator"}, "facts": {}}
        state = {
            "site": "https://example.test",
            "tagline": "actual read-back tagline",
            "palette": {"1": "#DA3F58"},
            "pages": {"/": 200},
            "products": [],
            "form_titles": ["Contact Form Demo"],
            "rendered_text": "neutral copy",
        }
        certificate = build_certificate(state, intake)
        self.assertEqual(certificate["verified_state"]["palette"]["1"], "#DA3F58")
        self.assertFalse(certificate["launch"]["certified"])
        self.assertIn("visible demo form title: Contact Form Demo", certificate["launch"]["blockers"])

    def test_structured_certificate_can_certify_verified_launch(self):
        intake = {"launch": {"enable_sales": True, "approved_by": "operator"}, "facts": {}}
        state = {
            "site": "https://example.test",
            "pages": {"/": 200, "/shop/": 200},
            "products": [{"name": "Approved Print", "status": "publish", "stock_status": "instock"}],
            "form_titles": ["Contact Form"],
            "rendered_text": "Neutral approved storefront copy.",
        }
        certificate = build_certificate(state, intake)
        self.assertTrue(certificate["launch"]["certified"])
        self.assertEqual(certificate["launch"]["blockers"], [])


if __name__ == "__main__":
    unittest.main()
