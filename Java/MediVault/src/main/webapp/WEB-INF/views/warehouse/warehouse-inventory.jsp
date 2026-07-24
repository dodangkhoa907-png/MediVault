<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "inventory";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Quản lý tồn kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=5">
<style>
a{text-decoration:none;color:inherit}

.wrap{max-width:1200px;margin:0 auto;padding:28px 28px 60px}
.head{display:flex;align-items:flex-end;justify-content:space-between;flex-wrap:wrap;gap:14px;margin-bottom:22px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.head h1 span{color:var(--main)}
.head p{color:var(--muted);font-size:14px;margin-top:4px}

.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat{background:#fff;
  border:1px solid #E4E9E7;border-radius:14px;padding:16px 18px;
  box-shadow:0 1px 2px rgba(4,47,46,.04),0 8px 22px -14px rgba(4,47,46,.10);
  display:flex;align-items:center;gap:14px}
.stat .ic{width:44px;height:44px;border-radius:12px;display:grid;place-items:center;font-size:20px;flex:none}
.stat .num{font-size:24px;font-weight:800;letter-spacing:-.5px;line-height:1}
.stat .lbl{font-size:12.5px;color:var(--muted);font-weight:600;margin-top:3px}
.stat.a .ic{background:var(--soft);color:var(--main)}
.stat.b .ic{background:var(--goldbg);color:var(--gold)} .stat.b .num{color:var(--gold)}
.stat.c .ic{background:var(--goldbg);color:var(--gold)}
.stat.d .ic{background:var(--dangerbg);color:var(--danger)} .stat.d .num{color:var(--danger)}

.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;overflow:hidden;margin-bottom:22px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12)}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;
  padding:16px 20px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800}
.card-head h2 small{color:var(--muted);font-weight:600;font-size:12.5px;margin-left:6px}

.search{display:flex;gap:8px}
.search input{width:280px;max-width:52vw;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.search input:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(15,118,110,.12)}
.search button{padding:10px 16px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));
  color:#fff;font-weight:700;font-size:13.5px;cursor:pointer;font-family:inherit}
