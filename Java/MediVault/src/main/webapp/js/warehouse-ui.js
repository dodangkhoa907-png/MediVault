/* ============================================================================
   warehouse-ui.js — Hành vi dùng chung của lớp design system `wh-*`.
   Nạp SAU warehouse-portal.css, ở cuối <body> hoặc kèm `defer`.

   Chỉ chứa những thứ CSS không tự làm được, và tự kích hoạt theo class có mặt
   trên trang — trang nào không dùng component đó thì đoạn tương ứng no-op.
   ========================================================================= */
(function () {
  'use strict';

  /* ── 1. Bảng: chỉ bật cuộn ngang khi thật sự không vừa khung ──────────────
     Sidebar là position:fixed, nên nếu để cả TRANG cuộn ngang thì nội dung
     trượt xuống dưới sidebar và che mất cột đầu. Phải nhốt cuộn ngang vào đúng
     khung bảng.

     Nhưng không thể đặt sẵn `overflow-x:auto`: bất kỳ tổ tiên nào có overflow
     khác `visible` đều trở thành scrollport của `position:sticky` bên trong,
     làm header bảng "dính" vào một hộp không bao giờ cuộn — tức mất sticky mà
     không báo lỗi gì. Vì vậy class `needs-x` chỉ được gắn đúng lúc cần, và
     CSS sẽ tự hạ thead về `position:static` trong trạng thái đó. */
  function fitTables(root) {
    (root || document).querySelectorAll('.wh-tablescroll').forEach(function (pane) {
      if (pane.dataset.fit === 'manual') return;   // trang tự quản lý (vd. tồn kho)
      var widest = 0;
      pane.querySelectorAll('table').forEach(function (t) {
        if (t.offsetParent === null && t.hidden) return;
        widest = Math.max(widest, t.offsetWidth);
      });
      pane.classList.toggle('needs-x', widest > pane.clientWidth + 1);
    });
  }

  /* ── 2. Toolbar dính: đo chiều cao để header bảng dính ngay bên dưới ──────
     Toolbar co giãn và xuống dòng theo bề ngang nên không hard-code được. */
  function measureToolbars() {
    var tb = document.querySelector('.wh-toolbar');
    if (!tb) return;
    document.documentElement.style.setProperty('--wh-toolbar-h', tb.offsetHeight + 'px');
  }

  /* ── 3. Đổ bóng khi toolbar đã dính — tín hiệu "còn nội dung phía trên" ─── */
  function watchStuck() {
    var tb = document.querySelector('.wh-toolbar');
    if (!tb) return;
    var ticking = false;
    function onScroll() {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(function () {
        tb.classList.toggle('is-stuck', tb.getBoundingClientRect().top <= 67);
        ticking = false;
      });
    }
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* ── 4. Nút "Làm mới" — quay icon trong lúc chờ tải lại ───────────────── */
  function wireRefresh() {
    document.querySelectorAll('[data-wh-refresh]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        btn.classList.add('is-busy');
        btn.disabled = true;
        location.reload();
      });
    });
  }

  /* ── 5. Toast — phản hồi cho thao tác chạy nền (kéo-thả, lưu nhanh) ────── */
  function toast(msg, ok) {
    var wrap = document.querySelector('.wh-toast-wrap');
    if (!wrap) {
      wrap = document.createElement('div');
      wrap.className = 'wh-toast-wrap';
      wrap.setAttribute('role', 'status');
      wrap.setAttribute('aria-live', 'polite');
      document.body.appendChild(wrap);
    }
    var el = document.createElement('div');
    el.className = 'wh-toast ' + (ok === false ? 'err' : 'ok');
    el.innerHTML = '<svg><use href="#' + (ok === false ? 'ic-alert' : 'ic-check-circle') + '"/></svg><span></span>';
    el.querySelector('span').textContent = msg;
    wrap.appendChild(el);
    setTimeout(function () {
      el.classList.add('out');
      setTimeout(function () { el.remove(); }, 220);
    }, ok === false ? 4200 : 2600);
  }

  /* ── 6. Đếm số cho các ô thống kê ────────────────────────────────────────
     Chỉ chạy với số nguyên ≤ 4 chữ số và chỉ MỘT lần lúc vào trang. Số lớn
     đếm lâu thành khó chịu, còn số có đơn vị (%, đ) thì đọc sai định dạng. */
  function countUp() {
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    document.querySelectorAll('.wh-kpi .num, .wh-tile .n').forEach(function (el) {
      var raw = el.textContent.trim();
      if (!/^\d{1,4}$/.test(raw)) return;
      var target = +raw;
      if (target < 3) return;               // 0–2 thì nhảy số trông giật, để yên
      var t0 = performance.now(), dur = 620;
      el.textContent = '0';
      (function step(now) {
        var p = Math.min(1, (now - t0) / dur);
        var eased = 1 - Math.pow(1 - p, 3);
        el.textContent = Math.round(target * eased);
        if (p < 1) requestAnimationFrame(step);
        else el.textContent = target;
      })(t0);
    });
  }

  function boot() {
    measureToolbars();
    fitTables();
    watchStuck();
    wireRefresh();
    countUp();

    var tb = document.querySelector('.wh-toolbar');
    if (window.ResizeObserver) {
      var ro = new ResizeObserver(function () { measureToolbars(); fitTables(); });
      if (tb) ro.observe(tb);
      document.querySelectorAll('.wh-tablescroll').forEach(function (p) { ro.observe(p); });
    } else {
      window.addEventListener('resize', function () { measureToolbars(); fitTables(); });
    }
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

  // Trang nào render lại dòng bằng JS (lọc/phân trang) thì gọi lại sau khi render.
  window.whFitTables = fitTables;
  window.whToast = toast;
})();
