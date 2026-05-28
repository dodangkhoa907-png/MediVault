<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medivault.entity.Account acc =
        (com.medivault.entity.Account) session.getAttribute("account");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    com.medivault.entity.Account form =
        (com.medivault.entity.Account) request.getAttribute("account");
    boolean isNew = (form == null || form.getAccountId() == 0);

    String vUsername  = form != null && form.getUsername()  != null ? form.getUsername()  : "";
    String vFullName  = form != null && form.getFullName()  != null ? form.getFullName()  : "";
    String vEmail     = form != null && form.getEmail()     != null ? form.getEmail()     : "";
    String vPhone     = form != null && form.getPhone()     != null ? form.getPhone()     : "";
    String vCitizenId = form != null && form.getCitizenId() != null ? form.getCitizenId(): "";
    String vPosition  = form != null && form.getPosition()  != null ? form.getPosition() : "";
    int    vRoleId    = form != null ? form.getRoleId() : 2;

    // Kiểm tra field nào có lỗi để highlight
    @SuppressWarnings("unchecked")
    java.util.List<String> errs =
        (java.util.List<String>) request.getAttribute("errors");
    boolean hasErrors = (errs != null && !errs.isEmpty());
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isNew ? "Tạo tài khoản" : "Sửa tài khoản" %> — MediVault</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
    <style>
        /* ── Override / extend style.css cho trang form ── */
        :root {
            --navy-deep:  #101A33;
            --navy-mid:   #1D2D50;
            --blue-main:  #114C7D;
            --cyan-light: #5EC3E4;
            --sky-blue:   #46CAF4;
            --surface:    #F2F2F2;
            --gold:       #FCDA7C;
        }

        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background: var(--surface);
            color: var(--navy-deep);
        }

        /* ── PAGE WRAPPER ───────────────────────────── */
        .form-page {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* ── TOPBAR ──────────────────────────────────── */
        .topbar {
            background: var(--navy-deep);
            padding: 14px 32px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 3px solid var(--sky-blue);
        }

        .topbar-left {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .topbar-logo {
            font-family: 'Nunito', sans-serif;
            font-size: 20px;
            font-weight: 900;
            color: #fff;
            display: flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
        }

        .topbar-logo span { color: var(--sky-blue); }

        .topbar-divider {
            width: 1px; height: 20px;
            background: rgba(255,255,255,.2);
        }

        .topbar-title {
            font-size: 14px;
            font-weight: 600;
            color: rgba(255,255,255,.75);
        }

        .btn-back {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 8px 16px;
            background: rgba(255,255,255,.08);
            border: 1px solid rgba(255,255,255,.15);
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            color: rgba(255,255,255,.8);
            text-decoration: none;
            transition: background .2s;
        }
        .btn-back:hover { background: rgba(255,255,255,.15); }

        /* ── CONTENT AREA ───────────────────────────── */
        .form-content {
            flex: 1;
            padding: 40px 32px;
            max-width: 760px;
            margin: 0 auto;
            width: 100%;
        }

        /* Page heading */
        .page-heading {
            margin-bottom: 28px;
        }

        .page-heading .label {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            color: var(--blue-main);
            background: #E8F3FB;
            padding: 4px 12px;
            border-radius: 100px;
            margin-bottom: 10px;
        }

        .page-heading h1 {
            font-family: 'Nunito', sans-serif;
            font-size: 30px;
            font-weight: 900;
            color: var(--navy-deep);
            letter-spacing: -.5px;
        }

        /* ── ERROR BLOCK ─────────────────────────────── */
        .error-block {
            background: #FEF2F2;
            border: 1.5px solid #fca5a5;
            border-left: 4px solid #ef4444;
            border-radius: 12px;
            padding: 16px 20px;
            margin-bottom: 28px;
            animation: slideDown .3s ease;
        }

        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-10px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        .error-block-title {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 700;
            color: #b91c1c;
            margin-bottom: 10px;
        }

        .error-block ul {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .error-block li {
            font-size: 13px;
            color: #dc2626;
            display: flex;
            align-items: flex-start;
            gap: 8px;
        }

        .error-block li::before {
            content: '›';
            font-weight: 700;
            margin-top: 1px;
        }

        /* ── FORM CARD ───────────────────────────────── */
        .form-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 2px 20px rgba(16,26,51,.08);
            overflow: hidden;
        }

        .form-card-header {
            padding: 20px 28px;
            background: linear-gradient(135deg, var(--navy-mid), var(--blue-main));
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .form-card-header .header-icon {
            width: 40px; height: 40px;
            background: rgba(255,255,255,.15);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px;
        }

        .form-card-header h2 {
            font-family: 'Nunito', sans-serif;
            font-size: 18px;
            font-weight: 800;
            color: #fff;
        }

        .form-card-header p {
            font-size: 12px;
            color: rgba(255,255,255,.6);
        }

        .form-card-body {
            padding: 32px 28px;
        }

        /* ── FORM GRID ───────────────────────────────── */
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px 24px;
        }

        .form-grid .span-2 { grid-column: 1 / -1; }

        /* ── FIELD ───────────────────────────────────── */
        .field { display: flex; flex-direction: column; gap: 6px; }

        .field-label {
            font-size: 12.5px;
            font-weight: 600;
            color: var(--navy-mid);
            letter-spacing: .2px;
        }

        .field-label .req { color: #ef4444; margin-left: 2px; }

        .field-label .hint {
            font-weight: 400;
            font-size: 11px;
            color: #94a3b8;
            margin-left: 6px;
        }

        .field-input {
            padding: 11px 14px;
            background: #F8FAFB;
            border: 1.5px solid #e2e8f2;
            border-radius: 9px;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 13.5px;
            color: var(--navy-deep);
            outline: none;
            transition: border-color .2s, box-shadow .2s, background .2s;
        }

        .field-input::placeholder { color: #b0bcd0; font-size: 13px; }

        .field-input:focus {
            border-color: var(--sky-blue);
            background: #fff;
            box-shadow: 0 0 0 3px rgba(70,202,244,.12);
        }

        .field-input[readonly] {
            background: #F0F4F8;
            color: #94a3b8;
            cursor: default;
        }

        /* Select */
        select.field-input {
            cursor: pointer;
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2.5'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 12px center;
            padding-right: 36px;
        }

        .field-note {
            font-size: 11px;
            color: #94a3b8;
            margin-top: -2px;
        }

        /* Password wrapper */
        .pw-wrap { position: relative; }
        .pw-wrap .field-input { padding-right: 40px; }
        .pw-toggle {
            position: absolute;
            right: 12px; top: 50%;
            transform: translateY(-50%);
            background: none; border: none;
            font-size: 15px; cursor: pointer;
            color: #94a3b8;
            padding: 4px;
            transition: color .2s;
        }
        .pw-toggle:hover { color: var(--blue-main); }

        /* ── SECTION DIVIDER ─────────────────────────── */
        .section-divider {
            grid-column: 1 / -1;
            display: flex;
            align-items: center;
            gap: 12px;
            margin: 8px 0 4px;
        }

        .section-divider span {
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1.2px;
            text-transform: uppercase;
            color: #94a3b8;
            white-space: nowrap;
        }

        .section-divider::before, .section-divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: #e8edf5;
        }

        /* ── ACTION ROW ──────────────────────────────── */
        .action-row {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 20px 28px;
            border-top: 1px solid #f0f4f8;
            background: #FAFBFD;
        }

        .btn-submit {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 28px;
            background: linear-gradient(135deg, var(--blue-main), #1a6baa);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-family: 'Nunito', sans-serif;
            font-size: 15px;
            font-weight: 800;
            cursor: pointer;
            transition: transform .15s, box-shadow .2s;
            box-shadow: 0 4px 16px rgba(17,76,125,.3);
        }

        .btn-submit:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 24px rgba(17,76,125,.4);
        }

        .btn-submit:active { transform: translateY(0); }

        .btn-cancel {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 12px 20px;
            background: transparent;
            color: #64748b;
            border: 1.5px solid #dde4ef;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            transition: border-color .2s, color .2s;
        }

        .btn-cancel:hover {
            border-color: var(--blue-main);
            color: var(--blue-main);
        }

        /* Success toast (khi redirect có msg=created) */
        .toast-success {
            position: fixed;
            top: 20px; right: 24px;
            background: #064e3b;
            color: #fff;
            padding: 12px 20px;
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 8px 32px rgba(0,0,0,.2);
            animation: toastIn .3s ease, toastOut .4s 3s ease forwards;
            z-index: 999;
        }

        @keyframes toastIn {
            from { opacity: 0; transform: translateX(20px); }
            to   { opacity: 1; transform: translateX(0); }
        }

        @keyframes toastOut {
            from { opacity: 1; }
            to   { opacity: 0; }
        }

        @media (max-width: 640px) {
            .form-grid { grid-template-columns: 1fr; }
            .form-grid .span-2 { grid-column: 1; }
            .form-content { padding: 24px 16px; }
        }
    </style>
</head>
<body>

<div class="form-page">

    <!-- ── TOPBAR ── -->
    <div class="topbar">
        <div class="topbar-left">
            <a href="${pageContext.request.contextPath}/dashboard" class="topbar-logo">
                💊 Medi<span>Vault</span>
            </a>
            <div class="topbar-divider"></div>
            <div class="topbar-title">Quản lý tài khoản</div>
        </div>
        <a href="${pageContext.request.contextPath}/accounts" class="btn-back">← Quay lại</a>
    </div>

    <!-- ── CONTENT ── -->
    <div class="form-content">

        <!-- Heading -->
        <div class="page-heading">
            <div class="label">
                <%= isNew ? "👤 Tạo mới" : "✏️ Chỉnh sửa" %>
            </div>
            <h1><%= isNew ? "Tạo tài khoản nhân viên" : "Cập nhật tài khoản" %></h1>
        </div>

        <!-- Error block -->
        <% if (hasErrors) { %>
        <div class="error-block">
            <div class="error-block-title">
                <span>⚠️</span> Vui lòng kiểm tra lại thông tin nhập vào
            </div>
            <ul>
                <% for (String err : errs) { %>
                <li><%= err %></li>
                <% } %>
            </ul>
        </div>
        <% } %>

        <!-- Form card -->
        <div class="form-card">
            <div class="form-card-header">
                <div class="header-icon"><%= isNew ? "➕" : "💾" %></div>
                <div>
                    <h2><%= isNew ? "Thông tin tài khoản mới" : "Chỉnh sửa thông tin" %></h2>
                    <p><%= isNew ? "Điền đầy đủ thông tin để tạo tài khoản" : "Cập nhật thông tin nhân viên" %></p>
                </div>
            </div>

            <form method="post" action="${pageContext.request.contextPath}/accounts" novalidate>
                <c:if test="${not empty account and account.accountId > 0}">
                    <input type="hidden" name="accountId" value="${account.accountId}">
                </c:if>

                <div class="form-card-body">
                    <div class="form-grid">

                        <!-- SECTION: Thông tin đăng nhập -->
                        <div class="section-divider span-2">
                            <span>Thông tin đăng nhập</span>
                        </div>

                        <!-- Username -->
                        <div class="field">
                            <label class="field-label" for="username">
                                Tên đăng nhập <span class="req">*</span>
                            </label>
                            <input type="text" id="username" name="username"
                                   class="field-input"
                                   value="<%= vUsername %>"
                                   placeholder="vd: nhanvien01"
                                   <%= isNew ? "required" : "readonly" %>>
                            <% if (!isNew) { %>
                            <span class="field-note">Username không thể thay đổi sau khi tạo.</span>
                            <% } %>
                        </div>

                        <!-- Role -->
                        <div class="field">
                            <label class="field-label" for="roleId">
                                Phân quyền <span class="req">*</span>
                            </label>
                            <select id="roleId" name="roleId" class="field-input" required>
                                <option value="1" <%= vRoleId == 1 ? "selected" : "" %>>🛡️ Admin (Quản trị)</option>
                                <option value="2" <%= vRoleId == 2 ? "selected" : "" %>>💊 Dược sĩ bán hàng</option>
                                <option value="3" <%= vRoleId == 3 ? "selected" : "" %>>📦 Thủ kho</option>
                            </select>
                        </div>

                        <!-- Password -->
                        <div class="field span-2">
                            <label class="field-label" for="password">
                                Mật khẩu
                                <%= isNew
                                    ? "<span class='req'>*</span>"
                                    : "<span class='hint'>(để trống = giữ nguyên mật khẩu cũ)</span>" %>
                            </label>
                            <div class="pw-wrap">
                                <input type="password" id="password" name="password"
                                       class="field-input"
                                       placeholder="<%= isNew ? "Ít nhất 6 ký tự" : "Nhập mật khẩu mới nếu muốn thay đổi" %>"
                                       <%= isNew ? "required minlength='6'" : "minlength='6'" %>>
                                <button type="button" class="pw-toggle" id="togglePw">👁</button>
                            </div>
                        </div>

                        <!-- SECTION: Thông tin cá nhân -->
                        <div class="section-divider span-2">
                            <span>Thông tin cá nhân</span>
                        </div>

                        <!-- Họ tên -->
                        <div class="field span-2">
                            <label class="field-label" for="fullName">
                                Họ và tên đầy đủ <span class="req">*</span>
                            </label>
                            <input type="text" id="fullName" name="fullName"
                                   class="field-input"
                                   value="<%= vFullName %>"
                                   placeholder="Nguyễn Văn A"
                                   required>
                        </div>

                        <!-- Email -->
                        <div class="field">
                            <label class="field-label" for="email">Email</label>
                            <input type="email" id="email" name="email"
                                   class="field-input"
                                   value="<%= vEmail %>"
                                   placeholder="example@gmail.com">
                        </div>

                        <!-- Phone -->
                        <div class="field">
                            <label class="field-label" for="phone">Số điện thoại</label>
                            <input type="tel" id="phone" name="phone"
                                   class="field-input"
                                   value="<%= vPhone %>"
                                   placeholder="0901234567">
                        </div>

                        <!-- CCCD -->
                        <div class="field">
                            <label class="field-label" for="citizenId">CMND / CCCD</label>
                            <input type="text" id="citizenId" name="citizenId"
                                   class="field-input"
                                   value="<%= vCitizenId %>"
                                   placeholder="9 hoặc 12 chữ số"
                                   maxlength="12"
                                   pattern="[0-9]{9}|[0-9]{12}">
                        </div>

                        <!-- Chức vụ -->
                        <div class="field">
                            <label class="field-label" for="position">Chức vụ</label>
                            <input type="text" id="position" name="position"
                                   class="field-input"
                                   value="<%= vPosition %>"
                                   placeholder="Dược sĩ bán hàng">
                        </div>

                    </div>
                </div>

                <!-- Action row -->
                <div class="action-row">
                    <button type="submit" class="btn-submit">
                        <%= isNew ? "➕ Tạo tài khoản" : "💾 Lưu thay đổi" %>
                    </button>
                    <a href="${pageContext.request.contextPath}/accounts" class="btn-cancel">Hủy</a>
                </div>

            </form>
        </div>
    </div>

</div>

<!-- Toast thông báo thành công -->
<% String msg = request.getParameter("msg"); %>
<% if ("created".equals(msg)) { %>
<div class="toast-success">✅ Tài khoản đã được tạo thành công!</div>
<% } else if ("updated".equals(msg)) { %>
<div class="toast-success">✅ Đã cập nhật tài khoản!</div>
<% } %>

<script>
    // Toggle password visibility
    document.getElementById('togglePw').addEventListener('click', function () {
        const pw = document.getElementById('password');
        const isHidden = pw.type === 'password';
        pw.type = isHidden ? 'text' : 'password';
        this.textContent = isHidden ? '🙈' : '👁';
    });

    // Auto-remove toast after 3.5s
    const toast = document.querySelector('.toast-success');
    if (toast) setTimeout(() => toast.remove(), 3500);

    // Highlight inputs nếu có lỗi server
    <% if (hasErrors) { %>
    const errorText = `<%= errs != null ? String.join("|", errs).toLowerCase() : "" %>`;
    const fieldMap = {
        username: ['tên đăng nhập', 'username'],
        email:    ['email'],
        phone:    ['điện thoại'],
        citizenId:['cmnd', 'cccd'],
        fullName: ['họ tên'],
        password: ['mật khẩu']
    };
    Object.entries(fieldMap).forEach(([fieldId, keywords]) => {
        if (keywords.some(kw => errorText.includes(kw))) {
            const el = document.getElementById(fieldId);
            if (el) {
                el.style.borderColor = '#ef4444';
                el.style.boxShadow = '0 0 0 3px rgba(239,68,68,.12)';
            }
        }
    });
    <% } %>
</script>

</body>
</html>
