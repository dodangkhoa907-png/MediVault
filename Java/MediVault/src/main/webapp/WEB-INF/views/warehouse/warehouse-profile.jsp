<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-profile.jsp — Hồ sơ cá nhân (Warehouse Console)

  Thiết kế lại 2026-08-02 (bản độ sâu): hero gradient + ảnh đại diện lớn, ô
  thống kê, lịch sử chấm công tháng này, khu tải ảnh có kéo-thả.

  Số liệu đều là số THẬT lấy từ DB. Cố ý KHÔNG có ô "Số lô đã nhập": bảng Batches
  không lưu người tạo nên con số đó chỉ có thể bịa — muốn có phải thêm cột
  CreatedBy vào Batches trước.

  Yêu cầu từ servlet: staffAcc, staffUid, stDoneOnTime, stDoneLate, stOpenTasks,
  stAttDays, attendance, stMonthLabel.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "profile";
    String msg = request.getParameter("msg");

    Object oOnTime = request.getAttribute("stDoneOnTime");
    Object oLate   = request.getAttribute("stDoneLate");
    Object oOpen   = request.getAttribute("stOpenTasks");
    Object oAtt    = request.getAttribute("stAttDays");
    Object oStreak = request.getAttribute("stStreak");
    Object oLateM  = request.getAttribute("stLateMin");
    int nOnTime = oOnTime != null ? (Integer) oOnTime : 0;
    int nLate   = oLate   != null ? (Integer) oLate   : 0;
    int nOpen   = oOpen   != null ? (Integer) oOpen   : 0;
    int nAtt    = oAtt    != null ? (Integer) oAtt    : 0;
    int nStreak = oStreak != null ? (Integer) oStreak : 0;
    int nLateM  = oLateM  != null ? (Integer) oLateM  : 0;
    int nDone   = nOnTime + nLate;
    int pctOnTime = nDone > 0 ? Math.round(nOnTime * 100f / nDone) : 0;

    /* ── Thành tích ──────────────────────────────────────────────────────────
       Mỗi huy hiệu là một NGƯỠNG đặt trên một số liệu có thật trong DB, không
       phải nhãn trang trí. Chưa đạt thì vẫn hiện (xám + thanh tiến độ) để biết
       còn thiếu bao nhiêu — giấu đi thì thành tích không dẫn hướng được gì.
       Mảng: {tên, mô tả, icon, màu, giá trị hiện tại, ngưỡng} */
    Object[][] achievements = {
        {"Tay nghề vững",   "Hoàn thành 10 nhiệm vụ",              "ic-check-circle", "g-teal",   nDone,   10},
        {"Trụ cột kho",     "Hoàn thành 50 nhiệm vụ",              "ic-shield-check", "g-violet", nDone,   50},
        {"Chuỗi đúng hạn",  "5 việc liên tiếp không trễ hạn",      "ic-target",       "g-amber",  nStreak, 5},
        {"Đúng giờ cả tháng","Không phút đi trễ nào trong tháng",  "ic-clock",        "g-green",  (nAtt > 0 && nLateM == 0) ? 1 : 0, 1},
        {"Chuyên cần",      "Đủ 20 ngày công trong tháng",         "ic-calendar",     "g-teal",   nAtt,    20}
    };
%>
<%!
    /** Phần trăm tiến độ tới ngưỡng, kẹp trong [0,100]. */
    private int pct(int cur, int goal) {
        if (goal <= 0) return 100;
        return Math.min(100, Math.round(cur * 100f / goal));
    }
%>
<%

    boolean hasAvatar = acc.getFaceEnrollmentPath() != null && !acc.getFaceEnrollmentPath().isEmpty();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Hồ sơ cá nhân — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}
.wh-shell{max-width:1240px}