.search a.clear{padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;color:var(--muted);font-weight:700;font-size:13.5px}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px}
th,td{padding:13px 16px;text-align:left;border-bottom:1px solid var(--line)}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
/* Zebra + hover — mắt bám dòng tốt hơn khi quét ngang, tránh nhìn lộn giá của dòng khác. */
tbody tr:nth-child(even){background:#F8FAFC}
tbody tr:hover{background:#E6FFFA}
.code{font-family:ui-monospace,Consolas,monospace;font-size:12px;color:#4B5A56}
.mname{font-weight:700;color:#0F172A;line-height:1.35}
.gen{font-size:12px;color:var(--muted);margin-top:3px}
.num-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:700}
.price-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:800;color:#0F172A}
.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge.ok{background:var(--okbg);color:var(--ok)}
.badge.low{background:var(--goldbg);color:var(--gold)}
.badge.out{background:var(--dangerbg);color:var(--danger)}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}
.act-cell{white-space:nowrap;text-align:right}
.act-btn{display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;
  border-radius:8px;font-size:14.5px;margin-left:4px;background:var(--surface);border:1px solid var(--border);
  transition:.15s}
.act-btn:hover{background:var(--soft);border-color:var(--main);transform:translateY(-1px)}

/* ── Split view: bảng chính (65%) | cột cảnh báo lô xếp dọc (35%) ──
   Thay cho bố cục xếp chồng cũ (bảng full-width rồi mới tới 2 bảng cảnh báo bên dưới) —
   vừa lấp khoảng trắng 2 bên, vừa để 2 bảng cảnh báo không bị dồn nén tí hon ở đáy trang. */
.split{display:grid;grid-template-columns:1.7fr 1fr;gap:20px;align-items:start}
.side-stack{display:flex;flex-direction:column;gap:20px}
.panel h2 .ic{margin-right:6px}
.warn-head{background:linear-gradient(90deg,#FEF3C7,transparent)}
.dead-head{background:linear-gradient(90deg,var(--dangerbg),transparent)}
.exp-date{font-weight:700}
.exp-soon{color:var(--gold)} .exp-dead{color:var(--danger)}

@media(max-width:1000px){.split{grid-template-columns:1fr}}
@media(max-width:900px){.stats{grid-template-columns:repeat(2,1fr)}}

/* ── Modal "👁 Xem chi tiết" — hiện toàn bộ thông tin sản phẩm + mọi lô ngay tại chỗ,
   không điều hướng sang trang khác (giữ nguyên bộ lọc/kết quả tìm kiếm đang xem dở). ── */
.dm-backdrop{display:none;position:fixed;inset:0;z-index:9000;background:rgba(11,22,40,.55);
  align-items:flex-start;justify-content:center;padding:40px 20px;overflow-y:auto}
.dm-backdrop.show{display:flex}
.dm-box{background:#fff;border-radius:18px;max-width:720px;width:100%;box-shadow:0 24px 70px rgba(0,0,0,.3);overflow:hidden}
.dm-head{padding:18px 24px;background:linear-gradient(135deg,var(--deep),var(--main));color:#fff;
  display:flex;align-items:center;justify-content:space-between;gap:12px}
.dm-head h3{font-size:16.5px;font-weight:800;margin:0}
.dm-head .sub{font-size:12px;color:rgba(255,255,255,.7);margin-top:2px}
.dm-close{background:rgba(255,255,255,.16);border:none;color:#fff;width:30px;height:30px;
  border-radius:9px;font-size:15px;cursor:pointer;flex:none}
.dm-close:hover{background:rgba(255,255,255,.28)}
.dm-body{padding:22px 24px;max-height:70vh;overflow-y:auto}
.dm-loading{padding:40px;text-align:center;color:var(--muted)}
.dm-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px 20px;margin-bottom:18px}
.dm-field{display:flex;flex-direction:column;gap:3px}
.dm-field .k{font-size:10.5px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.dm-field .v{font-size:13.5px;font-weight:650;color:#0F172A}
.dm-field .v.empty{color:var(--muted);font-weight:500;font-style:italic}
.dm-field.full{grid-column:1/-1}
.dm-sec-title{font-size:12px;font-weight:800;color:var(--main);text-transform:uppercase;
  letter-spacing:.5px;margin:18px 0 10px;padding-top:14px;border-top:1px solid var(--line)}
.dm-batches table{font-size:12.5px}
.dm-batches th,.dm-batches td{padding:8px 12px}
.dm-batch-status{font-size:10.5px;font-weight:750;padding:2px 8px;border-radius:14px}
.dm-batch-status.ACTIVE{background:var(--okbg);color:var(--ok)}
.dm-batch-status.RECALLED{background:var(--dangerbg);color:var(--danger)}
.dm-batch-status.CANCELLED,.dm-batch-status.EXPIRED{background:#F1F5F4;color:var(--muted)}
</style>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Quản lý tồn kho</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <div class="head">
      <div>
        <h1>Quản lý <span>tồn kho</span></h1>
        <p>Danh mục thuốc, tồn kho thực tế theo lô, và cảnh báo hạn dùng.</p>
      </div>
    </div>

    <div class="stats">
      <div class="stat a"><div class="ic">💊</div><div><div class="num">${totalActive}</div><div class="lbl">Thuốc đang kinh doanh</div></div></div>
      <div class="stat b"><div class="ic">📉</div><div><div class="num">${lowStockCount}</div><div class="lbl">Sắp hết hàng</div></div></div>
      <div class="stat c"><div class="ic">⏳</div><div><div class="num">${expiringBatches.size()}</div><div class="lbl">Lô cận hạn (≤30 ngày)</div></div></div>
      <div class="stat d"><div class="ic">⛔</div><div><div class="num">${expiredBatches.size()}</div><div class="lbl">Lô đã hết hạn</div></div></div>
    </div>

    <div class="split">
      <!-- ══ Cột trái (65%): Danh mục thuốc — đã thu gọn cột, bỏ Barcode/ĐVT/HSD khỏi bảng
           chính (2 lý do: (1) đỡ chật, hết cần cuộn ngang; (2) HSD đã có chi tiết đầy đủ
           ở 2 widget cảnh báo bên phải rồi, không cần lặp lại). Barcode vẫn tìm được qua ô search. ══ -->
      <div class="card">
        <div class="card-head">
          <div style="display:flex;align-items:center;gap:12px">
            <div class="wh-ic">💊</div>
            <h2>Danh mục thuốc <small>(${medicines.size()} mục)</small></h2>
          </div>
          <form class="search" method="get" action="<%= ctx %>/warehouse-inventory">
            <input type="hidden" name="uid" value="${staffUid}">
            <div class="wh-field">
              <span class="wh-field-ic">🔍</span>
              <input type="text" name="q" value="${fn:escapeXml(keyword)}" placeholder="Tìm tên, hoạt chất, barcode, mã thuốc…">
            </div>
            <button type="submit">🔍 Tìm</button>
            <c:if test="${not empty keyword}"><a class="clear" href="<%= ctx %>/warehouse-inventory?uid=${staffUid}">✕</a></c:if>
          </form>
        </div>
        <div class="tblwrap">
          <table>
            <thead><tr>
              <th>Mã</th><th>Thuốc</th>
              <th style="text-align:right">Tồn kho</th><th>Trạng thái</th>
              <th style="text-align:right">Giá bán</th>
              <th style="text-align:right">Thao tác</th>
            </tr></thead>
            <tbody>
            <c:choose>
              <c:when test="${empty medicines}">
                <tr><td colspan="6" class="empty">Không có thuốc nào khớp tìm kiếm.</td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="m" items="${medicines}">
                  <tr>
                    <td class="code">${m.medicineCode}</td>
                    <td>
                      <div class="mname">${m.medicineName}</div>
                      <c:if test="${not empty m.genericName}"><div class="gen">${m.genericName}</div></c:if>
                    </td>
                    <td class="num-cell">${m.totalStock} / <span style="color:var(--muted);font-weight:600">${m.minInventory}</span></td>
                    <td>
                      <c:choose>
                        <c:when test="${m.totalStock == 0}"><span class="badge out">Hết hàng</span></c:when>
                        <c:when test="${m.minInventory > 0 && m.totalStock <= m.minInventory}"><span class="badge low">Sắp hết</span></c:when>
                        <c:otherwise><span class="badge ok">Đủ hàng</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="price-cell"><fmt:formatNumber value="${m.sellingPrice}" type="number" maxFractionDigits="0"/>đ</td>
                    <td class="act-cell">
                      <button type="button" class="act-btn" onclick="openDetail(${m.medicineId})" title="Xem toàn bộ thông tin sản phẩm">👁️</button>
                      <a class="act-btn" href="<%= ctx %>/warehouse-reorder?uid=${staffUid}" title="Xem gợi ý đặt hàng">🛒</a>
                    </td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
            </tbody>
          </table>
        </div>
      </div>

      <!-- ══ Cột phải (35%): 2 widget cảnh báo xếp dọc — không còn bị dồn tí hon ở đáy trang ══ -->
      <div class="side-stack">
        <div class="card panel">
          <div class="card-head warn-head"><div class="wh-ic warn">⏳</div><h2>Lô cận hạn <small>≤ 30 ngày</small></h2></div>
          <div class="tblwrap">
            <table style="min-width:auto">
              <thead><tr><th>Số lô</th><th>Thuốc</th><th style="text-align:right">Tồn</th><th>Hạn</th></tr></thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty expiringBatches}"><tr><td colspan="4" class="empty">Không có lô nào cận hạn. 👍</td></tr></c:when>
                  <c:otherwise>
                    <c:forEach var="b" items="${expiringBatches}">
                      <tr>
                        <td class="code">${b.batchNumber}</td>
                        <td class="mname">${medNameMap[b.medicineId]}</td>
                        <td class="num-cell">${b.currentQuantity}</td>
                        <td class="exp-date exp-soon">${b.expiryDate}</td>
                      </tr>
                    </c:forEach>
                  </c:otherwise>
                </c:choose>
              </tbody>
            </table>
          </div>
        </div>

        <div class="card panel">
          <div class="card-head dead-head"><div class="wh-ic danger">⛔</div><h2>Lô đã hết hạn</h2></div>
          <div class="tblwrap">
            <table style="min-width:auto">
              <thead><tr><th>Số lô</th><th>Thuốc</th><th style="text-align:right">Tồn</th><th>Hạn</th></tr></thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty expiredBatches}"><tr><td colspan="4" class="empty">Không có lô hết hạn tồn kho. 👍</td></tr></c:when>
                  <c:otherwise>
                    <c:forEach var="b" items="${expiredBatches}">
                      <tr>
                        <td class="code">${b.batchNumber}</td>
                        <td class="mname">${medNameMap[b.medicineId]}</td>
                        <td class="num-cell">${b.currentQuantity}</td>
                        <td class="exp-date exp-dead">${b.expiryDate}</td>
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
  </div>
</div>

<!-- ══ Modal chi tiết sản phẩm — fetch AJAX, không rời trang ══ -->
<div class="dm-backdrop" id="dmBackdrop" onclick="if(event.target===this)closeDetail()">
  <div class="dm-box">
    <div class="dm-head">
      <div>
        <h3 id="dmTitle">Chi tiết sản phẩm</h3>
        <div class="sub" id="dmSub"></div>
      </div>
      <button type="button" class="dm-close" onclick="closeDetail()">✕</button>
    </div>
    <div class="dm-body" id="dmBody">
      <div class="dm-loading">Đang tải…</div>
    </div>
  </div>
</div>

<script>
const _dmCtx = '<%= ctx %>';
const _dmUid = '${staffUid}';
function _dmEsc(s){ return (s==null?'':String(s)).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function _dmField(label, value, full){
  const empty = value===null || value===undefined || value==='';
  return '<div class="dm-field'+(full?' full':'')+'"><span class="k">'+_dmEsc(label)+'</span>'
       + '<span class="v'+(empty?' empty':'')+'">'+(empty?'Chưa có dữ liệu':_dmEsc(value))+'</span></div>';
}
function openDetail(medicineId){
  document.getElementById('dmBackdrop').classList.add('show');
  document.getElementById('dmTitle').textContent = 'Chi tiết sản phẩm';
  document.getElementById('dmSub').textContent = '';
  document.getElementById('dmBody').innerHTML = '<div class="dm-loading">Đang tải…</div>';
  fetch(_dmCtx + '/warehouse-inventory?action=detail&id=' + medicineId + '&uid=' + encodeURIComponent(_dmUid))
    .then(r => r.json())
    .then(data => {
      if (data.error) { document.getElementById('dmBody').innerHTML = '<div class="dm-loading">Không tải được dữ liệu.</div>'; return; }
      const m = data.medicine, batches = data.batches || [];
      document.getElementById('dmTitle').textContent = m.medicineName;
      document.getElementById('dmSub').textContent = m.medicineCode + (m.genericName ? ' · ' + m.genericName : '');

      let html = '<div class="dm-grid">'
        + _dmField('Danh mục', m.categoryName)
        + _dmField('Nhà sản xuất', m.manufacturerName)
        + _dmField('Vị trí kệ', m.shelfName)
        + _dmField('Đơn vị', m.unit)
        + _dmField('Barcode', m.barcode)
        + _dmField('Số đăng ký', m.registrationNumber)
        + _dmField('Giá bán', Number(m.sellingPrice).toLocaleString('vi-VN') + 'đ')
        + _dmField('Tồn kho / Ngưỡng tối thiểu', m.totalStock + ' / ' + m.minInventory)
        + _dmField('Kê đơn (Rx)', m.isPrescriptionRequired ? 'Có — cần đơn thuốc' : 'Không')
        + _dmField('Quy cách đóng gói', m.packagingSpec)
        + _dmField('Liều dùng', m.dosage, true)
        + (m.dosageWarning ? _dmField('Cảnh báo liều dùng', m.dosageWarning) : '')
        + _dmField('Chống chỉ định', m.contraindications)
        + _dmField('Điều kiện bảo quản', m.storageConditions)
        + '</div>';

      html += '<div class="dm-sec-title">📦 Tất cả lô hàng (' + batches.length + ')</div>';
      if (batches.length === 0) {
        html += '<div class="empty">Chưa có lô nào cho thuốc này.</div>';
      } else {
        html += '<div class="dm-batches tblwrap"><table><thead><tr>'
          + '<th>Số lô</th><th>NSX</th><th>HSD</th><th style="text-align:right">Tồn / Nhập ban đầu</th><th>Trạng thái</th>'
          + '</tr></thead><tbody>';
        batches.forEach(b => {
          html += '<tr><td class="code">' + _dmEsc(b.batchNumber) + '</td>'
            + '<td>' + _dmEsc(b.importDate || '—') + '</td>'
            + '<td>' + _dmEsc(b.expiryDate || '—') + '</td>'
            + '<td class="num-cell">' + b.currentQuantity + ' / ' + b.initialQuantity + '</td>'
            + '<td><span class="dm-batch-status ' + _dmEsc(b.status) + '">' + _dmEsc(b.status) + '</span></td></tr>';
        });
        html += '</tbody></table></div>';
      }
      document.getElementById('dmBody').innerHTML = html;
    })
    .catch(() => { document.getElementById('dmBody').innerHTML = '<div class="dm-loading">Lỗi kết nối, thử lại sau.</div>'; });
}
function closeDetail(){ document.getElementById('dmBackdrop').classList.remove('show'); }
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDetail(); });
</script>
</body>
</html>
