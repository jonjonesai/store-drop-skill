// TWM: Review Image Upload Handler v5
// Self-contained: injects upload widget HTML + file input + JS into review form
// No dependency on Fluent Forms custom_html (which sanitizes <input> tags)

add_action("wp_ajax_twm_get_upload_nonce", "twm_get_upload_nonce");
add_action("wp_ajax_nopriv_twm_get_upload_nonce", "twm_get_upload_nonce");
function twm_get_upload_nonce() {
    wp_send_json_success(["nonce" => wp_create_nonce("twm_review_upload")]);
}

add_action("wp_ajax_twm_review_upload", "twm_handle_review_upload");
add_action("wp_ajax_nopriv_twm_review_upload", "twm_handle_review_upload");
function twm_handle_review_upload() {
    if (!isset($_POST["twm_upload_nonce"]) || !wp_verify_nonce(sanitize_text_field(wp_unslash($_POST["twm_upload_nonce"])), "twm_review_upload")) {
        wp_send_json_error(["message" => "Security check failed. Please refresh and try again."], 403);
    }
    if (empty($_FILES["review_image"])) {
        wp_send_json_error(["message" => "No file uploaded"], 400);
    }
    $file = $_FILES["review_image"];
    if (!in_array($file["type"], ["image/jpeg","image/png","image/webp"])) {
        wp_send_json_error(["message" => "Only JPG, PNG, and WebP allowed"], 400);
    }
    if ($file["size"] > 2 * 1024 * 1024) {
        wp_send_json_error(["message" => "File too large. Max 2MB."], 400);
    }
    $ip = sanitize_text_field($_SERVER["REMOTE_ADDR"]);
    $tk = "twm_upload_" . md5($ip);
    $count = (int) get_transient($tk);
    if ($count >= 10) {
        wp_send_json_error(["message" => "Too many uploads. Try again later."], 429);
    }
    set_transient($tk, $count + 1, HOUR_IN_SECONDS);

    require_once ABSPATH . "wp-admin/includes/image.php";
    require_once ABSPATH . "wp-admin/includes/file.php";
    require_once ABSPATH . "wp-admin/includes/media.php";
    $id = media_handle_upload("review_image", 0);
    if (is_wp_error($id)) {
        wp_send_json_error(["message" => $id->get_error_message()], 500);
    }
    wp_send_json_success([
        "url" => wp_get_attachment_url($id),
        "thumb" => wp_get_attachment_image_url($id, "thumbnail"),
        "id" => $id
    ]);
}