/* Hero hồ sơ — ảnh đại diện nằm GỌN TRONG hero.
   Bản trước cho ảnh thò xuống dưới mép hero bằng margin âm; nhưng .wh-hero có
   `overflow:hidden` (để cắt 2 khối sáng trang trí) nên nửa dưới ảnh bị cắt cụt.
   Bỏ luôn trò chồng lớp: một khối gọn, không phải bù margin cho trang, và không
   phụ thuộc vào việc hero có cắt tràn hay không. */
.p-hero-in{display:flex;align-items:center;gap:22px;flex-wrap:wrap}
.p-av{position:relative;flex:none}
.p-av .img,.p-av .ph{width:104px;height:104px;border-radius:30px;display:block;
  border:3px solid rgba(255,255,255,.30);box-shadow:0 10px 26px -10px rgba(0,0,0,.5)}
.p-av .img{object-fit:cover}
.p-av .ph{display:flex;align-items:center;justify-content:center;font-size:40px;font-weight:800;color:#fff;
  background:linear-gradient(160deg,#2DD4BF,#0F766E)}
.p-av .badge{position:absolute;right:-5px;bottom:-5px;width:34px;height:34px;border-radius:50%;
  background:linear-gradient(160deg,#34D399,#059669);border:3px solid #0B4F4A;
  display:flex;align-items:center;justify-content:center;color:#fff}
.p-av .badge svg{width:15px;height:15px}
.p-meta{flex:1;min-width:220px}
.p-meta h1{font-size:clamp(23px,2.2vw,30px);font-weight:800;letter-spacing:-.7px;line-height:1.15}
.p-meta .who{display:flex;align-items:center;gap:9px;flex-wrap:wrap;margin-top:10px;
  font-size:13.5px;color:rgba(255,255,255,.74)}
.p-meta .who .dot{width:4px;height:4px;border-radius:50%;background:rgba(255,255,255,.4)}

/* Kéo–thả ảnh.
   `display:block` là BẮT BUỘC: .drop là thẻ <label>, mà label mặc định là inline
   — thiếu dòng này thì viền đứt nét quấn quanh từng đoạn chữ rời rạc và nội dung
   tràn ra ngoài card, đúng như ảnh chụp báo lỗi. */
.drop{display:block;border:2px dashed var(--border);border-radius:18px;padding:26px 20px;
  text-align:center;cursor:pointer;
  background:linear-gradient(180deg,#FBFCFE,#F6F9FC);transition:all var(--wh-t)}
.drop:hover{border-color:var(--main);background:#F0FDFA}
.drop.over{border-color:var(--main);background:#ECFDF5;transform:scale(1.01)}
.drop .ic{width:52px;height:52px;border-radius:18px;margin:0 auto 12px;display:flex;align-items:center;justify-content:center;
  background:linear-gradient(160deg,#CCFBF1,#A7F3E4);color:var(--deep)}
.drop .ic svg{width:24px;height:24px}
.drop .t{font-size:14px;font-weight:750;color:var(--ink)}
.drop .s{font-size:12.5px;color:var(--muted);margin-top:5px;line-height:1.5}
.drop input[type=file]{display:none}
.pick{display:none;align-items:center;gap:13px;margin-top:16px;padding:13px 15px;border-radius:14px;
  background:#F0FDFA;border:1px solid #99F6E4}
.pick.on{display:flex}
.pick .nm{flex:1;min-width:0;font-size:13px;font-weight:700;color:var(--deep);
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.pick img{width:52px;height:52px;border-radius:14px;object-fit:cover;flex:none}

/* Chấm công */
.att-row{display:flex;align-items:center;gap:13px;padding:13px 22px;border-bottom:1px solid var(--line)}
.att-row:last-child{border-bottom:none}
.att-row .bd{flex:1;min-width:0}
.att-row .t1{font-size:13.5px;font-weight:750;color:var(--ink)}
.att-row .t2{font-size:11.5px;color:var(--muted);margin-top:2px}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="<%= ctx %>/js/csrf.js"></script>
<script src="<%= ctx %>/js/warehouse-ui.js" defer></script>
</head>
<body class="wh">
<%@ include file="/WEB-INF/views/icons.jsp" %>
<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Cá nhân</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <!-- ══ HERO ══ -->
    <div class="wh-hero">
      <div class="p-hero-in">
        <div class="p-av">
          <% if (hasAvatar) { %>
            <img class="img" src="<%= ctx %>/<%= acc.getFaceEnrollmentPath() %>" alt="Ảnh đại diện của <%= fullName %>">
          <% } else { %>
            <div class="ph" aria-hidden="true"><%= initials %></div>
          <% } %>
          <span class="badge" title="Tài khoản đang hoạt động"><svg><use href="#ic-check"/></svg></span>
        </div>
        <div class="p-meta">
          <h1><%= fullName %></h1>
          <div class="who">
            <span class="wh-chip on" style="padding:6px 13px;font-size:12px"><span class="d"></span> Thủ kho</span>
            <span class="dot"></span>
            <span><%= acc.getUsername() %></span>
            <% if (acc.getEmail() != null && !acc.getEmail().isEmpty()) { %>
              <span class="dot"></span><span><%= acc.getEmail() %></span>
            <% } %>
          </div>
        </div>
      </div>
    </div>

    <% if ("success".equals(msg)) { %>
      <div class="wh-note ok" role="status">
        <svg><use href="#ic-check-circle"/></svg>
        <span>Đã cập nhật ảnh đại diện.</span>
      </div>
    <% } else if ("error".equals(msg)) { %>
      <div class="wh-note danger" role="alert">
        <svg><use href="#ic-alert"/></svg>
        <span>Không lưu được ảnh. Kiểm tra định dạng (PNG/JPEG, tối đa 5MB) rồi thử lại.</span>
      </div>
    <% } %>

    <!-- ══ Thống kê ══ -->
    <div class="wh-tiles" style="margin-bottom:24px">
      <div class="wh-tile">
        <div class="ic ok"><svg><use href="#ic-check-circle"/></svg></div>
        <div class="n"><%= nDone %></div>
        <div class="l">Nhiệm vụ đã hoàn thành</div>
        <div class="s"><%= nOnTime %> đúng hạn · <%= nLate %> trễ hạn</div>
      </div>
      <div class="wh-tile">
        <div class="ic violet"><svg><use href="#ic-target"/></svg></div>
        <div class="n"><%= pctOnTime %>%</div>
        <div class="l">Tỷ lệ đúng hạn</div>
        <div class="s"><%= nDone == 0 ? "Chưa có nhiệm vụ nào hoàn thành" : "Trên tổng " + nDone + " việc đã xong" %></div>
      </div>
      <div class="wh-tile">
        <div class="ic warn"><svg><use href="#ic-clipboard"/></svg></div>
        <div class="n"><%= nOpen %></div>
        <div class="l">Việc đang chờ</div>
        <div class="s"><%= nOpen == 0 ? "Không còn việc tồn" : "Xem ở Nhiệm vụ & SOP" %></div>
      </div>
      <div class="wh-tile">
        <div class="ic info"><svg><use href="#ic-calendar"/></svg></div>
        <div class="n"><%= nAtt %></div>
        <div class="l">Ngày công tháng này</div>
        <div class="s">${stMonthLabel}</div>
      </div>
    </div>

    <!-- ══ Thành tích ══ -->
    <div class="wh-card">
      <div class="wh-card-head">
        <div class="wh-ic warn"><svg><use href="#ic-flag"/></svg></div>
        <div class="tt">
          <h2>Thành tích</h2>
          <div class="desc">Mốc đạt được trên số liệu thật của bạn — chưa đạt vẫn hiện kèm tiến độ.</div>
        </div>
        <div class="sp">
          <span class="wh-badge <%= java.util.Arrays.stream(achievements).filter(a -> (Integer) a[4] >= (Integer) a[5]).count() > 0 ? "ok" : "mute" %>">
            <%= java.util.Arrays.stream(achievements).filter(a -> (Integer) a[4] >= (Integer) a[5]).count() %>/<%= achievements.length %> đã đạt
          </span>
        </div>
      </div>
      <div class="wh-card-body">
        <div class="wh-ach">
          <% for (Object[] a : achievements) {
               String name = (String) a[0], desc = (String) a[1], icon = (String) a[2], tone = (String) a[3];
               int cur = (Integer) a[4], goal = (Integer) a[5];
               boolean got = cur >= goal;
               int p = pct(cur, goal);
          %>
            <div class="wh-ach-i <%= got ? "got " + tone : "" %>">
              <div class="ic"><svg><use href="#<%= icon %>"/></svg></div>
              <div class="t"><%= name %></div>
              <div class="d"><%= got ? desc : desc + " — còn " + (goal - cur) %></div>
              <div class="bar"><i style="width:<%= p %>%"></i></div>
            </div>
          <% } %>
        </div>
      </div>
    </div>

    <!-- ══ Lưới lệch 5/7 ══ -->
    <div class="wh-g12">

      <div class="c5">
        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic"><svg><use href="#ic-image"/></svg></div>
            <div class="tt">
              <h2>Ảnh đại diện</h2>
              <div class="desc">Dùng cho điểm danh khuôn mặt và nhật ký thao tác.</div>
            </div>
          </div>
          <div class="wh-card-body">
            <form action="<%= ctx %>/warehouse-profile" method="POST"
                  enctype="multipart/form-data" id="avForm">
              <label class="drop" id="drop" for="avatarFile">
                <div class="ic"><svg><use href="#ic-image"/></svg></div>
                <div class="t">Kéo ảnh vào đây hoặc bấm để chọn</div>
                <div class="s">PNG hoặc JPEG, tối đa 5MB.<br>Nên dùng ảnh chân dung rõ mặt để điểm danh nhận diện tốt hơn.</div>
                <input type="file" id="avatarFile" name="avatar" accept="image/png, image/jpeg" required>
              </label>

              <div class="pick" id="pick">
                <img id="pickImg" alt="">
                <span class="nm" id="pickName">—</span>
                <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" id="pickClear" aria-label="Bỏ ảnh đã chọn">
                  <svg><use href="#ic-x"/></svg>
                </button>
              </div>

              <button type="submit" class="wh-btn wh-btn-primary" id="avSave" style="margin-top:18px;width:100%;justify-content:center" disabled>
                <svg><use href="#ic-check"/></svg> Lưu ảnh đại diện
              </button>
            </form>
          </div>
        </div>
      </div>

      <div class="c7">
        <div class="wh-card" style="margin-bottom:24px">
          <div class="wh-card-head">
            <div class="wh-ic jade"><svg><use href="#ic-user"/></svg></div>
            <div class="tt">
              <h2>Thông tin tài khoản</h2>
              <div class="desc">Do Admin quản lý — không sửa được từ portal Kho.</div>
            </div>
          </div>
          <div class="wh-card-body" style="padding-top:6px;padding-bottom:10px">
            <div class="wh-rows">
              <div class="r"><span class="k"><svg><use href="#ic-user"/></svg> Họ và tên</span><span class="v"><%= fullName %></span></div>
              <div class="r"><span class="k"><svg><use href="#ic-tag"/></svg> Tài khoản</span><span class="v"><%= acc.getUsername() %></span></div>
              <div class="r"><span class="k"><svg><use href="#ic-file-text"/></svg> Email</span>
                <span class="v"><%= acc.getEmail() != null && !acc.getEmail().isEmpty() ? acc.getEmail() : "—" %></span></div>
              <div class="r"><span class="k"><svg><use href="#ic-shield-check"/></svg> Vai trò</span>
                <span class="v"><span class="wh-badge ok">Thủ kho</span></span></div>
            </div>
          </div>
        </div>

        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic info"><svg><use href="#ic-calendar"/></svg></div>
            <div class="tt">
              <h2>Chấm công <small>${stMonthLabel}</small></h2>
              <div class="desc">Các ca đã điểm danh trong tháng.</div>
            </div>
            <div class="sp">
              <a class="wh-btn" href="<%= ctx %>/staff-checkin?uid=<%= uid %>">
                <svg><use href="#ic-clock"/></svg> Điểm danh
              </a>
            </div>
          </div>
          <c:choose>
            <c:when test="${empty attendance}">
              <div class="wh-empty">
                <div class="art"><svg style="width:26px;height:26px"><use href="#ic-calendar"/></svg></div>
                <div class="t">Chưa có ca nào trong tháng</div>
                <div class="d">Điểm danh vào ca để hệ thống ghi nhận ngày công.</div>
              </div>
            </c:when>
            <c:otherwise>
              <div style="max-height:340px;overflow-y:auto">
                <c:forEach var="a" items="${attendance}">
                  <div class="att-row">
                    <span class="wh-ic sm ${a.statusBadgeClass == 'danger' ? 'danger' : (a.statusBadgeClass == 'warn' ? 'warn' : 'ok')}">
                      <svg><use href="#ic-clock"/></svg>
                    </span>
                    <span class="bd">
                      <span class="t1">${a.checkInTime}</span>
                      <span class="t2">
                        <c:choose>
                          <c:when test="${not empty a.checkOutTime}">Ra ca: ${a.checkOutTime}</c:when>
                          <c:otherwise>Chưa kết thúc ca</c:otherwise>
                        </c:choose>
                        <c:if test="${a.lateMinutes > 0}"> · trễ ${a.lateMinutes} phút</c:if>
                      </span>
                    </span>
                    <span class="wh-badge ${a.statusBadgeClass == 'danger' ? 'out' : (a.statusBadgeClass == 'warn' ? 'low' : 'ok')}">${a.statusLabel}</span>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

    </div>
  </div>
</div>

<script>
(function () {
  'use strict';
  var input = document.getElementById('avatarFile');
  var drop  = document.getElementById('drop');
  var pick  = document.getElementById('pick');
  var save  = document.getElementById('avSave');
  if (!input) return;

  var MAX = 5 * 1024 * 1024;

  function accept(file) {
    if (!file) return;
    if (!/^image\/(png|jpeg)$/.test(file.type)) {
      alert('Chỉ nhận ảnh PNG hoặc JPEG.');
      return;
    }
    if (file.size > MAX) {
      alert('Ảnh nặng quá 5MB. Chọn ảnh nhỏ hơn.');
      return;
    }
    document.getElementById('pickName').textContent =
      file.name + ' · ' + (file.size / 1024 / 1024).toFixed(2) + ' MB';
    var img = document.getElementById('pickImg');
    if (img.src) URL.revokeObjectURL(img.src);
    img.src = URL.createObjectURL(file);
    pick.classList.add('on');
    save.disabled = false;
  }

  input.addEventListener('change', function () { accept(input.files[0]); });

  ['dragenter', 'dragover'].forEach(function (ev) {
    drop.addEventListener(ev, function (e) { e.preventDefault(); drop.classList.add('over'); });
  });
  ['dragleave', 'drop'].forEach(function (ev) {
    drop.addEventListener(ev, function (e) { e.preventDefault(); drop.classList.remove('over'); });
  });
  drop.addEventListener('drop', function (e) {
    var f = e.dataTransfer.files && e.dataTransfer.files[0];
    if (!f) return;
    // Gán lại vào input để form vẫn submit theo đúng luồng multipart cũ
    var dt = new DataTransfer();
    dt.items.add(f);
    input.files = dt.files;
    accept(f);
  });

  document.getElementById('pickClear').addEventListener('click', function () {
    input.value = '';
    pick.classList.remove('on');
    save.disabled = true;
  });
})();
</script>
</body>
</html>
