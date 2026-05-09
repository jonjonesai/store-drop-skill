# Recipe: Install + Activate Fluent Forms

> Ensures Fluent Forms is installed and active on the target site so the contact-page template's `[fluentform id="1"]` shortcode renders a real form. Auto-runs in `deploy-pod-store.yaml` as the `ensure-fluent-forms` node.

## Why this exists

The contact-page template (`templates/contact.html`) embeds:

```
[fluentform id="1"]
```

Fluent Forms auto-creates form ID 1 ("Contact Form Demo") on plugin activation, with proper Name/Email/Subject/Message fields. Every fresh FF install has it. So the only prerequisite is that Fluent Forms be installed and active before the contact page is rendered.

For sites where FF was pre-installed manually (e.g. cutemerch.love early deploys), this step is a no-op — the bridge endpoint short-circuits when FF is already active. For fresh student sites it's load-bearing.

## Inputs Required

None. The endpoint takes a hard-coded slug.

## Prerequisites

- Mega Kadence Bridge **v1.1.0+** installed and active on the target site (provides `/plugins/install-and-activate`)
- `claude-bot` user has `administrator` role (default per `class-activator.php` in the bridge plugin)

## Execution

### Step 1: Call the bridge

```bash
source "$HOME/kadence-skill/store-drop-skill/.archon/lib/bridge.sh"
bridge_check_env || exit 1

RESPONSE=$(bridge_post "/plugins/install-and-activate" '{"slug":"fluentform"}')
```

The endpoint accepts `{ slug: "fluentform" }` for wordpress.org plugins or `{ zip_url: "https://..." }` for premium plugin ZIPs (used by future wizard "upload your premium plugin" flows).

### Step 2: Parse the response

```bash
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json;print(json.load(sys.stdin).get('success',''))" 2>/dev/null)
if [ "$SUCCESS" != "True" ]; then
  echo "FAIL: Fluent Forms install/activate failed"
  echo "Response: $RESPONSE"
  exit 1
fi

ALREADY=$(echo "$RESPONSE" | python3 -c "import sys,json;print(json.load(sys.stdin).get('already_active',''))" 2>/dev/null)
PLUGIN=$(echo "$RESPONSE" | python3 -c "import sys,json;print(json.load(sys.stdin).get('plugin',''))" 2>/dev/null)
```

### Step 3: Report

```bash
if [ "$ALREADY" = "True" ]; then
  echo "PASS: Fluent Forms already active ($PLUGIN)"
else
  echo "PASS: Fluent Forms installed and activated ($PLUGIN)"
fi
```

## Response Shape

Successful install (first time):
```json
{ "success": true, "installed": true, "activated": true, "plugin": "fluentform/fluentform.php" }
```

Already active (idempotent re-run):
```json
{ "success": true, "installed": true, "activated": true, "already_active": true, "plugin": "fluentform/fluentform.php" }
```

Install failure (e.g. wp.org slug not found, file system locked):
```json
{ "code": "mkb_install_failed", "message": "Plugin install failed: ...", "data": { "status": 500 } }
```

## Verifying the form actually renders

After this recipe, the `check-contact` node in the workflow asserts:

```bash
assert_grep "contact embeds a Fluent Form" 'fluentform|ff-el-form' "$HTML"
```

If FF was activated but the shortcode renders nothing, that check fails — surfacing a stale install or missing form ID 1. The fix is usually deactivate + reactivate FF (which re-creates form 1).

## Gotchas

1. **Bridge version.** Endpoint requires MKB v1.1.0+. Older bridges return a 404. Update the bridge plugin on the target site before this DAG node runs.

2. **Plugin update checker lag.** If the bridge was just bumped to v1.1.0 and the target site's plugin update checker hasn't refreshed, the new endpoint isn't available yet. Force-update via WP admin → Plugins → "Update available", or run `wp plugin update mega-kadence-bridge` via SSH/CLI.

3. **Hostinger file-system permissions.** Some shared-hosting setups deny `wp-content/plugins/` writes from REST contexts. If the install errors with `mkb_install_failed`, check FTP/file permissions are 755 on the plugins directory.

4. **Fluent Forms Pro.** This recipe installs the FREE Fluent Forms slug (`fluentform`). For the Pro version (paid), use `{ zip_url: "https://..." }` with the customer's licensed download URL — same endpoint, different parameter.
