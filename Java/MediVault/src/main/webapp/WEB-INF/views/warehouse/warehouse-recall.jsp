<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    Object foundBatch = request.getAttribute("foundBatch");
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "recall";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Thu hồi lô khẩn cấp — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=3">
<style>
a{text-decoration:none;color:inherit}

.topbar{background:linear-gradient(120deg,#3730A3 0%,#4338CA 62%,#0F766E 116%);color:#fff;
  padding:13px 28px;display:flex;align-items:center;justify-content:space-between;
  backdrop-filter:blur(14px) saturate(160%);-webkit-backdrop-filter:blur(14px) saturate(160%);
  box-shadow:0 4px 18px -6px rgba(67,56,202,.4);position:sticky;top:0;z-index:10}
.tb-brand{display:flex;align-items:center;gap:12px}
.tb-icon{width:38px;height:38px;border-radius:11px;display:grid;place-items:center;font-size:19px;
  background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.2)}
.tb-name{font-size:15px;font-weight:800}
.tb-tag{font-size:10px;color:rgba(255,255,255,.6);letter-spacing:1.5px;text-transform:uppercase}
.tb-right{display:flex;align-items:center;gap:14px;font-size:13px}
.tb-back{color:#fff;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.22);
  padding:8px 13px;border-radius:10px;font-weight:700;transition:.15s}
.tb-back:hover{background:rgba(255,255,255,.22)}
.tb-user{font-weight:700}

.wrap{max-width:1100px;margin:0 auto;padding:28px 28px 60px}
.head{margin-bottom:22px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px;display:flex;align-items:center;gap:10px}
.head h1 span{color:var(--danger)}
.head p{color:var(--muted);font-size:14px;margin-top:4px}

.banner{border-radius:14px;padding:14px 18px;margin-bottom:20px;font-weight:700;font-size:14px;
  display:flex;align-items:center;gap:10px}
