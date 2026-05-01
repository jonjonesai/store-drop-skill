# Hostinger Gotchas

> Everything that's different about Hostinger hosting. Discovered during mega.management dogfooding (Sessions 1-2, April 2026).

## Blockers (will prevent bridge from working)

### 1. Hostinger Tools Disables Application Passwords

**Severity:** Blocker — bridge auth fails silently.

Hostinger pre-installs **Hostinger Tools** which has a setting that disables WordPress Application Passwords by default. Since the bridge uses Application Passwords for auth, this must be turned off before activating the bridge.

**Fix:** Hostinger panel (hPanel) → WordPress → Tools → set "Disable application passwords" to **OFF**. Then deactivate and reactivate Mega Kadence Bridge to regenerate credentials.

### 2. LiteSpeed Strips Authorization Header

**Severity:** Blocker — all authenticated requests return 401.

Hostinger's LiteSpeed server strips the HTTP `Authorization` header before it reaches PHP. Even WordPress's native REST API fails.

**Fix:** Add to the top of `.htaccess` (before the LiteSpeed Cache section):

```apache
CGIPassAuth On
SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1
```

The line that actually fixes it is `CGIPassAuth On` (LiteSpeed-native directive). The `SetEnvIf` line is belt-and-suspenders for Apache compatibility.

**v1.0.1 will auto-write this during plugin activation.**

### 3. Hostinger Bloatware

Hostinger pre-installs 4 plugins. Recommendation:

| Plugin | Action | Why |
|---|---|---|
| Hostinger AI | Delete | Unnecessary, adds admin weight |
| Hostinger Easy Onboarding | Delete | Unnecessary wizard |
| Hostinger Reach | Delete | Marketing upsell |
| Hostinger Tools | Keep | Has the app password toggle (needed) |
| LiteSpeed Cache | Keep | Essential for caching |

## Configuration

| Setting | Value | Notes |
|---|---|---|
| SSH port | **65002** | Not 22. Every SSH command needs `-p 65002` |
| WP-CLI path | `/usr/local/bin/wp` | Not in default PATH |
| WordPress root | `/home/{user}/domains/{domain}/public_html` | Standard Hostinger layout |
| PHP version | 8.x | Check: `php -v`. Change in hPanel → Advanced → PHP |
| SSH key type | Ed25519 or RSA 4096 | Add pub key in hPanel → SSH Keys |

## Common Issues

| Issue | Fix |
|---|---|
| WP-CLI not found | Use full path: `/usr/local/bin/wp` |
| File permission errors | `find $WP_PATH -type f -exec chmod 644 {} \;` and `find $WP_PATH -type d -exec chmod 755 {} \;` |
| LiteSpeed cache not purging | Confirm plugin active: `wp plugin is-active litespeed-cache --path=$WP_PATH` |
| SSH key auth failing | Hostinger requires Ed25519 or RSA 4096. Add in hPanel → SSH Keys |
| Memory limit errors | Add to wp-config.php: `define('WP_MEMORY_LIMIT', '256M');` |
| Upload size too small | Add to `.htaccess`: `php_value upload_max_filesize 64M` and `php_value post_max_size 64M` |
| Cache returns stale content after plugin install | Call `/cache/flush` after installing any plugin |

## SSH Command Template

```bash
SSH="ssh -p 65002 ${SSH_USER}@${SSH_HOST}"
WP="/usr/local/bin/wp --path=/home/${SSH_USER}/domains/${DOMAIN}/public_html"

# Example: check WordPress version
$SSH "$WP core version"
```