add_action("wp_footer", function() {
    if (!function_exists("is_product") || !is_product()) return;
    $ajax_url = admin_url("admin-ajax.php");
    ?>
    <script>
    (function(){
        var ajaxUrl="<?php echo esc_js($ajax_url); ?>";
        var nonce="";

        // Fetch nonce right away
        var nx=new XMLHttpRequest();
        nx.open("POST",ajaxUrl);
        nx.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
        nx.onload=function(){try{var r=JSON.parse(nx.responseText);if(r.success)nonce=r.data.nonce;}catch(e){}};
        nx.send("action=twm_get_upload_nonce");

        function tryInject(){
            // Find the submit button wrapper in fluentform 5
            var btn=document.querySelector(".ff_btn_style, .ff-btn-submit");
            if(!btn)return;
            var wrap=btn.closest(".ff_submit_btn_wrapper, .ff-el-group");
            if(!wrap||document.getElementById("twm-uploader"))return;

            // Build upload widget
            var w=document.createElement("div");
            w.id="twm-uploader";
            w.style.cssText="margin-bottom:15px;";
            w.innerHTML='<label style="display:block;font-weight:600;margin-bottom:6px;color:#1b2733;font-size:14px">Product Photos <span style="color:#8c8c8c;font-weight:400;font-size:13px">(optional)</span></label>'
                +'<p style="color:#8c8c8c;font-size:12px;margin:0 0 8px">Up to 3 photos \u2014 JPG, PNG, or WebP, max 2MB each</p>'
                +'<div id="twm-drop" style="border:2px dashed #ccc;border-radius:8px;padding:20px;text-align:center;cursor:pointer;background:#fafafa">'
                +'<svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#888" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>'
                +'<p style="margin:8px 0 0;color:#666;font-size:14px">Click or drag photos here</p></div>'
                +'<div id="twm-previews" style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap"></div>'
                +'<div id="twm-status" style="margin-top:6px;font-size:13px"></div>';
            wrap.parentNode.insertBefore(w, wrap);

            var drop=document.getElementById("twm-drop"),
                previews=document.getElementById("twm-previews"),
                status=document.getElementById("twm-status"),
                fileInput=document.createElement("input"),
                urls=[],max=3;

            fileInput.type="file";
            fileInput.accept="image/jpeg,image/png,image/webp";
            fileInput.multiple=true;
            fileInput.style.display="none";
            document.body.appendChild(fileInput);

            drop.addEventListener("click",function(){
                if(urls.length>=max){status.innerHTML='<span style="color:#e53e3e">Max '+max+' photos</span>';return;}
                if(!nonce){status.innerHTML='<span style="color:#215387">Loading, try again...</span>';return;}
                fileInput.click();
            });
            drop.addEventListener("dragover",function(e){e.preventDefault();drop.style.borderColor="#215387";drop.style.background="#f0f4f8";});
            drop.addEventListener("dragleave",function(){drop.style.borderColor="#ccc";drop.style.background="#fafafa";});
            drop.addEventListener("drop",function(e){
                e.preventDefault();drop.style.borderColor="#ccc";drop.style.background="#fafafa";
                if(!nonce){status.innerHTML='<span style="color:#e53e3e">Loading, try again...</span>';return;}
                handleFiles(e.dataTransfer.files);
            });
            fileInput.addEventListener("change",function(){handleFiles(fileInput.files);fileInput.value="";});

            function handleFiles(files){
                for(var i=0;i<files.length&&urls.length<max;i++) upload(files[i]);
            }
            function upload(file){
                if(file.size>2*1024*1024){status.innerHTML='<span style="color:#e53e3e">'+file.name+' too large (2MB max)</span>';return;}
                var fd=new FormData();
                fd.append("action","twm_review_upload");
                fd.append("twm_upload_nonce",nonce);
                fd.append("review_image",file);
                var box=document.createElement("div");
                box.style.cssText="position:relative;width:80px;height:80px;border-radius:6px;overflow:hidden;border:1px solid #ddd;";
                box.innerHTML='<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:#f0f0f0;font-size:11px;color:#888">Uploading\u2026</div>';
                previews.appendChild(box);
                status.innerHTML='<span style="color:#215387">Uploading\u2026</span>';
                var x=new XMLHttpRequest();
                x.open("POST",ajaxUrl);
                x.onload=function(){
                    try{var r=JSON.parse(x.responseText);}catch(e){box.remove();status.innerHTML='<span style="color:#e53e3e">Upload failed</span>';return;}
                    if(r.success){
                        urls.push(r.data.url);
                        box.innerHTML='<img src="'+r.data.thumb+'" style="width:100%;height:100%;object-fit:cover">'
                            +'<a href="#" style="position:absolute;top:2px;right:2px;background:rgba(0,0,0,.6);color:#fff;width:20px;height:20px;border-radius:50%;display:flex;align-items:center;justify-content:center;text-decoration:none;font-size:14px;line-height:1" data-i="'+(urls.length-1)+'">\u00d7</a>';
                        box.querySelector("a").onclick=function(e){e.preventDefault();urls.splice(+this.dataset.i,1);box.remove();sync();reindex();status.innerHTML=urls.length?'<span style="color:#38a169">'+urls.length+'/'+max+'</span>':"";};
                        sync();
                        status.innerHTML='<span style="color:#38a169">'+urls.length+'/'+max+' uploaded</span>';
                    }else{
                        box.remove();
                        var msg=(r.data&&r.data.message)||"Upload failed";
                        if(msg.indexOf("Security")>-1){nonce="";msg+=". Refresh the page.";}
                        status.innerHTML='<span style="color:#e53e3e">'+msg+'</span>';
                    }
                };
                x.onerror=function(){box.remove();status.innerHTML='<span style="color:#e53e3e">Connection error</span>';};
                x.send(fd);
            }
            function sync(){var h=document.querySelector('input[name="product-photos"]');if(h)h.value=urls.join(",");}
            function reindex(){previews.querySelectorAll("a[data-i]").forEach(function(a,i){a.dataset.i=i;});}
        }

        // Keep trying until form appears (it's in a popup)
        var iv=setInterval(function(){if(document.getElementById("twm-uploader")){clearInterval(iv);return;}tryInject();},500);
        tryInject();
    })();
    </script>
    <?php
}, 99);