.banner.ok{background:var(--okbg);color:var(--ok);border:1px solid #A7F3D0}
.banner.err{background:var(--dangerbg);color:var(--danger);border:1.5px solid #FCA5B1}

.card{background:#fff;border:1px solid #E7E8F1;border-radius:16px;overflow:hidden;margin-bottom:22px;box-shadow:0 1px 2px rgba(30,27,75,.04),0 12px 30px -18px rgba(30,27,75,.12)}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;
  padding:16px 20px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800;display:flex;align-items:center;gap:8px}
.card-body{padding:20px}

.formrow{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-end}
.field{display:flex;flex-direction:column;gap:6px;min-width:220px}
.field label{font-size:12px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
.field select,.field input{padding:11px 14px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.field select:focus,.field input:focus{outline:none;border-color:var(--main);background:#fff;
  box-shadow:0 0 0 3px rgba(67,56,202,.12)}
.btn{padding:11px 20px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));
  color:#fff;font-weight:800;font-size:14px;cursor:pointer;font-family:inherit}
.btn:hover{filter:brightness(1.06)}
.btn.big{padding:15px 26px;font-size:15.5px;background:linear-gradient(135deg,#F87171,#DC2626);
  box-shadow:0 10px 26px -10px rgba(220,38,38,.5)}
.btn.big:disabled{opacity:.45;cursor:not-allowed;box-shadow:none}

/* Card cảnh báo nghiêm trọng khi tìm thấy lô */
.recall-card{border:2px solid var(--danger);background:linear-gradient(180deg,var(--dangerbg) 0%,#fff 22%)}
.recall-card .card-head{background:var(--danger);color:#fff;border-bottom:none}
.recall-card .card-head h2{color:#fff}
.info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:14px;margin-bottom:18px}
.info-item{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:12px 14px}
.info-item .lbl{font-size:11px;color:var(--muted);font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.info-item .val{font-size:16px;font-weight:800;margin-top:4px}
.info-item.warn .val{color:var(--danger)}
.info-item .val.shelf{color:var(--jade)}

.reason-box textarea{width:100%;min-height:80px;padding:12px 14px;border:1.5px solid var(--border);
  border-radius:10px;font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink);resize:vertical}
.reason-box textarea:focus{outline:none;border-color:var(--danger);background:#fff;
  box-shadow:0 0 0 3px rgba(220,38,38,.14)}
.reason-box label{font-size:12.5px;font-weight:800;color:var(--danger);display:block;margin-bottom:6px}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px;min-width:640px}
th,td{padding:11px 16px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
tbody tr:hover{background:var(--surface)}
.code{font-family:ui-monospace,Consolas,monospace;font-size:12px;color:var(--muted)}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}
.reason-cell{white-space:normal;max-width:280px}
</style>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">🚨 Thu hồi lô khẩn cấp</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <div class="head">
      <h1>⚠️ Thu hồi <span>lô khẩn cấp</span></h1>
      <p>Tìm đúng lô theo số lô, kiểm tra vị trí kệ, và ngừng bán ngay lập tức khi có công văn thu hồi.</p>
    </div>

    <c:if test="${param.msg == 'recalled'}">
      <div class="banner ok">✅ Đã thu hồi lô thành công — lô này đã ngừng bán ngay lập tức tại POS.</div>
    </c:if>
    <c:if test="${not empty error}">
      <div class="banner err">⛔ <c:out value="${error}"/></div>
    </c:if>

    <div class="card">
      <div class="card-head"><div class="wh-ic">🔎</div><h2>Tìm lô cần thu hồi</h2></div>
      <div class="card-body">
        <form method="post" action="<%= ctx %>/warehouse-recall">
          <input type="hidden" name="uid" value="${staffUid}">
          <input type="hidden" name="action" value="search">
          <div class="formrow">
            <div class="field">
              <label>Thuốc</label>
              <div class="wh-field">
                <span class="wh-field-ic">💊</span>
                <select name="medicineId" required>
                  <option value="">— Chọn thuốc —</option>
                  <c:forEach var="m" items="${medicines}">
                    <option value="${m.medicineId}" ${param.medicineId == m.medicineId ? 'selected' : ''}>${m.medicineName}</option>
                  </c:forEach>
                </select>
              </div>
            </div>
            <div class="field">
              <label>Số lô</label>
              <div class="wh-field">
                <span class="wh-field-ic">🏷️</span>
                <input type="text" name="batchNumber" value="${fn:escapeXml(param.batchNumber)}" placeholder="Nhập hoặc quét số lô…" required>
              </div>
            </div>
            <button type="submit" class="btn">🔍 Tìm lô</button>
          </div>
        </form>
      </div>
    </div>

    <c:if test="${not empty foundBatch}">
      <div class="card recall-card">
        <div class="card-head"><div class="wh-ic danger" style="background:rgba(255,255,255,.2);color:#fff">🚨</div><h2>Thông tin lô — xác nhận thu hồi</h2></div>
        <div class="card-body">
          <div class="info-grid">
            <div class="info-item"><div class="lbl">Số lô</div><div class="val">${foundBatch.batchNumber}</div></div>
            <div class="info-item"><div class="lbl">Tên thuốc</div><div class="val">${foundMedName}</div></div>
            <div class="info-item warn"><div class="lbl">Hạn dùng</div><div class="val">${foundBatch.expiryDate}</div></div>
            <div class="info-item warn"><div class="lbl">Còn tồn</div><div class="val">${foundBatch.currentQuantity}</div></div>
            <div class="info-item"><div class="lbl">Vị trí kệ</div><div class="val shelf">📍 ${foundShelf}</div></div>
            <div class="info-item"><div class="lbl">Trạng thái hiện tại</div><div class="val">${foundBatch.status}</div></div>
          </div>

          <c:if test="${foundBatch.status == 'ACTIVE'}">
            <form method="post" action="<%= ctx %>/warehouse-recall" id="recallForm">
              <input type="hidden" name="uid" value="${staffUid}">
              <input type="hidden" name="action" value="confirm-recall">
              <input type="hidden" name="batchId" value="${foundBatch.batchId}">
              <div class="reason-box" style="margin-bottom:16px">
                <label>Lý do thu hồi (bắt buộc)</label>
                <textarea name="reason" id="reasonInput"
                  placeholder="VD: Công văn số .../QLD-CL của Cục Quản lý Dược yêu cầu thu hồi lô do phát hiện lỗi chất lượng…"
                  oninput="document.getElementById('confirmBtn').disabled = this.value.trim().length === 0;"
                  required></textarea>
              </div>
              <button type="submit" class="btn big" id="confirmBtn" disabled
                onclick="return confirm('XÁC NHẬN THU HỒI lô ' + '${foundBatch.batchNumber}' + '? Lô sẽ ngừng bán ngay lập tức.');">
                🚨 Xác nhận Thu hồi
              </button>
            </form>
          </c:if>
        </div>
      </div>
    </c:if>

    <div class="card">
      <div class="card-head"><div class="wh-ic">📋</div><h2>Lịch sử thu hồi <small>(30 ngày gần nhất)</small></h2></div>
      <div class="tblwrap">
        <table>
          <thead><tr>
            <th>Số lô</th><th>Thuốc</th><th>Lý do</th><th>Người thu hồi</th><th>Thời gian</th>
          </tr></thead>
          <tbody>
          <c:choose>
            <c:when test="${empty history}">
              <tr><td colspan="5" class="empty">Chưa có lô nào bị thu hồi trong 30 ngày qua.</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="h" items="${history}">
                <tr>
                  <td class="code">${h.batchNumber}</td>
                  <td>${h.medicineName}</td>
                  <td class="reason-cell">${fn:escapeXml(h.reason)}</td>
                  <td>${h.recalledBy}</td>
                  <td>${h.createdAt}</td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>
</body>
</html>
