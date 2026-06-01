
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page import="java.lang.String" %>
<%
    com.medivault.entity.Account acc =
        (com.medivault.entity.Account) session.getAttribute("account");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    com.medivault.entity.Account form =
        (com.medivault.entity.Account) request.getAttribute("account");
    boolean isNew = (form == null || form.getAccountId() == 0);

    java.lang.String vUsername  = form != null && form.getUsername()  != null ? form.getUsername()  : "";
    java.lang.String vFullName  = form != null && form.getFullName()  != null ? form.getFullName()  : "";
    java.lang.String vEmail     = form != null && form.getEmail()     != null ? form.getEmail()     : "";
    java.lang.String vPhone     = form != null && form.getPhone()     != null ? form.getPhone()     : "";
    java.lang.String vCitizenId = form != null && form.getCitizenId() != null ? form.getCitizenId(): "";
    java.lang.String vPosition  = form != null && form.getPosition()  != null ? form.getPosition() : "";
    int    vRoleId    = form != null ? form.getRoleId() : 2;

    @SuppressWarnings("unchecked")
    java.util.List<String> errs =
        (java.util.List<String>) request.getAttribute("errors");
    boolean hasErrors = (errs != null && !errs.isEmpty());

    java.lang.String successMsg = (java.lang.String) request.getAttribute("success");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isNew ? "Tạo tài khoản nhân viên" : "Cập nhật tài khoản" %> — MediVault</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;0,600;1,400&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --navy-deep:  #101A33;
            --navy-mid:   #1D2D50;
            --blue-main:  #114C7D;
            --cyan-light: #5EC3E4;
            --sky-blue:   #46CAF4;
            --surface:    #F0F4F9;
            --gold:       #FCDA7C;
            --white:      #FFFFFF;
            --border:     #DDE6F0;
            --text-muted: #6B82A0;
        }

        html, body { height: 100%; font-family: 'Plus Jakarta Sans', sans-serif; }
        body {
            background: var(--surface);
            color: var(--navy-deep);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* ──────────── TOPBAR ──────────── */
        .topbar {
            height: 58px;
            background: var(--navy-deep);
            display: flex;
            align-items: center;
            padding: 0 28px;
            gap: 14px;
            border-bottom: 2px solid var(--sky-blue);
            flex-shrink: 0;
        }
        .topbar-logo {
            font-family: 'Nunito', sans-serif;
            font-size: 18px;
            font-weight: 900;
            color: #fff;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 7px;
        }
        .topbar-logo span { color: var(--sky-blue); }
        .topbar-sep { width: 1px; height: 18px; background: rgba(255,255,255,.2); }
        .topbar-title {
            font-size: 13px;
            font-weight: 500;
            color: rgba(255,255,255,.6);
        }
        .btn-back {
            margin-left: auto;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 15px;
            background: rgba(255,255,255,.08);
            border: 1px solid rgba(255,255,255,.15);
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 500;
            color: rgba(255,255,255,.75);
            text-decoration: none;
            transition: background .2s;
        }
        .btn-back:hover { background: rgba(255,255,255,.14); }

        /* ──────────── CONTENT ──────────── */
        .page-wrap {
            flex: 1;
            display: flex;
            padding: 32px 24px;
            gap: 24px;
            max-width: 1100px;
            width: 100%;
            margin: 0 auto;
        }

        /* Left info panel */
        .info-panel {
            width: 280px;
            flex-shrink: 0;
        }

        .info-card {
            background: linear-gradient(155deg, var(--navy-deep) 0%, var(--blue-main) 100%);
            border-radius: 20px;
            padding: 28px 24px;
            color: #fff;
            position: sticky;
            top: 24px;
        }

        .info-card-icon {
            width: 52px; height: 52px;
            background: rgba(70,202,244,.2);
            border: 1.5px solid rgba(70,202,244,.4);
            border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            font-size: 24px;
            margin-bottom: 18px;
        }

        .info-card h2 {
            font-family: 'Nunito', sans-serif;
            font-size: 19px;
            font-weight: 900;
            margin-bottom: 8px;
            color: #fff;
        }
        .info-card p {
            font-size: 12.5px;
            line-height: 1.65;
            color: rgba(255,255,255,.6);
        }

        .info-steps {
            margin-top: 24px;
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .info-step {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .step-num {
            width: 24px; height: 24px;
            background: rgba(70,202,244,.2);
            border: 1px solid rgba(70,202,244,.35);
            border-radius: 6px;
            display: flex; align-items: center; justify-content: center;
            font-size: 12px;
            font-weight: 700;
            color: var(--sky-blue);
            flex-shrink: 0;
        }
        .step-text strong {
            display: block;
            font-size: 12.5px;
            font-weight: 600;
            color: #fff;
            margin-bottom: 2px;
        }
        .step-text span {
            font-size: 11.5px;
            color: rgba(255,255,255,.45);
            line-height: 1.4;
        }

        .info-otp-note {
            margin-top: 22px;
            padding: 14px 16px;
            background: rgba(70,202,244,.1);
            border: 1px solid rgba(70,202,244,.2);
            border-radius: 12px;
        }
        .info-otp-note .title {
            font-size: 12px;
            font-weight: 700;
            color: var(--sky-blue);
            margin-bottom: 6px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .info-otp-note p {
            font-size: 11.5px;
            color: rgba(255,255,255,.5);
            line-height: 1.5;
        }

        /* ──────────── FORM ──────────── */
        .form-panel {
            flex: 1;
            min-width: 0;
        }

        /* Page title */
        .form-heading {
            margin-bottom: 20px;
        }
        .form-heading .badge-tag {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 3px 11px;
            background: #E8F3FB;
            border-radius: 100px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1px;
            text-transform: uppercase;
            color: var(--blue-main);
            margin-bottom: 8px;
        }
        .form-heading h1 {
            font-family: 'Nunito', sans-serif;
            font-size: 26px;
            font-weight: 900;
            color: var(--navy-deep);
            letter-spacing: -.4px;
        }
        .form-heading p {
            font-size: 13px;
            color: var(--text-muted);
            margin-top: 4px;
        }

        /* Error block */
        .err-block {
            background: #FEF2F2;
            border: 1.5px solid #fca5a5;
            border-left: 4px solid #ef4444;
            border-radius: 12px;
            padding: 14px 18px;
            margin-bottom: 20px;
            animation: fadeDown .3s ease;
        }
        @keyframes fadeDown {
            from { opacity: 0; transform: translateY(-8px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        .err-block-title {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13.5px;
            font-weight: 700;
            color: #b91c1c;
            margin-bottom: 8px;
        }
        .err-block ul { list-style: none; }
        .err-block li {
            font-size: 12.5px;
            color: #dc2626;
            padding: 3px 0;
            display: flex;
            align-items: flex-start;
            gap: 6px;
        }
        .err-block li::before { content: '›'; font-weight: 700; }

        /* Card */
        .form-card {
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 18px;
            overflow: hidden;
            margin-bottom: 16px;
        }

        .form-card-head {
            padding: 18px 24px 16px;
            background: linear-gradient(90deg, #f4f7fb, #e8f2fc);
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .form-card-head-icon {
            width: 36px; height: 36px;
            background: rgba(70,202,244,.15);
            border: 1.5px solid rgba(70,202,244,.3);
            border-radius: 9px;
            display: flex; align-items: center; justify-content: center;
            font-size: 17px;
        }
        .form-card-head h2 {
            font-family: 'Nunito', sans-serif;
            font-size: 15px;
            font-weight: 800;
            color: var(--navy-deep);
        }
        .form-card-head p {
            font-size: 12px;
            color: var(--text-muted);
        }

        .form-body { padding: 22px 24px; }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }
        .span-2 { grid-column: 1 / -1; }

        .field { display: flex; flex-direction: column; gap: 6px; }

        .field-label {
            font-size: 12.5px;
            font-weight: 600;
            color: var(--navy-deep);
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .req { color: #e74c3c; font-size: 13px; }
        .hint {
            font-size: 11px;
            font-weight: 400;
            color: var(--text-muted);
        }

        .field-input {
            height: 40px;
            padding: 0 14px;
            border: 1.5px solid var(--border);
            border-radius: 10px;
            font-size: 13.5px;
            font-family: inherit;
            color: var(--navy-deep);
            background: #fff;
            outline: none;
            transition: border-color .18s, box-shadow .18s;
        }
        .field-input:focus {
            border-color: var(--sky-blue);
            box-shadow: 0 0 0 3px rgba(70,202,244,.12);
        }
        .field-input::placeholder { color: #b0c4d8; }
        .field-input[readonly] {
            background: var(--surface);
            color: var(--text-muted);
            cursor: not-allowed;
        }

        select.field-input {
            appearance: none;
            background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%236B82A0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 12px center;
            padding-right: 30px;
        }

        .pw-wrap { position: relative; }
        .pw-wrap .field-input { padding-right: 42px; width: 100%; }
        .pw-toggle {
            position: absolute;
            right: 12px; top: 50%; transform: translateY(-50%);
            background: none;
            border: none;
            cursor: pointer;
            font-size: 15px;
            line-height: 1;
            color: var(--text-muted);
            padding: 0;
        }

        .field-note {
            font-size: 11.5px;
            color: var(--text-muted);
            display: flex;
            align-items: center;
            gap: 4px;
        }

        /* Email highlight when creating (OTP will be sent) */
        .email-highlight .field-label::after {
            content: '· OTP sẽ gửi về đây';
            font-size: 10.5px;
            font-weight: 500;
            color: var(--sky-blue);
            background: rgba(70,202,244,.1);
            padding: 2px 7px;
            border-radius: 10px;
            margin-left: 6px;
        }
        .email-highlight .field-input {
            border-color: rgba(70,202,244,.4);
        }
        .email-highlight .field-input:focus {
            border-color: var(--sky-blue);
        }

        /* Action row */
        .action-row {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 18px 24px;
            background: #fafcff;
            border-top: 1px solid var(--border);
        }

        .btn-submit {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 11px 24px;
            background: linear-gradient(135deg, var(--blue-main), #0e3d63);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            transition: opacity .2s, transform .1s;
        }
        .btn-submit:hover { opacity: .9; }
        .btn-submit:active { transform: scale(.98); }

        .btn-cancel {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 11px 20px;
            background: #fff;
            border: 1.5px solid var(--border);
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 500;
            color: var(--navy-deep);
            cursor: pointer;
            text-decoration: none;
            transition: border-color .2s;
        }
        .btn-cancel:hover { border-color: var(--blue-main); color: var(--blue-main); }

        .action-note {
            margin-left: auto;
            font-size: 12px;
            color: var(--text-muted);
            display: flex;
            align-items: center;
            gap: 5px;
        }

        /* Toast */
        #toast {
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
            box-shadow: 0 8px 32px rgba(0,0,0,.18);
            z-index: 999;
            animation: slideIn .3s ease;
        }
        @keyframes slideIn {
            from { opacity: 0; transform: translateX(16px); }
            to   { opacity: 1; transform: translateX(0); }
        }

        @media (max-width: 768px) {
            .page-wrap { flex-direction: column; padding: 20px 16px; }
            .info-panel { width: 100%; }
            .info-card { position: static; }
            .form-grid { grid-template-columns: 1fr; }
            .span-2 { grid-column: 1; }
        }
    </style>
</head>
<body>

<!-- ── TOPBAR ── -->
<header class="topbar">
    <a href="${pageContext.request.contextPath}/dashboard" class="topbar-logo">
        💊 Medi<span>Vault</span>
    </a>
    <div class="topbar-sep"></div>
    <span class="topbar-title">Quản lý tài khoản nhân viên</span>
    <a href="${pageContext.request.contextPath}/dashboard" class="btn-back">← Quay lại Dashboard</a>
</header>

<!-- ── CONTENT ── -->
<div class="page-wrap">

    <!-- LEFT INFO PANEL -->
    <aside class="info-panel">
        <div class="info-card">
            <div class="info-card-icon">
                <%= isNew ? "➕" : "✏️" %>
            </div>
            <h2><%= isNew ? "Thêm nhân viên mới" : "Chỉnh sửa tài khoản" %></h2>
            <p>
                <%= isNew
                    ? "Tạo tài khoản cho nhân viên mới. Hệ thống sẽ gửi mã OTP xác nhận qua email."
                    : "Cập nhật thông tin tài khoản nhân viên trong hệ thống." %>
            </p>

            <% if (isNew) { %>
            <div class="info-steps">
                <div class="info-step">
                    <div class="step-num">1</div>
                    <div class="step-text">
                        <strong>Điền thông tin</strong>
                        <span>Nhập thông tin tài khoản và cá nhân đầy đủ</span>
                    </div>
                </div>
                <div class="info-step">
                    <div class="step-num">2</div>
                    <div class="step-text">
                        <strong>Gửi OTP</strong>
                        <span>Hệ thống tự động gửi mã xác nhận 6 số về email nhân viên</span>
                    </div>
                </div>
                <div class="info-step">
                    <div class="step-num">3</div>
                    <div class="step-text">
                        <strong>Xác nhận & Tạo</strong>
                        <span>Nhập mã OTP để kích hoạt tài khoản</span>
                    </div>
                </div>
            </div>

            <div class="info-otp-note">
                <div class="title">📧 Lưu ý về OTP</div>
                <p>Email nhân viên phải hợp lệ. Mã OTP có hiệu lực trong <strong style="color:var(--sky-blue)">5 phút</strong>.</p>
            </div>
            <% } %>
        </div>
    </aside>

    <!-- FORM PANEL -->
    <section class="form-panel">

        <div class="form-heading">
            <div class="badge-tag">
                <%= isNew ? "👤 Tạo mới" : "✏️ Chỉnh sửa" %>
            </div>
            <h1><%= isNew ? "Tạo tài khoản nhân viên" : "Cập nhật tài khoản" %></h1>
            <p><%= isNew
                    ? "Điền đầy đủ thông tin bên dưới. OTP sẽ được gửi tới email nhân viên."
                    : "Chỉnh sửa thông tin tài khoản, sau đó lưu lại." %></p>
        </div>

        <!-- Lỗi validation -->
        <% if (hasErrors) { %>
        <div class="err-block">
            <div class="err-block-title">⚠️ Vui lòng kiểm tra lại thông tin</div>
            <ul>
                <% for (String err : errs) { %>
                <li><%= err %></li>
                <% } %>
            </ul>
        </div>
        <% } %>

        <!-- ── FORM ── -->
        <form method="post" action="${pageContext.request.contextPath}/accounts" novalidate id="mainForm">
            <c:if test="${not empty account and account.accountId > 0}">
                <input type="hidden" name="accountId" value="${account.accountId}">
            </c:if>
            <%-- Flag để servlet biết phải gửi OTP khi tạo mới --%>
            <input type="hidden" name="action" value="<%= isNew ? "create-otp" : "update" %>">

            <!-- Card 1: Thông tin đăng nhập -->
            <div class="form-card">
                <div class="form-card-head">
                    <div class="form-card-head-icon">🔑</div>
                    <div>
                        <h2>Thông tin đăng nhập</h2>
                        <p>Username, mật khẩu và phân quyền hệ thống</p>
                    </div>
                </div>
                <div class="form-body">
                    <div class="form-grid">

                        <!-- Username -->
                        <div class="field">
                            <label class="field-label" for="username">
                                Tên đăng nhập <span class="req">*</span>
                            </label>
                            <input type="text" id="username" name="username"
                                   class="field-input"
                                   value="<%= vUsername %>"
                                   placeholder="vd: nhanvien01"
                                   <%= isNew ? "required" : "readonly" %>
                                   autocomplete="username">
                            <% if (!isNew) { %>
                            <span class="field-note">ℹ️ Username không thể thay đổi sau khi tạo.</span>
                            <% } %>
                        </div>

                        <!-- Phân quyền -->
                        <div class="field">
                            <label class="field-label" for="roleId">
                                Phân quyền <span class="req">*</span>
                            </label>
                            <select id="roleId" name="roleId" class="field-input" required>
                                <option value="2" <%= vRoleId == 2 ? "selected" : "" %>>💊 Dược sĩ bán hàng</option>
                                <option value="3" <%= vRoleId == 3 ? "selected" : "" %>>📦 Thủ kho</option>
                            </select>
                        </div>

                        <!-- Mật khẩu -->
                        <div class="field span-2">
                            <label class="field-label" for="password">
                                Mật khẩu
                                <%= isNew
                                    ? "<span class='req'>*</span>"
                                    : "<span class='hint'>(để trống nếu không muốn đổi)</span>" %>
                            </label>
                            <div class="pw-wrap">
                                <input type="password" id="password" name="password"
                                       class="field-input"
                                       placeholder="<%= isNew ? "Ít nhất 6 ký tự" : "Nhập mật khẩu mới để thay đổi" %>"
                                       <%= isNew ? "required minlength='6'" : "minlength='6'" %>
                                       autocomplete="new-password">
                                <button type="button" class="pw-toggle" id="togglePw" title="Hiện/ẩn mật khẩu">👁</button>
                            </div>
                        </div>

                    </div>
                </div>
            </div>

            <!-- Card 2: Thông tin cá nhân -->
            <div class="form-card">
                <div class="form-card-head">
                    <div class="form-card-head-icon">👤</div>
                    <div>
                        <h2>Thông tin cá nhân</h2>
                        <p>Họ tên, email, số điện thoại và CCCD</p>
                    </div>
                </div>
                <div class="form-body">
                    <div class="form-grid">

                        <!-- Họ và tên -->
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

                        <!-- Email — highlight khi tạo mới (OTP) -->
                        <div class="field <%= isNew ? "email-highlight" : "" %>">
                            <label class="field-label" for="email">
                                Email <%= isNew ? "<span class='req'>*</span>" : "" %>
                            </label>
                            <input type="email" id="email" name="email"
                                   class="field-input"
                                   value="<%= vEmail %>"
                                   placeholder="example@gmail.com"
                                   <%= isNew ? "required" : "" %>>
                            <% if (isNew) { %>
                            <span class="field-note">📧 OTP 6 số sẽ được gửi tới email này để xác nhận.</span>
                            <% } %>
                        </div>

                        <!-- Số điện thoại -->
                        <div class="field">
                            <label class="field-label" for="phone">Số điện thoại</label>
                            <input type="tel" id="phone" name="phone"
                                   class="field-input"
                                   value="<%= vPhone %>"
                                   placeholder="0901234567"
                                   pattern="0[0-9]{9}">
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
                            <label class="field-label" for="position">Chức vụ / Bộ phận</label>
                            <input type="text" id="position" name="position"
                                   class="field-input"
                                   value="<%= vPosition %>"
                                   placeholder="Dược sĩ bán hàng, Thủ kho…">
                        </div>

                    </div>
                </div>

                <!-- Action row bên trong card -->
                <div class="action-row">
                    <button type="submit" class="btn-submit" id="submitBtn">
                        <%= isNew
                            ? "📧 Tạo & Gửi mã OTP"
                            : "💾 Lưu thay đổi" %>
                    </button>
                    <a href="${pageContext.request.contextPath}/dashboard" class="btn-cancel">Hủy</a>
                    <% if (isNew) { %>
                    <span class="action-note">🔒 OTP sẽ gửi qua Gmail nhân viên</span>
                    <% } %>
                </div>
            </div>

        </form>
    </section>
</div>

<!-- Toast -->
<% java.lang.String msg = request.getParameter("msg"); %>
<% if ("updated".equals(msg)) { %>
<div id="toast">✅ Đã cập nhật tài khoản thành công!</div>
<% } %>

<script>
    // Toggle mật khẩu
    document.getElementById('togglePw').addEventListener('click', function() {
        const pw = document.getElementById('password');
        const show = pw.type === 'password';
        pw.type = show ? 'text' : 'password';
        this.textContent = show ? '🙈' : '👁';
    });

    // Auto-hide toast
    const toast = document.getElementById('toast');
    if (toast) setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 400); }, 3500);

    // Loading state khi submit
    document.getElementById('mainForm').addEventListener('submit', function() {
        const btn = document.getElementById('submitBtn');
        btn.disabled = true;
        btn.innerHTML = '⏳ Đang xử lý…';
    });

    // Client-side validation highlights
    <% if (hasErrors) { %>
    const errorText = `<%= errs != null ? String.join("|", errs).toLowerCase() : "" %>`;
    const fieldMap = {
        username:  ['tên đăng nhập','username'],
        email:     ['email'],
        phone:     ['điện thoại','phone'],
        citizenId: ['cmnd','cccd'],
        fullName:  ['họ tên','họ và tên'],
        password:  ['mật khẩu']
    };
    Object.entries(fieldMap).forEach(([id, kws]) => {
        if (kws.some(kw => errorText.includes(kw))) {
            const el = document.getElementById(id);
            if (el) {
                el.style.borderColor = '#ef4444';
                el.style.boxShadow = '0 0 0 3px rgba(239,68,68,.12)';
                el.focus();
            }
        }
    });
    <% } %>

    // Email live validation
    const emailInput = document.getElementById('email');
    if (emailInput) {
        emailInput.addEventListener('blur', function() {
            const val = this.value;
            if (val && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
                this.style.borderColor = '#ef4444';
                this.title = 'Email không hợp lệ';
            } else {
                this.style.borderColor = '';
                this.title = '';
            }
        });
    }

    // Phone format hint
    const phoneInput = document.getElementById('phone');
    if (phoneInput) {
        phoneInput.addEventListener('input', function() {
            this.value = this.value.replace(/[^0-9]/g, '').slice(0, 10);
        });
    }
</script>

</body>
</html>
