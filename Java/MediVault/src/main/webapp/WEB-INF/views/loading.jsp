<%-- ── loading.jsp — include vào đầu <body> của mọi trang ──
     Tự động hiện khi trang bắt đầu load, tự ẩn khi DOM ready.
     Không cần truyền tham số gì thêm.
--%>
<style>
/* ── LOADING OVERLAY ────────────────────────────────────── */
#mv-loading{
  position:fixed;inset:0;z-index:9999;
  background:#fff;
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  transition:opacity .35s ease, visibility .35s ease;
}
#mv-loading.hide{opacity:0;visibility:hidden;pointer-events:none}

/* Progress bar trên đầu */
#mv-progress{
  position:fixed;top:0;left:0;height:3px;width:0%;z-index:10000;
  background:linear-gradient(90deg,#1558A8,#3ABDE0,#1558A8);
  background-size:200% 100%;
  animation:mv-shimmer 1.4s linear infinite;
  border-radius:0 2px 2px 0;
  transition:width .3s ease;
  box-shadow:0 0 8px rgba(58,189,224,.6);
}
@keyframes mv-shimmer{
  0%{background-position:200% 0}
  100%{background-position:-200% 0}
}

/* Logo + spinner center */
.mv-load-center{
  display:flex;flex-direction:column;align-items:center;gap:20px;
  animation:mv-fadeIn .3s ease;
}
@keyframes mv-fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}

.mv-load-logo{
  display:flex;align-items:center;gap:10px;
}
.mv-load-icon{
  width:44px;height:44px;
  background:linear-gradient(135deg,#1558A8,#3ABDE0);
  border-radius:12px;
  display:flex;align-items:center;justify-content:center;
  font-size:22px;
  box-shadow:0 4px 16px rgba(21,88,168,.25);
}
.mv-load-name{
  font-family:'Outfit',sans-serif;
  font-size:22px;font-weight:800;
  color:#0F2645;letter-spacing:-.3px;
}
.mv-load-sub{
  font-family:'Outfit',sans-serif;
  font-size:11px;font-weight:600;
  color:#7A90B0;letter-spacing:1px;text-transform:uppercase;
}

/* Spinner */
.mv-spinner{
  width:36px;height:36px;
  border:3px solid #EEF2FF;
  border-top-color:#1558A8;
  border-radius:50%;
  animation:mv-spin .75s linear infinite;
}
@keyframes mv-spin{to{transform:rotate(360deg)}}

.mv-load-text{
  font-family:'Outfit',sans-serif;
  font-size:13px;color:#7A90B0;font-weight:500;
  letter-spacing:.3px;
}

/* Skeleton rows bên dưới */
.mv-skeletons{
  display:flex;flex-direction:column;gap:10px;
  margin-top:8px;width:260px;
}
.mv-sk-row{
  height:10px;border-radius:6px;
  background:linear-gradient(90deg,#F1F5FB 25%,#E2E8F4 50%,#F1F5FB 75%);
  background-size:400% 100%;
  animation:mv-sk-wave 1.5s ease infinite;
}
@keyframes mv-sk-wave{
  0%{background-position:200% 0}
  100%{background-position:-200% 0}
}
.mv-sk-row:nth-child(1){width:100%}
.mv-sk-row:nth-child(2){width:75%}
.mv-sk-row:nth-child(3){width:88%}
</style>

<%-- Progress bar --%>
<div id="mv-progress"></div>

<%-- Overlay --%>
<div id="mv-loading">
  <div class="mv-load-center">
    <div class="mv-load-logo">
      <div class="mv-load-icon">💊</div>
      <div>
        <div class="mv-load-name">medicare</div>
        <div class="mv-load-sub">Đang tải...</div>
      </div>
    </div>
    <div class="mv-spinner"></div>
    <div class="mv-skeletons">
      <div class="mv-sk-row"></div>
      <div class="mv-sk-row"></div>
      <div class="mv-sk-row"></div>
    </div>
    <div class="mv-load-text" id="mv-load-msg">Đang khởi động hệ thống...</div>
  </div>
</div>

<script>
(function() {
  // Progress bar chạy từ 0 → 85% trong lúc load
  var bar = document.getElementById('mv-progress');
  var overlay = document.getElementById('mv-loading');
  var msg = document.getElementById('mv-load-msg');
  var w = 0;

  var msgs = ['Đang tải dữ liệu...', 'Đang khởi tạo giao diện...', 'Sắp xong rồi...'];
  var mi = 0;

  var iv = setInterval(function() {
    if (w < 85) {
      w += (85 - w) * 0.08 + 0.5;
      bar.style.width = w + '%';
      if (w > 30 && mi === 0) { msg.textContent = msgs[1]; mi = 1; }
      if (w > 65 && mi === 1) { msg.textContent = msgs[2]; mi = 2; }
    }
  }, 60);

  function done() {
    clearInterval(iv);
    bar.style.width = '100%';
    setTimeout(function() {
      overlay.classList.add('hide');
      bar.style.opacity = '0';
      setTimeout(function() { bar.remove(); }, 400);
    }, 200);
  }

  // Ẩn khi DOM ready
  if (document.readyState === 'complete') {
    done();
  } else {
    window.addEventListener('load', done);
    // Fallback: tối đa 4s
    setTimeout(done, 4000);
  }

  // Hiện lại loading khi navigate sang trang mới
  document.addEventListener('click', function(e) {
    var a = e.target.closest('a[href]');
    if (!a) return;
    var href = a.href;
    if (!href || href.startsWith('#') || href.startsWith('javascript')
        || a.target === '_blank' || e.ctrlKey || e.metaKey) return;
    // Chỉ hiện lại cho internal links
    if (href.indexOf(window.location.hostname) !== -1 || href.startsWith('/')) {
      overlay.classList.remove('hide');
      overlay.style.opacity = '1';
      bar.style.opacity = '1';
      bar.style.width = '0%';
      w = 0;
      mi = 0;
      msg.textContent = 'Đang tải dữ liệu...';
      iv = setInterval(function() {
        if (w < 85) { w += (85 - w) * 0.08 + 0.5; bar.style.width = w + '%'; }
      }, 60);
    }
  });
})();
</script>
