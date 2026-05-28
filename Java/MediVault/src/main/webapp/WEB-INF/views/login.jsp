<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediVault — Đăng nhập</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --navy-deep:  #101A33;
            --navy-mid:   #1D2D50;
            --blue-main:  #114C7D;
            --cyan-light: #5EC3E4;
            --sky-blue:   #46CAF4;
            --surface:    #F2F2F2;
            --gold:       #FCDA7C;
            --white:      #FFFFFF;
            --text-muted: #8fa3c8;
        }

        html, body {
            height: 100%;
            font-family: 'Plus Jakarta Sans', sans-serif;
        }

        body {
            display: grid;
            grid-template-columns: 1fr 1fr;
            min-height: 100vh;
            background: var(--navy-deep);
            overflow: hidden;
        }

        /* ── LEFT PANEL ─────────────────────────────── */
        .left-panel {
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 60px 64px;
            background: linear-gradient(145deg, var(--navy-deep) 0%, var(--navy-mid) 50%, var(--blue-main) 100%);
            overflow: hidden;
        }

        /* Decorative cross marks */
        .cross {
            position: absolute;
            color: rgba(94,195,228,.15);
            font-size: 48px;
            font-weight: 300;
            line-height: 1;
            user-select: none;
            animation: floatCross 6s ease-in-out infinite;
        }
        .cross:nth-child(1) { top: 8%;  left: 12%;  animation-delay: 0s; font-size: 56px; }
        .cross:nth-child(2) { top: 18%; right: 8%;  animation-delay: 1.5s; font-size: 32px; }
        .cross:nth-child(3) { bottom: 22%; left: 8%; animation-delay: 3s; font-size: 40px; }
        .cross:nth-child(4) { bottom: 10%; right: 15%; animation-delay: 4.5s; font-size: 24px; }
        .cross:nth-child(5) { top: 45%; left: 5%;  animation-delay: 2s; font-size: 20px; }

        @keyframes floatCross {
            0%, 100% { transform: translateY(0) rotate(0deg); opacity: .15; }
            50%       { transform: translateY(-12px) rotate(5deg); opacity: .3; }
        }

        /* Glow orb */
        .glow-orb {
            position: absolute;
            width: 320px; height: 320px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(70,202,244,.18) 0%, transparent 70%);
            bottom: -60px; right: -60px;
            pointer-events: none;
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 52px;
            animation: slideUp .6s ease both;
        }

        .logo-icon {
            width: 64px; height: 64px;
            background: linear-gradient(135deg, var(--sky-blue), var(--cyan-light));
            border-radius: 18px;
            display: flex; align-items: center; justify-content: center;
            font-size: 28px;
            box-shadow: 0 8px 32px rgba(70,202,244,.35);
        }

        .logo-text h1 {
            font-family: 'Nunito', sans-serif;
            font-size: 28px;
            font-weight: 900;
            color: var(--white);
            letter-spacing: -.5px;
        }

        .logo-text span {
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 2px;
            text-transform: uppercase;
            color: var(--sky-blue);
        }

        .brand-headline {
            margin-bottom: 40px;
            animation: slideUp .6s .1s ease both;
        }

        .brand-headline h2 {
            font-family: 'Nunito', sans-serif;
            font-size: 42px;
            font-weight: 900;
            color: var(--white);
            line-height: 1.1;
            letter-spacing: -1px;
            margin-bottom: 12px;
        }

        .brand-headline h2 em {
            font-style: normal;
            color: var(--sky-blue);
        }

        .brand-headline p {
            font-size: 15px;
            color: var(--text-muted);
            line-height: 1.6;
            max-width: 340px;
        }

        .feature-pills {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            animation: slideUp .6s .2s ease both;
        }

        .pill {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 7px 14px;
            background: rgba(255,255,255,.07);
            border: 1px solid rgba(255,255,255,.1);
            border-radius: 100px;
            font-size: 12px;
            font-weight: 500;
            color: rgba(255,255,255,.75);
            backdrop-filter: blur(8px);
        }

        .pill-dot {
            width: 6px; height: 6px;
            border-radius: 50%;
            background: var(--sky-blue);
            box-shadow: 0 0 8px var(--sky-blue);
        }

        /* ── RIGHT PANEL ─────────────────────────────── */
        .right-panel {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 48px 56px;
            background: var(--surface);
            position: relative;
        }

        .right-panel::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--blue-main), var(--sky-blue), var(--cyan-light));
        }

        .login-card {
            width: 100%;
            max-width: 400px;
            animation: slideUp .5s .15s ease both;
        }

        .login-card-header {
            margin-bottom: 36px;
        }

        .role-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 12px 5px 8px;
            background: #EBF5FB;
            border-radius: 100px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            color: var(--blue-main);
            margin-bottom: 16px;
        }

        .role-badge-dot {
            width: 7px; height: 7px;
            border-radius: 50%;
            background: var(--sky-blue);
            box-shadow: 0 0 6px var(--sky-blue);
        }

        .login-card-header h2 {
            font-family: 'Nunito', sans-serif;
            font-size: 36px;
            font-weight: 900;
            color: var(--navy-deep);
            letter-spacing: -1px;
            margin-bottom: 6px;
        }

        .login-card-header p {
            font-size: 14px;
            color: #6b7f9e;
        }

        /* Alert */
        .alert-error {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            padding: 12px 16px;
            background: #FEF2F2;
            border: 1px solid #fecaca;
            border-radius: 10px;
            margin-bottom: 24px;
            font-size: 13px;
            color: #b91c1c;
            animation: shake .4s ease;
        }

        @keyframes shake {
            0%,100% { transform: translateX(0); }
            25% { transform: translateX(-6px); }
            75% { transform: translateX(6px); }
        }

        /* Form */
        .form-group {
            margin-bottom: 20px;
        }

        .form-label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: var(--navy-mid);
            margin-bottom: 7px;
            letter-spacing: .2px;
        }

        .input-wrap {
            position: relative;
        }

        .input-icon {
            position: absolute;
            left: 14px; top: 50%;
            transform: translateY(-50%);
            font-size: 16px;
            color: #94a3b8;
            pointer-events: none;
            transition: color .2s;
        }

        .form-input {
            width: 100%;
            padding: 12px 16px 12px 42px;
            background: var(--white);
            border: 1.5px solid #dde4ef;
            border-radius: 10px;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 14px;
            color: var(--navy-deep);
            outline: none;
            transition: border-color .2s, box-shadow .2s;
        }

        .form-input::placeholder { color: #b0bcd0; }

        .form-input:focus {
            border-color: var(--sky-blue);
            box-shadow: 0 0 0 3px rgba(70,202,244,.15);
        }

        .form-input:focus + .input-icon-right,
        .input-wrap:focus-within .input-icon { color: var(--blue-main); }

        /* Password toggle */
        .input-icon-right {
            position: absolute;
            right: 14px; top: 50%;
            transform: translateY(-50%);
            background: none; border: none;
            cursor: pointer;
            font-size: 16px;
            color: #94a3b8;
            padding: 4px;
            transition: color .2s;
        }
        .input-icon-right:hover { color: var(--blue-main); }
        .form-input.has-right { padding-right: 44px; }

        /* Submit btn */
        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, var(--blue-main), #1a6baa);
            color: var(--white);
            border: none;
            border-radius: 12px;
            font-family: 'Nunito', sans-serif;
            font-size: 16px;
            font-weight: 800;
            letter-spacing: .3px;
            cursor: pointer;
            margin-top: 8px;
            transition: transform .15s, box-shadow .2s, background .2s;
            box-shadow: 0 4px 20px rgba(17,76,125,.35);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .btn-login:hover {
            background: linear-gradient(135deg, #0d3d6b, var(--blue-main));
            transform: translateY(-1px);
            box-shadow: 0 6px 28px rgba(17,76,125,.45);
        }

        .btn-login:active {
            transform: translateY(0);
            box-shadow: 0 2px 12px rgba(17,76,125,.3);
        }

        .btn-login .arrow {
            transition: transform .2s;
        }
        .btn-login:hover .arrow { transform: translateX(4px); }

        .login-footer {
            text-align: center;
            margin-top: 28px;
            font-size: 11.5px;
            color: #94a3b8;
        }

        .login-footer strong { color: var(--blue-main); }

        @keyframes slideUp {
            from { opacity: 0; transform: translateY(20px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        /* FPT Poly badge */
        .poly-badge {
            position: absolute;
            top: 24px; right: 28px;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 1px;
            color: #e85d14;
            text-transform: uppercase;
        }

        /* Responsive */
        @media (max-width: 860px) {
            body { grid-template-columns: 1fr; }
            .left-panel { display: none; }
            .right-panel { padding: 40px 24px; background: var(--navy-deep); }
            .login-card-header h2 { color: var(--white); }
            .login-card-header p { color: var(--text-muted); }
            .form-label { color: rgba(255,255,255,.85); }
            .form-input { background: rgba(255,255,255,.08); border-color: rgba(255,255,255,.15); color: var(--white); }
            .form-input::placeholder { color: rgba(255,255,255,.3); }
            .role-badge { background: rgba(70,202,244,.15); color: var(--sky-blue); }
        }
    </style>
</head>
<body>

<!-- ── LEFT PANEL ───────────────────────────────────────── -->
<div class="left-panel">
    <span class="cross">+</span>
    <span class="cross">+</span>
    <span class="cross">+</span>
    <span class="cross">+</span>
    <span class="cross">+</span>
    <div class="glow-orb"></div>

    <div class="brand-logo">
        <div class="logo-icon">💊</div>
        <div class="logo-text">
            <h1>MediVault</h1>
            <span>Admin Console</span>
        </div>
    </div>

    <div class="brand-headline">
        <h2>Hệ thống quản lý<br>nhà thuốc <em>thông minh</em></h2>
        <p>Quản trị toàn quyền · Tạo &amp; phân quyền nhân viên · Theo dõi kho hàng tự động</p>
    </div>

    <div class="feature-pills">
        <div class="pill"><div class="pill-dot"></div> Quản lý tài khoản</div>
        <div class="pill"><div class="pill-dot"></div> Báo cáo doanh thu</div>
        <div class="pill"><div class="pill-dot"></div> Kho thuốc FIFO</div>
        <div class="pill"><div class="pill-dot"></div> Cấp thuốc tự động</div>
    </div>
</div>

<!-- ── RIGHT PANEL ──────────────────────────────────────── -->
<div class="right-panel">
    <span class="poly-badge">FPT Polytechnic</span>

    <div class="login-card">
        <div class="login-card-header">
            <div class="role-badge">
                <div class="role-badge-dot"></div>
                ADMIN
            </div>
            <h2>Đăng Nhập</h2>
            <p>Truy cập bảng điều khiển quản trị</p>
        </div>

        <!-- Thông báo lỗi -->
        <% if (request.getAttribute("error") != null) { %>
        <div class="alert-error">
            <span>⚠️</span>
            <span><%= request.getAttribute("error") %></span>
        </div>
        <% } %>

        <!-- Form -->
        <form method="post" action="${pageContext.request.contextPath}/login" autocomplete="off">

            <div class="form-group">
                <label class="form-label" for="username">Tên đăng nhập</label>
                <div class="input-wrap">
                    <span class="input-icon">👤</span>
                    <input type="text" id="username" name="username"
                           class="form-input"
                           placeholder="Nhập tên đăng nhập"
                           required autofocus autocomplete="username">
                </div>
            </div>

            <div class="form-group">
                <label class="form-label" for="password">Mật khẩu</label>
                <div class="input-wrap">
                    <span class="input-icon">🔒</span>
                    <input type="password" id="password" name="password"
                           class="form-input has-right"
                           placeholder="Nhập mật khẩu"
                           required autocomplete="current-password">
                    <button type="button" class="input-icon-right" id="togglePw" aria-label="Hiện/ẩn mật khẩu">👁</button>
                </div>
            </div>

            <button type="submit" class="btn-login">
                Đăng nhập quản trị
                <span class="arrow">→</span>
            </button>

        </form>

        <div class="login-footer">
            MediVault v1.0 · <strong>Secure Admin Access</strong>
        </div>
    </div>
</div>

<script>
    document.getElementById('togglePw').addEventListener('click', function () {
        const pw = document.getElementById('password');
        const isHidden = pw.type === 'password';
        pw.type = isHidden ? 'text' : 'password';
        this.textContent = isHidden ? '🙈' : '👁';
    });
</script>

</body>
</html>
