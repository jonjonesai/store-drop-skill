/**
 * {{BRAND_SHORT}}: Replace WooCommerce Default Review Form with Fluent Form Modal
 *
 * Hides the default WC comment-based review form, adds a branded "Write a Review" button
 * under the product reviews tab, and opens the Fluent Form in a modal overlay.
 * The upload-handler snippet (snippet-upload-handler.php) auto-injects the dropzone
 * into the form inside the modal.
 *
 * Required placeholders:
 *   {{FF_FORM_ID}}        — the Fluent Form ID of the Product Review Form (e.g. 5)
 *   {{BRAND_PRIMARY_HEX}} — modal accent + button background (e.g. #215387)
 *   {{BRAND_HOVER_HEX}}   — button hover background (e.g. #ff181d)
 *   {{BRAND_HEADING_HEX}} — modal heading color (e.g. #222c88)
 *   {{BRAND_FONT_CSS}}    — heading font-family CSS string (e.g. 'Righteous', cursive)
 */

add_action( 'wp_footer', function() {
    if ( ! function_exists( 'is_product' ) || ! is_product() ) return;
    ?>
    <style>
    .woocommerce-Reviews #respond.comment-respond { display: none !important; }

    .twm-review-btn {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        background: {{BRAND_PRIMARY_HEX}};
        color: #fff;
        border: none;
        padding: 12px 28px;
        border-radius: 6px;
        font-family: {{BRAND_FONT_CSS}};
        font-size: 16px;
        cursor: pointer;
        margin: 16px 0;
        transition: background 0.2s ease;
    }
    .twm-review-btn:hover { background: {{BRAND_HOVER_HEX}}; }
    .twm-review-btn svg { flex-shrink: 0; }

    .twm-review-modal-overlay {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(0,0,0,0.55);
        z-index: 99999;
        justify-content: center;
        align-items: center;
        padding: 20px;
    }
    .twm-review-modal-overlay.open { display: flex; }

    .twm-review-modal {
        background: #fff;
        border-radius: 12px;
        width: 100%;
        max-width: 520px;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        position: relative;
    }
    .twm-review-modal-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 20px 24px 16px;
        border-bottom: 1px solid #e2e8f0;
    }
    .twm-review-modal-header h3 {
        margin: 0;
        font-family: {{BRAND_FONT_CSS}};
        color: {{BRAND_HEADING_HEX}};
        font-size: 20px;
    }
    .twm-review-modal-close {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: #666;
        width: 36px;
        height: 36px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 50%;
        transition: background 0.2s;
    }
    .twm-review-modal-close:hover { background: #f0f0f0; }
    .twm-review-modal-body { padding: 20px 24px 24px; }

    .twm-review-modal .fluentform { margin: 0; }
    .twm-review-modal .ff-el-group { margin-bottom: 16px; }
    </style>

    <div class="twm-review-modal-overlay" id="twm-review-overlay">
        <div class="twm-review-modal">
            <div class="twm-review-modal-header">
                <h3>Write a Review</h3>
                <button class="twm-review-modal-close" id="twm-review-close" aria-label="Close">&times;</button>
            </div>
            <div class="twm-review-modal-body">
                <?php echo do_shortcode( '[fluentform id="{{FF_FORM_ID}}"]' ); ?>
            </div>
        </div>
    </div>

    <script>
    (function(){
        function insertBtn() {
            var tab = document.getElementById('tab-reviews');
            if (!tab) return false;
            if (document.getElementById('twm-review-trigger')) return true;
            var comments = tab.querySelector('#comments');
            if (!comments) return false;
            var btn = document.createElement('button');
            btn.type = 'button';
            btn.id = 'twm-review-trigger';
            btn.className = 'twm-review-btn';
            btn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/></svg> Write a Review';
            comments.appendChild(btn);
            btn.addEventListener('click', function() {
                document.getElementById('twm-review-overlay').classList.add('open');
                document.body.style.overflow = 'hidden';
            });
            return true;
        }
        var overlay = document.getElementById('twm-review-overlay');
        document.getElementById('twm-review-close').addEventListener('click', function() {
            overlay.classList.remove('open');
            document.body.style.overflow = '';
        });
        overlay.addEventListener('click', function(e) {
            if (e.target === overlay) { overlay.classList.remove('open'); document.body.style.overflow = ''; }
        });
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && overlay.classList.contains('open')) { overlay.classList.remove('open'); document.body.style.overflow = ''; }
        });
        if (window.jQuery) {
            jQuery(document).on('fluentform_submission_success', function() {
                setTimeout(function() { overlay.classList.remove('open'); document.body.style.overflow = ''; }, 2000);
            });
        }
        if (!insertBtn()) {
            var iv = setInterval(function() { if (insertBtn()) clearInterval(iv); }, 300);
            setTimeout(function() { clearInterval(iv); }, 10000);
        }
    })();
    </script>
    <?php
});
