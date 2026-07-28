/* ============================================================================
   csrf.js — Tự động đính token CSRF vào MỌI yêu cầu thay đổi dữ liệu gửi đi từ
   trang này (POST/PUT/PATCH/DELETE), để không phải sửa tay từng lời gọi fetch /
   XHR / form nằm rải rác khắp hệ thống.

   Server (AppFilter) chặn mọi POST không kèm token hợp lệ. Token lấy từ thẻ:
       <meta name="csrf-token" content="${csrfToken}">

   Ba đường đính token, tuỳ loại request:
     • fetch / XHR            → header  X-CSRF-Token
     • form thường            → input hidden _csrf (đã render sẵn trong JSP;
                                đoạn dưới chỉ là lưới an toàn nếu form nào sót)
     • form multipart (upload)→ query string ?_csrf=... vì field trong body thì
                                Filter KHÔNG đọc được (xem CsrfUtil.isValid)
   ========================================================================== */
(function () {
  var meta  = document.querySelector('meta[name="csrf-token"]');
  var TOKEN = meta ? meta.getAttribute('content') : '';
  if (!TOKEN) return;   // trang không có token (vd trang lỗi) → không làm gì

  var HEADER = 'X-CSRF-Token';
  var UNSAFE = /^(POST|PUT|PATCH|DELETE)$/i;

  function sameOrigin(url) {
    try { return new URL(url, location.href).origin === location.origin; }
    catch (e) { return true; }   // URL tương đối → chắc chắn cùng origin
  }

  // ── 1. fetch ──────────────────────────────────────────────────────────────
  if (window.fetch) {
    var origFetch = window.fetch;
    window.fetch = function (input, init) {
      init = init || {};
      var isReqObj = (typeof input === 'object' && input !== null);
      var url      = isReqObj ? (input.url || '') : String(input || '');
      var method   = init.method || (isReqObj ? input.method : '') || 'GET';

      if (UNSAFE.test(method) && sameOrigin(url)) {
        var h = new Headers(init.headers || (isReqObj ? input.headers : null) || {});
        if (!h.has(HEADER)) h.set(HEADER, TOKEN);
        init = Object.assign({}, init, { headers: h });
      }
      return origFetch.call(this, input, init);
    };
  }

  // ── 2. XMLHttpRequest ─────────────────────────────────────────────────────
  var origOpen = XMLHttpRequest.prototype.open;
  var origSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.__csrfUnsafe = UNSAFE.test(method || '') && sameOrigin(url || '');
    return origOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function () {
    if (this.__csrfUnsafe) {
      try { this.setRequestHeader(HEADER, TOKEN); } catch (e) { /* header đã set */ }
    }
    return origSend.apply(this, arguments);
  };

  // ── 3. Form HTML — lưới an toàn lúc submit ────────────────────────────────
  // Bắt ở pha capture để chạy TRƯỚC mọi handler submit khác của trang.
  document.addEventListener('submit', function (e) {
    var form = e.target;
    if (!form || form.tagName !== 'FORM') return;
    if (!UNSAFE.test(form.method || 'GET')) return;   // form GET không cần token

    var enc = (form.enctype || '').toLowerCase();
    if (enc.indexOf('multipart') === 0) {
      // Field multipart nằm trong body → Filter không đọc được. Đính vào query string.
      var act = form.getAttribute('action') || '';
      if (act.indexOf('_csrf=') === -1) {
        form.setAttribute('action',
          act + (act.indexOf('?') === -1 ? '?' : '&') + '_csrf=' + encodeURIComponent(TOKEN));
      }
      return;
    }

    if (!form.querySelector('input[name="_csrf"]')) {
      var i = document.createElement('input');
      i.type  = 'hidden';
      i.name  = '_csrf';
      i.value = TOKEN;
      form.appendChild(i);
    }
  }, true);
})();
