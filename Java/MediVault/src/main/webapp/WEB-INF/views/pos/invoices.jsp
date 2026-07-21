<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("staffAccount");
    boolean isLoggedIn = (acc != null && acc.getRoleId() != 1);
    String fullName = isLoggedIn ? (acc.getFullName() != null ? acc.getFullName() : acc.getUsername()) : "Dược sĩ";
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String ctx = request.getContextPath();
    String uid = request.getParameter("uid");
    String uidQS = uid != null && !uid.isEmpty() ? "?uid=" + uid : "";
    String posLink = ctx + "/pos" + uidQS;
    String dashboardLink = ctx + "/staff-dashboard" + uidQS;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Hóa đơn của tôi — Medicare POS</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --blue:#1558A8;--cyan:#3ABDE0;--navy:#0F2645;--ink:#0B1628;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}
.topbar{height:64px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 24px;gap:14px;position:sticky;top:0;z-index:20}
.back-btn{display:inline-flex;align-items:center;gap:6px;padding:8px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:700;text-decoration:none;transition:.15s}
.back-btn:hover{border-color:var(--blue);color:var(--blue)}
.topbar-title{font-size:16px;font-weight:800;display:flex;align-items:center;gap:8px}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.staff-badge{display:flex;align-items:center;gap:8px;padding:6px 12px 6px 6px;border-radius:22px;background:#EFF6FF}
.staff-av{width:28px;height:28px;border-radius:50%;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.staff-name{font-size:12.5px;font-weight:700;color:var(--blue)}
.pos-link{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;border-radius:10px;background:linear-gradient(135deg,var(--blue),#0d3d63);color:#fff;font-size:13px;font-weight:800;text-decoration:none;transition:.15s}
.pos-link:hover{filter:brightness(1.08)}

.content{max-width:760px;margin:0 auto;padding:22px 20px 60px}
.range-row{display:flex;align-items:center;gap:10px;margin-bottom:18px}
.range-row label{font-size:13px;font-weight:700;color:var(--muted)}
.range-row select{padding:8px 14px;border:1.5px solid var(--border);border-radius:9px;font-size:13px;font-weight:700;font-family:inherit;color:var(--ink);background:var(--white);cursor:pointer}

.stat-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:20px}
.stat-card{background:var(--white);border-radius:14px;padding:16px 18px;box-shadow:0 2px 12px rgba(15,38,69,.06)}
.stat-card .sc-label{font-size:11.5px;color:var(--muted);font-weight:700;text-transform:uppercase;letter-spacing:.4px}
.stat-card .sc-value{font-size:22px;font-weight:800;color:var(--navy);margin-top:4px}
.stat-card.rev .sc-value{color:var(--green)}

.inv-list{background:var(--white);border-radius:14px;box-shadow:0 2px 12px rgba(15,38,69,.06);overflow:hidden}
.inv-row{display:flex;justify-content:space-between;align-items:center;padding:15px 18px;border-bottom:1px solid #F1F5F9;cursor:pointer;transition:.12s}
.inv-row:last-child{border-bottom:none}
.inv-row:hover{background:#F8FAFC}
.inv-code{font-weight:800;font-size:14px;color:var(--navy)}
.inv-view-tag{font-size:10.5px;color:#93c5fd;font-weight:700;margin-left:6px}
.inv-meta{font-size:12px;color:var(--muted);margin-top:3px}
.inv-amount{font-weight:800;font-size:15px;text-align:right}
.inv-amount.refunded{color:var(--red)}
.inv-amount.ok{color:var(--green)}
.inv-refund-tag{font-size:10.5px;color:var(--red);font-weight:700;text-align:right}

.empty-state{text-align:center;padding:60px 20px;color:var(--muted)}
.empty-state .es-icon{font-size:40px;margin-bottom:10px}
.loading{text-align:center;padding:40px 0;color:var(--muted);font-size:13px}
.err-state{text-align:center;padding:40px 0;color:var(--red);font-size:13px}
</style>
</head>
<body>

<div class="topbar">
  <a href="<%= dashboardLink %>" class="back-btn">← Trang chủ</a>
  <div class="topbar-title">🧾 Hóa đơn của tôi</div>
  <div class="topbar-right">
    <div class="staff-badge">
      <div class="staff-av"><%= initials %></div>
      <div class="staff-name"><%= fullName %></div>
    </div>
    <a href="<%= posLink %>" class="pos-link">🛒 Sang bán hàng (POS)</a>
  </div>
</div>

<div class="content">
  <div class="range-row">
    <label for="rangeSel">Thời gian:</label>
    <select id="rangeSel" onchange="loadInvoices()">
      <option value="today">Hôm nay</option>
      <option value="yesterday">Hôm qua</option>
      <option value="7days">7 ngày qua</option>
      <option value="30days">30 ngày qua</option>
    </select>
  </div>

  <div class="stat-row">
    <div class="stat-card">
      <div class="sc-label">Số hóa đơn</div>
      <div class="sc-value" id="statCount">—</div>
    </div>
    <div class="stat-card rev">
      <div class="sc-label">Doanh thu</div>
      <div class="sc-value" id="statRevenue">—</div>
    </div>
  </div>

  <div id="invList" class="loading">Đang tải…</div>
</div>

<script>
const ctx = '<%= ctx %>';
const sellerName = '<%= fullName %>';
function fmt(n) { return new Intl.NumberFormat('vi-VN').format(Math.round(n||0)) + 'đ'; }
function escHtml(s) {
  const d = document.createElement('div');
  d.textContent = s == null ? '' : String(s);
  return d.innerHTML;
}

async function loadInvoices() {
  const list = document.getElementById('invList');
  list.className = 'loading';
  list.innerHTML = 'Đang tải…';
  document.getElementById('statCount').textContent = '—';
  document.getElementById('statRevenue').textContent = '—';
  try {
    const range = document.getElementById('rangeSel').value;
    const res = await fetch(ctx + '/pos?action=my-invoices&range=' + range);
    const data = await res.json();
    if (!data.ok) {
      list.className = 'err-state';
      list.innerHTML = data.reason === 'not_logged_in' ? 'Chưa điểm danh ca làm.' : 'Lỗi tải dữ liệu.';
      return;
    }
    document.getElementById('statCount').textContent = data.count;
    document.getElementById('statRevenue').textContent = fmt(parseFloat(data.totalRevenue) || 0);
    if (!data.invoices.length) {
      list.className = 'empty-state';
      list.innerHTML = '<div class="es-icon">🧾</div><div>Không có hóa đơn nào trong khoảng thời gian này.</div>';
      return;
    }
    const mLabel = { 'CASH': '💵 Tiền mặt', 'QR_CODE': '📱 QR', 'CARD': '💳 Thẻ' };
    list.className = 'inv-list';
    list.innerHTML = data.invoices.map(iv => {
      const refunded = iv.status !== 'COMPLETED';
      let displayTime = iv.time;
      if (displayTime && displayTime.includes('-')) {
        const parts = displayTime.split(' ');
        if (parts.length >= 2) {
          const dateParts = parts[0].split('-');
          displayTime = dateParts[2] + '/' + dateParts[1] + ' ' + parts[1];
        }
      }
      return '<div class="inv-row" onclick="viewInvoice(' + iv.id + ')">'
        + '<div><span class="inv-code">' + escHtml(iv.code) + '</span><span class="inv-view-tag">↗ xem lại</span>'
        + '<div class="inv-meta">' + displayTime + ' · ' + (mLabel[iv.method] || iv.method) + '</div></div>'
        + '<div><div class="inv-amount ' + (refunded ? 'refunded' : 'ok') + '">' + fmt(parseFloat(iv.amount) || 0) + '</div>'
        + (refunded ? '<div class="inv-refund-tag">Hoàn trả</div>' : '')
        + '</div></div>';
    }).join('');
  } catch (e) {
    list.className = 'err-state';
    list.innerHTML = 'Lỗi kết nối.';
  }
}

// ── Xem lại / in lại 1 hóa đơn (dùng chung định dạng in với màn bán hàng) ──
function buildReceiptHtml(inv) {
  let itemRows = '';
  inv.items.forEach((item, idx) => {
    const dosageLine = item.dosage
      ? '<div style="font-size:9.5px;color:#444;font-style:italic;margin-top:1px">↳ HDSD: ' + escHtml(item.dosage) + '</div>'
      : '';
    itemRows += '<tr>'
      + '<td style="text-align:center;padding:4px 6px">' + (idx+1) + '</td>'
      + '<td style="padding:4px 6px">' + escHtml(item.name) + dosageLine + '</td>'
      + '<td style="text-align:center;padding:4px 6px">' + escHtml(item.unit) + '</td>'
      + '<td style="text-align:center;padding:4px 6px">' + item.qty + '</td>'
      + '<td style="text-align:right;padding:4px 6px">' + fmt(item.price) + '</td>'
      + '<td style="text-align:right;padding:4px 6px;font-weight:750">' + fmt(item.price * item.qty) + '</td>'
      + '</tr>';
  });

  return '<!DOCTYPE html>'
    + '<html lang="vi"><head>'
    + '<meta charset="UTF-8">'
    + '<title>Hóa đơn ' + escHtml(inv.code) + '</title>'
    + '<style>'
    + '* { margin:0; padding:0; box-sizing:border-box; }'
    + 'body { font-family: "Courier New", monospace; font-size: 12px; color: #000; padding: 8px; max-width: 320px; margin: 0 auto; }'
    + '.center { text-align: center; }'
    + '.bold { font-weight: bold; }'
    + '.title { font-size: 15px; font-weight:800; margin: 4px 0; }'
    + '.divider { border-top: 1px dashed #000; margin: 7px 0; }'
    + '.divider2 { border-top: 2px solid #000; margin: 7px 0; }'
    + 'table { width: 100%; border-collapse: collapse; font-size: 11px; }'
    + 'th { background: #eee; padding: 4px 6px; font-weight:750; border-bottom: 1px solid #000; }'
    + 'td { vertical-align: top; }'
    + '.totals { margin-top: 6px; }'
    + '.totals-row { display: flex; justify-content: space-between; padding: 2px 0; font-size: 12px; }'
    + '.totals-row.grand { font-size: 14px; font-weight:800; border-top: 2px solid #000; padding-top: 5px; margin-top: 3px; }'
    + '.footer { text-align: center; margin-top: 10px; font-style: italic; font-size: 11.5px; }'
    + '.kv { display: flex; justify-content: space-between; font-size: 11.5px; padding: 2px 0; }'
    + '.reprint-tag { text-align:center; font-size:10.5px; color:#b45309; background:#fffbeb; border:1px dashed #d97706; border-radius:4px; padding:3px 6px; margin-bottom:6px; }'
    + '@media print { body { padding: 0; } button { display: none; } }'
    + '</style>'
    + '</head><body>'
    + (inv.reprint ? '<div class="reprint-tag">🔁 BẢN XEM LẠI — không phải hóa đơn gốc</div>' : '')
    + '<div class="center">'
    + '<div class="bold" style="font-size:14px">NHÀ THUỐC Medicare</div>'
    + '<div>Địa chỉ: 123 Đường Ba Cu, P.4, TP. Vũng Tàu</div>'
    + '<div>Điện thoại: 0901.234.567</div>'
    + '</div>'
    + '<div class="divider2"></div>'
    + '<div class="center"><div class="title">HÓA ĐƠN BÁN LẺ</div></div>'
    + '<div class="divider"></div>'
    + '<div class="kv"><span class="bold">Số HĐ:</span><span>#' + escHtml(inv.code) + '</span></div>'
    + '<div class="kv"><span class="bold">Ngày lập:</span><span>' + inv.dateStr + '</span></div>'
    + '<div class="kv"><span class="bold">Khách hàng:</span><span>' + (inv.customerName ? escHtml(inv.customerName) : 'Khách lẻ') + '</span></div>'
    + (inv.customerName && inv.customerPhone ? '<div class="kv"><span class="bold">SĐT:</span><span>' + escHtml(inv.customerPhone) + '</span></div>' : '')
    + '<div class="kv"><span class="bold">Dược sĩ bán:</span><span>' + escHtml(inv.sellerName) + '</span></div>'
    + '<div class="divider"></div>'
    + '<table><thead><tr>'
    + '<th style="text-align:center;width:24px">STT</th>'
    + '<th>Tên Thuốc / Vật Tư</th>'
    + '<th style="text-align:center;width:30px">ĐVT</th>'
    + '<th style="text-align:center;width:24px">SL</th>'
    + '<th style="text-align:right;width:60px">Đơn Giá</th>'
    + '<th style="text-align:right;width:66px">Thành Tiền</th>'
    + '</tr></thead><tbody>' + itemRows + '</tbody></table>'
    + '<div class="divider"></div>'
    + '<div class="totals">'
    + '<div class="totals-row"><span>Tổng tiền hàng:</span><span>' + fmt(inv.subtotal) + '</span></div>'
    + '<div class="totals-row"><span>Giảm giá:</span><span>-' + fmt(inv.discount) + '</span></div>'
    + '<div class="totals-row grand"><span>TỔNG THANH TOÁN:</span><span>' + fmt(inv.total) + '</span></div>'
    + '</div>'
    + '<div class="divider"></div>'
    + '<div class="footer">'
    + '<div>-- Chúc quý khách sức khỏe và một ngày tốt lành --</div>'
    + '<div style="margin-top:4px;font-size:10px;color:#555">Hẹn gặp lại quý khách!</div>'
    + '</div>'
    + '<div style="height:16px"></div>'
    + '<div class="center" style="margin-top:8px">'
    + '<button onclick="window.print()" style="padding:8px 20px;background:#1a56db;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:13px;font-weight:750;font-family:&quot;Plus Jakarta Sans&quot;,sans-serif">🖶 In hóa đơn</button>'
    + '<button onclick="window.close()" style="padding:8px 16px;background:#e5e7eb;color:#111;border:none;border-radius:6px;cursor:pointer;font-size:13px;margin-left:6px;font-family:&quot;Plus Jakarta Sans&quot;,sans-serif">✕ Đóng</button>'
    + '</div>'
    + '</body></html>';
}

function openReceiptWindow(html) {
  const win = window.open('', '_blank', 'width=380,height=600,toolbar=0,menubar=0,scrollbars=1');
  if (win) {
    win.document.write(html);
    win.document.close();
  } else {
    alert('⚠️ Trình duyệt chặn popup — vui lòng cho phép!');
  }
}

async function viewInvoice(invoiceId) {
  try {
    const res = await fetch(ctx + '/pos?action=invoice-detail&id=' + invoiceId);
    const data = await res.json();
    if (!data.ok) {
      alert(data.reason === 'not_found' ? 'Không tìm thấy hóa đơn.' : 'Không tải được hóa đơn.');
      return;
    }
    const iv = data.invoice;
    const html = buildReceiptHtml({
      code: iv.code,
      dateStr: iv.dateStr,
      customerName: iv.customerName,
      customerPhone: iv.customerPhone,
      sellerName: iv.sellerName,
      items: iv.items,
      subtotal: parseFloat(iv.subtotal) || 0,
      discount: parseFloat(iv.discount) || 0,
      total: parseFloat(iv.total) || 0,
      reprint: true
    });
    openReceiptWindow(html);
  } catch (e) {
    alert('Lỗi kết nối khi tải hóa đơn.');
  }
}

loadInvoices();
</script>
</body>
</html>
