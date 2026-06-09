/**
 * Taiwan Merch — Post-Purchase Review Request Automation
 * Sends a branded email 14 days after order completion asking customers to review their products.
 * 
 * Hooks: woocommerce_order_status_completed → schedules wp_cron event
 * Cron: twm_send_review_request → sends the email
 */

// Register the custom cron action
add_action('twm_send_review_request', 'twm_handle_review_request', 10, 1);

// Hook into order completion
add_action('woocommerce_order_status_completed', 'twm_schedule_review_request', 20, 1);

/**
 * Schedule a review request email 14 days after order completion
 */
function twm_schedule_review_request($order_id) {
    // Don't schedule if already scheduled
    $scheduled = get_post_meta($order_id, '_twm_review_scheduled', true);
    if ($scheduled) return;
    
    // Schedule for 14 days from now
    $delay = 14 * DAY_IN_SECONDS;
    $timestamp = time() + $delay;
    
    wp_schedule_single_event($timestamp, 'twm_send_review_request', [$order_id]);
    update_post_meta($order_id, '_twm_review_scheduled', current_time('mysql'));
    
    error_log("TWM Review: Scheduled review request for order #{$order_id} at " . date('Y-m-d H:i:s', $timestamp));
}

/**
 * Send the review request email
 */
function twm_handle_review_request($order_id) {
    $order = wc_get_order($order_id);
    if (!$order) return;
    
    // Don't send if already sent
    $sent = get_post_meta($order_id, '_twm_review_sent', true);
    if ($sent) return;
    
    $email = $order->get_billing_email();
    $first_name = $order->get_billing_first_name();
    if (!$email) return;
    
    // Build product review links
    $product_links = '';
    foreach ($order->get_items() as $item) {
        $product = $item->get_product();
        if (!$product) continue;
        
        // Get the parent product for variations
        $parent_id = $product->get_parent_id();
        $review_product = $parent_id ? wc_get_product($parent_id) : $product;
        if (!$review_product) continue;
        
        $name = $review_product->get_name();
        $url = get_permalink($review_product->get_id()) . '#reviews';
        $image = wp_get_attachment_image_url($review_product->get_image_id(), 'thumbnail');
        
        $product_links .= '
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #e2e8f0;">
                ' . ($image ? '<img src="' . esc_url($image) . '" alt="" style="width:60px;height:60px;object-fit:cover;border-radius:6px;vertical-align:middle;margin-right:12px;">' : '') . '
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #e2e8f0; vertical-align: middle;">
                <a href="' . esc_url($url) . '" style="color: #222c88; text-decoration: none; font-weight: bold;">' . esc_html($name) . '</a>
            </td>
            <td style="padding: 12px; border-bottom: 1px solid #e2e8f0; text-align: center; vertical-align: middle;">
                <a href="' . esc_url($url) . '" style="background: #ff181d; color: #ffffff; padding: 8px 16px; border-radius: 4px; text-decoration: none; font-family: Righteous, cursive; font-size: 14px; display: inline-block;">Leave a Review</a>
            </td>
        </tr>';
    }
    
    if (empty($product_links)) return;
    
    // Build the email
    $subject = "How are you loving your Taiwan Merch? We'd love to hear! ⭐";
    
    $body = '
    <div style="max-width: 600px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; color: #2D3748;">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #215387 0%, #222c88 100%); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
            <img src="https://taiwanmerch.co/wp-content/uploads/2025/12/taiwan-merch-logo.png" alt="Taiwan Merch" style="max-width: 180px; height: auto;">
        </div>
        
        <!-- Red accent bar -->
        <div style="background: #ff181d; height: 4px;"></div>
        
        <!-- Body -->
        <div style="padding: 32px 24px; background: #ffffff;">
            <h1 style="font-family: Righteous, cursive; color: #222c88; font-size: 24px; margin: 0 0 16px 0;">Hey ' . esc_html($first_name) . '! 🇹🇼</h1>
            
            <p style="font-size: 16px; line-height: 1.7; margin: 0 0 16px 0;">
                It\'s been a couple of weeks since your Taiwan Merch arrived, and we hope you\'re loving it! Your support means the world to us.
            </p>
            
            <p style="font-size: 16px; line-height: 1.7; margin: 0 0 24px 0;">
                Would you mind taking a moment to share your experience? Your review helps other Taiwan fans discover products they\'ll love too!
            </p>
            
            <!-- Products table -->
            <table style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0; background: #fef3e7; border-radius: 8px; overflow: hidden;">
                <tr>
                    <td colspan="3" style="padding: 16px; background: #215387; color: #ffffff; font-family: Righteous, cursive; font-size: 16px;">
                        Your Products
                    </td>
                </tr>
                ' . $product_links . '
            </table>
            
            <p style="font-size: 15px; line-height: 1.7; color: #4A5568; margin: 0 0 8px 0;">
                It only takes a minute, and we truly appreciate it! 🙏
            </p>
            
            <p style="font-size: 15px; line-height: 1.7; color: #4A5568; margin: 0;">
                With love from Taiwan,<br>
                <strong style="color: #222c88;">The Taiwan Merch Team</strong>
            </p>
        </div>
        
        <!-- Footer -->
        <div style="background: #f8f9fa; padding: 20px 24px; text-align: center; border-top: 3px solid #ff181d; border-radius: 0 0 8px 8px;">
            <p style="margin: 0; font-size: 12px; color: #4A5568;">
                Taiwan Merch Co. | <a href="https://taiwanmerch.co" style="color: #215387;">taiwanmerch.co</a><br>
                680 S Cache Street, Suite 100-8790, Jackson, WY 83001
            </p>
        </div>
    </div>';
    
    // Set HTML content type
    add_filter('wp_mail_content_type', function() { return 'text/html'; });
    
    $sent_ok = wp_mail($email, $subject, $body, [
        'From: Taiwan Merch <hello@taiwanmerch.co>',
        'Reply-To: hello@taiwanmerch.co',
    ]);
    
    // Reset content type
    remove_filter('wp_mail_content_type', function() { return 'text/html'; });
    
    if ($sent_ok) {
        update_post_meta($order_id, '_twm_review_sent', current_time('mysql'));
        error_log("TWM Review: Sent review request to {$email} for order #{$order_id}");
    } else {
        error_log("TWM Review: FAILED to send review request to {$email} for order #{$order_id}");
    }
}

