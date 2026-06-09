/**
 * {{BRAND_SHORT}} — Post-Purchase Review Request Automation
 *
 * Sends a branded email N days after order completion asking customers to leave a review.
 * Each item links directly to its product page's #reviews anchor.
 *
 * Hooks:  woocommerce_order_status_completed → schedules wp_cron event
 * Cron:   {{BRAND_PREFIX}}_send_review_request → sends the email
 *
 * Required placeholders:
 *   {{BRAND_SHORT}}        — short brand name (e.g. "TaiwanMerch")
 *   {{BRAND_PREFIX}}       — lowercase prefix for action/meta names (e.g. "twm")
 *   {{BRAND_DOMAIN}}       — bare domain (e.g. taiwanmerch.co)
 *   {{BRAND_FROM_EMAIL}}   — sender (e.g. hello@taiwanmerch.co)
 *   {{BRAND_PRIMARY_HEX}}  — primary brand color (e.g. #215387)
 *   {{BRAND_HEADING_HEX}}  — heading color (e.g. #222c88)
 *   {{BRAND_ACCENT_HEX}}   — accent / CTA color (e.g. #ff181d)
 *   {{BRAND_FONT_CSS}}     — heading font-family CSS (e.g. 'Righteous', cursive)
 *   {{BRAND_LOGO_URL}}     — absolute URL to logo PNG
 *   {{BRAND_TABLE_BG_HEX}} — products table background (e.g. #fef3e7)
 *   {{BRAND_ADDRESS}}      — postal address line for footer
 *   {{REVIEW_DELAY_DAYS}}  — delay before sending (default 14)
 *   {{REVIEW_SUBJECT}}     — email subject
 *   {{REVIEW_GREETING}}    — first heading copy, may include {first_name} placeholder
 *   {{REVIEW_BODY_P1}}     — opening paragraph
 *   {{REVIEW_BODY_P2}}     — second paragraph (above products)
 *   {{REVIEW_BODY_P3}}     — closing line above signature
 *   {{REVIEW_SIGNATURE}}   — signature (e.g. "The Taiwan Merch Team")
 */

add_action( '{{BRAND_PREFIX}}_send_review_request', '{{BRAND_PREFIX}}_handle_review_request', 10, 1 );
add_action( 'woocommerce_order_status_completed', '{{BRAND_PREFIX}}_schedule_review_request', 20, 1 );

function {{BRAND_PREFIX}}_schedule_review_request( $order_id ) {
    $scheduled = get_post_meta( $order_id, '_{{BRAND_PREFIX}}_review_scheduled', true );
    if ( $scheduled ) return;

    $delay     = {{REVIEW_DELAY_DAYS}} * DAY_IN_SECONDS;
    $timestamp = time() + $delay;

    wp_schedule_single_event( $timestamp, '{{BRAND_PREFIX}}_send_review_request', [ $order_id ] );
    update_post_meta( $order_id, '_{{BRAND_PREFIX}}_review_scheduled', current_time( 'mysql' ) );

    error_log( '{{BRAND_SHORT}} Review: Scheduled review request for order #' . $order_id . ' at ' . date( 'Y-m-d H:i:s', $timestamp ) );
}

