/**
 * {{BRAND_SHORT}}: Inject WP Social Ninja Pro reviews widget into the WooCommerce reviews tab.
 *
 * Prepends the widget's rendered HTML to the existing reviews-tab callback so submitted
 * reviews (with photos) appear ABOVE the "Write a Review" button.
 *
 * Required placeholders:
 *   {{WPSR_TEMPLATE_ID}} — the ID of the WPSR Reviews template created via Social Ninja
 *                         admin UI wizard (e.g. 23946). Must be a fully-saved template;
 *                         a half-completed wizard leaves `_wpsr_template_config` empty
 *                         and the widget renders nothing.
 *
 * Shortcode gotchas — DO NOT change these unless you understand them:
 *   - Use `platform="reviews"` (the renderer's allowed value), NOT `platform="woocommerce"`.
 *     The valid shortcode platforms are: reviews / twitter / youtube / instagram / facebook /
 *     tiktok / facebook_feed / testimonial. WooCommerce is the *source* the template draws
 *     from (stored in the template post's `post_content`), not a shortcode-accepted platform.
 *     Passing `platform="woocommerce"` returns "Provided platform name is not valid."
 *   - The shortcode tag is `wp_social_ninja`, NOT `wpsr-reviews-<ID>`. The `wpsr-reviews-<ID>`
 *     string IS the rendered CSS class, but is not a shortcode handler.
 */
add_action( 'woocommerce_product_tabs', function( $tabs ) {
    if ( isset( $tabs['reviews']['callback'] ) ) {
        $original = $tabs['reviews']['callback'];
        $tabs['reviews']['callback'] = function() use ( $original ) {
            // CRITICAL: pass product_id explicitly so the widget filters to the CURRENT
            // product. Without it, every review in wp_wpsr_reviews renders on every
            // product page (one product's review leaks onto every product's page).
            $pid = get_the_ID();
            echo do_shortcode( '[wp_social_ninja id="{{WPSR_TEMPLATE_ID}}" platform="reviews" product_id="' . intval( $pid ) . '"]' );
            call_user_func( $original );
        };
    }
    return $tabs;
}, 100 );