function {{BRAND_PREFIX}}_handle_review_request( $order_id ) {
    $order = wc_get_order( $order_id );
    if ( ! $order ) return;

    $sent = get_post_meta( $order_id, '_{{BRAND_PREFIX}}_review_sent', true );
    if ( $sent ) return;

    $email      = $order->get_billing_email();
    $first_name = $order->get_billing_first_name();
    if ( ! $email ) return;

    $product_links = '';
    foreach ( $order->get_items() as $item ) {
        $product = $item->get_product();
        if ( ! $product ) continue;

        $parent_id      = $product->get_parent_id();
        $review_product = $parent_id ? wc_get_product( $parent_id ) : $product;
        if ( ! $review_product ) continue;

        $name  = $review_product->get_name();
        $url   = get_permalink( $review_product->get_id() ) . '#reviews';
        $image = wp_get_attachment_image_url( $review_product->get_image_id(), 'thumbnail' );

        $product_links .= '
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #e2e8f0;">
                ' . ( $image ? '<img src="' . esc_url( $image ) . '" alt="" style="width:60px;height:60px;object-fit:cover;border-radius:6px;vertical-align:middle;margin-right:12px;">' : '' ) . '
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #e2e8f0; vertical-align: middle;">
                <a href="' . esc_url( $url ) . '" style="color: {{BRAND_HEADING_HEX}}; text-decoration: none; font-weight: bold;">' . esc_html( $name ) . '</a>
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #e2e8f0; text-align: center; vertical-align: middle;">
                <a href="' . esc_url( $url ) . '" style="background: {{BRAND_ACCENT_HEX}}; color: #ffffff; padding: 8px 16px; border-radius: 4px; text-decoration: none; font-family: {{BRAND_FONT_CSS}}; font-size: 14px; display: inline-block;">Leave a Review</a>
            </td>
        </tr>';
    }

    if ( empty( $product_links ) ) return;

    $subject = '{{REVIEW_SUBJECT}}';

    $body = '
    <div style="max-width: 600px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; color: #2D3748;">
        <div style="background: linear-gradient(135deg, {{BRAND_PRIMARY_HEX}} 0%, {{BRAND_HEADING_HEX}} 100%); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
            <img src="{{BRAND_LOGO_URL}}" alt="{{BRAND_SHORT}}" style="max-width: 180px; height: auto;">
        </div>
        <div style="background: {{BRAND_ACCENT_HEX}}; height: 4px;"></div>
        <div style="padding: 32px 24px; background: #ffffff;">
            <h1 style="font-family: {{BRAND_FONT_CSS}}; color: {{BRAND_HEADING_HEX}}; font-size: 24px; margin: 0 0 16px 0;">' . str_replace( '{first_name}', esc_html( $first_name ), '{{REVIEW_GREETING}}' ) . '</h1>
            <p style="font-size: 16px; line-height: 1.7; margin: 0 0 16px 0;">{{REVIEW_BODY_P1}}</p>
            <p style="font-size: 16px; line-height: 1.7; margin: 0 0 24px 0;">{{REVIEW_BODY_P2}}</p>
            <table style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0; background: {{BRAND_TABLE_BG_HEX}}; border-radius: 8px; overflow: hidden;">
                <tr>
                    <td colspan="3" style="padding: 16px; background: {{BRAND_PRIMARY_HEX}}; color: #ffffff; font-family: {{BRAND_FONT_CSS}}; font-size: 16px;">
                        Your Products
                    </td>
                </tr>
                ' . $product_links . '
            </table>
            <p style="font-size: 15px; line-height: 1.7; color: #4A5568; margin: 0 0 8px 0;">{{REVIEW_BODY_P3}}</p>
            <p style="font-size: 15px; line-height: 1.7; color: #4A5568; margin: 0;">
                With love,<br>
                <strong style="color: {{BRAND_HEADING_HEX}};">{{REVIEW_SIGNATURE}}</strong>
            </p>
        </div>
        <div style="background: #f8f9fa; padding: 20px 24px; text-align: center; border-top: 3px solid {{BRAND_ACCENT_HEX}}; border-radius: 0 0 8px 8px;">
            <p style="margin: 0; font-size: 12px; color: #4A5568;">
                {{BRAND_SHORT}} | <a href="https://{{BRAND_DOMAIN}}" style="color: {{BRAND_PRIMARY_HEX}};">{{BRAND_DOMAIN}}</a><br>
                {{BRAND_ADDRESS}}
            </p>
        </div>
    </div>';

    add_filter( 'wp_mail_content_type', function() { return 'text/html'; } );

    $sent_ok = wp_mail( $email, $subject, $body, [
        'From: {{BRAND_SHORT}} <{{BRAND_FROM_EMAIL}}>',
        'Reply-To: {{BRAND_FROM_EMAIL}}',
    ] );

    remove_filter( 'wp_mail_content_type', function() { return 'text/html'; } );

    if ( $sent_ok ) {
        update_post_meta( $order_id, '_{{BRAND_PREFIX}}_review_sent', current_time( 'mysql' ) );
        error_log( '{{BRAND_SHORT}} Review: Sent review request to ' . $email . ' for order #' . $order_id );
    } else {
        error_log( '{{BRAND_SHORT}} Review: FAILED to send review request to ' . $email . ' for order #' . $order_id );
    }
}
