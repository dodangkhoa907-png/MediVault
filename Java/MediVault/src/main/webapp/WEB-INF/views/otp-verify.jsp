<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    /*
     * otp-verify.jsp — Xác nhận mã OTP
     *
     * Dùng cho 2 luồng:
     *   1) Đăng nhập (LoginServlet):
     *      session["otpCode"], session["otpExpiry"], session["pendingAccount"]
     *
     *   2) Tạo tài khoản nhân viên (AccountServlet → action=create-otp):
     *      session["newAccOtpCode"], session["newAccOtpExpiry"], session["pendingNewAccount"]
     *
     * Servlet xử lý: POST /otp-verify
     *   param: otpCode (6 chữ số), context ("login" | "new-account")
     */

    // Xác định context hiện tại
    boolean isNewAccount = (session.getAttribute("pendingNewAccount") != null);
    boolean isLogin      = (session.getAttribute("pendingAccount")    != null);

    if (!isNewAccount && !isLogin) {
        // Không có context hợp lệ → redirect về login
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    java.lang.String context = isNewAccount ? "new-account" : "login";

    // Email để hiển thị (che bớt)
    java.lang.String targetEmail = "";
    if (isNewAccount) {
        Object pna = session.getAttribute("pendingNewAccount");
        if (pna instanceof com.medivault.entity.Account) {
            targetEmail = ((com.medivault.entity.Account) pna).getEmail();
        }
    } else {
        Object pa = session.getAttribute("pendingAccount");
        if (pa instanceof com.medivault.entity.Account) {
            targetEmail = ((com.medivault.entity.Account) pa).getEmail();
        }
    }

    // Che email: abc****@gmail.com
    java.lang.String maskedEmail = targetEmail;
    if (targetEmail != null && targetEmail.contains("@")) {
        int atIdx = targetEmail.indexOf('@');
        java.lang.String local = targetEmail.substring(0, atIdx);
        java.lang.String domain = targetEmail.substring(atIdx);
        if (local.length() > 3) {
            maskedEmail = local.substring(0, 3) + "****" + domain;
        } else {
            maskedEmail = local + "****" + domain;
        }
    }

    // Lỗi nếu có
    java.lang.String errMsg = (java.lang.String) request.getAttribute("error");
    java.lang.String infoMsg = (java.lang.String) request.getAttribute("info");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xác nhận OTP — MediVault</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;0,600;1,300&display=swap" rel="stylesheet">
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
        }

        /* ──────────── LEFT PANEL ──────────── */
        .left-panel {
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 60px 64px;
            background: linear-gradient(145deg, var(--navy-deep) 0%, var(--navy-mid) 50%, var(--blue-main) 100%);
            overflow: hidden;
        }

        /* Decorative circles */
        .left-panel::before {
            content: '';
            position: absolute;
            width: 420px; height: 420px;
            border-radius: 50%;
            border: 60px solid rgba(70,202,244,.06);
            top: -120px; right: -140px;
            pointer-events: none;
        }
        .left-panel::after {
            content: '';
            position: absolute;
            width: 280px; height: 280px;
            border-radius: 50%;
            border: 40px solid rgba(70,202,244,.04);
            bottom: -80px; left: -80px;
            pointer-events: none;
        }

        /* Cross decoration */
        .deco-cross {
            position: absolute;
            width: 8px; height: 8px;
            pointer-events: none;
        }
        .deco-cross::before, .deco-cross::after {
            content: '';
            position: absolute;
            background: rgba(70,202,244,.25);
            border-radius: 2px;
        }
        .deco-cross::before { width: 2px; height: 8px; left: 3px; }
        .deco-cross::after  { width: 8px; height: 2px; top: 3px; }
        .dc1 { top: 80px;  right: 80px;  }
        .dc2 { top: 200px; right: 160px; transform: scale(1.5); opacity: .5; }
        .dc3 { bottom: 140px; left: 60px; }
        .dc4 { bottom: 90px;  left: 130px; transform: scale(.8); opacity: .6; }

        /* Logo */
        .left-logo {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 48px;
            z-index: 1;
        }
        .left-logo-icon {
            width: 44px; height: 44px;
            background: rgba(70,202,244,.15);
            border: 1.5px solid rgba(70,202,244,.3);
            border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            font-size: 22px;
        }
        .left-logo-text {
            font-family: 'Nunito', sans-serif;
            font-size: 20px;
            font-weight: 900;
            color: #fff;
        }
        .left-logo-text span { color: var(--sky-blue); }

        /* Main left content */
        .left-content { position: relative; z-index: 1; }

        .left-tag {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 13px;
            background: rgba(70,202,244,.12);
            border: 1px solid rgba(70,202,244,.2);
            border-radius: 100px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 1px;
            text-transform: uppercase;
            color: var(--sky-blue);
            margin-bottom: 18px;
        }

        .left-title {
            font-family: 'Nunito', sans-serif;
            font-size: 34px;
            font-weight: 900;
            color: #fff;
            line-height: 1.18;
            letter-spacing: -.6px;
            margin-bottom: 16px;
        }
        .left-title span { color: var(--sky-blue); }

        .left-desc {
            font-size: 14px;
            color: rgba(255,255,255,.55);
            line-height: 1.7;
            max-width: 340px;
            margin-bottom: 36px;
        }

        /* Feature bullets */
        .left-features {
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .left-feat {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .feat-icon {
            width: 34px; height: 34px;
            background: rgba(70,202,244,.1);
            border: 1px solid rgba(70,202,244,.2);
            border-radius: 9px;
            display: flex; align-items: center; justify-content: center;
            font-size: 15px;
            flex-shrink: 0;
        }
        .feat-text strong {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #fff;
        }
        .feat-text span {
            font-size: 11.5px;
            color: rgba(255,255,255,.4);
        }

        /* Email display on left */
        .left-email-badge {
            margin-top: 32px;
            padding: 14px 18px;
            background: rgba(70,202,244,.08);
            border: 1px solid rgba(70,202,244,.2);
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .left-email-badge .icon { font-size: 20px; }
        .left-email-badge .info strong {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: rgba(255,255,255,.6);
            margin-bottom: 2px;
        }
        .left-email-badge .info .email {
            font-size: 14px;
            font-weight: 600;
            color: var(--sky-blue);
            word-break: break-all;
        }

        /* OTP expiry timer */
        .left-timer {
            margin-top: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            color: rgba(255,255,255,.4);
        }
        .left-timer .countdown {
            font-weight: 700;
            color: var(--sky-blue);
            font-size: 13px;
            font-family: 'Nunito', sans-serif;
        }

        /* ──────────── RIGHT PANEL ──────────── */
        .right-panel {
            background: var(--surface);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 48px 56px;
        }

        .right-inner {
            width: 100%;
            max-width: 400px;
        }

        .right-icon {
            width: 58px; height: 58px;
            background: linear-gradient(135deg, rgba(70,202,244,.2), rgba(17,76,125,.15));
            border: 2px solid rgba(70,202,244,.3);
            border-radius: 16px;
            display: flex; align-items: center; justify-content: center;
            font-size: 26px;
            margin-bottom: 22px;
        }

        .right-title {
            font-family: 'Nunito', sans-serif;
            font-size: 26px;
            font-weight: 900;
            color: var(--navy-deep);
            letter-spacing: -.5px;
            margin-bottom: 8px;
        }

        .right-sub {
            font-size: 13.5px;
            color: #6B82A0;
            line-height: 1.6;
            margin-bottom: 28px;
        }
        .right-sub .email-hl {
            font-weight: 600;
            color: var(--blue-main);
        }

        /* Error / info alerts */
        .alert {
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 13px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 8px;
            animation: popIn .25s ease;
        }
        @keyframes popIn {
            from { opacity: 0; transform: scale(.97); }
            to   { opacity: 1; transform: scale(1); }
        }
        .alert-error {
            background: #FEF2F2;
            border: 1px solid #fca5a5;
            color: #b91c1c;
        }
        .alert-info {
            background: #EFF6FF;
            border: 1px solid #93c5fd;
            color: #1d4ed8;
        }
        .alert-success {
            background: #F0FDF4;
            border: 1px solid #86efac;
            color: #166534;
        }

        /* OTP input group */
        .otp-group {
            display: flex;
            gap: 10px;
            justify-content: center;
            margin-bottom: 28px;
        }

        .otp-box {
            width: 52px; height: 58px;
            border: 2px solid #D1E0EE;
            border-radius: 12px;
            text-align: center;
            font-size: 22px;
            font-weight: 800;
            font-family: 'Nunito', sans-serif;
            color: var(--navy-deep);
            background: #fff;
            outline: none;
            caret-color: var(--sky-blue);
            transition: border-color .18s, box-shadow .18s, transform .1s;
            -moz-appearance: textfield;
        }
        .otp-box::-webkit-outer-spin-button,
        .otp-box::-webkit-inner-spin-button { -webkit-appearance: none; }
        .otp-box:focus {
            border-color: var(--sky-blue);
            box-shadow: 0 0 0 4px rgba(70,202,244,.15);
            transform: translateY(-2px);
        }
        .otp-box.filled {
            border-color: var(--blue-main);
            background: #E8F3FB;
        }
        .otp-box.error {
            border-color: #ef4444;
            background: #FEF2F2;
            animation: shake .35s ease;
        }
        @keyframes shake {
            0%,100% { transform: translateX(0); }
            25%      { transform: translateX(-5px); }
            75%      { transform: translateX(5px); }
        }

        /* Hidden actual input */
        #otpCode { display: none; }

        /* Submit button */
        .btn-verify {
            width: 100%;
            height: 48px;
            background: linear-gradient(135deg, var(--blue-main), #0e3d63);
            color: #fff;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 700;
            font-family: inherit;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: opacity .2s, transform .1s;
            margin-bottom: 16px;
        }
        .btn-verify:hover { opacity: .92; }
        .btn-verify:active { transform: scale(.98); }
        .btn-verify:disabled {
            opacity: .5;
            cursor: not-allowed;
            transform: none;
        }

        /* Resend link */
        .resend-row {
            text-align: center;
            font-size: 13px;
            color: #6B82A0;
            margin-bottom: 20px;
        }
        .resend-row #resendBtn {
            background: none;
            border: none;
            color: var(--blue-main);
            font-weight: 600;
            cursor: pointer;
            font-size: 13px;
            font-family: inherit;
            text-decoration: underline;
            padding: 0;
        }
        .resend-row #resendBtn:disabled {
            color: #b0c4d8;
            text-decoration: none;
            cursor: default;
        }

        /* Back link */
        .back-link {
            text-align: center;
            font-size: 12.5px;
            color: #9FB0C4;
        }
        .back-link a {
            color: #6B82A0;
            font-weight: 600;
            text-decoration: none;
        }
        .back-link a:hover { color: var(--blue-main); text-decoration: underline; }

        /* Progress dots */
        .step-dots {
            display: flex;
            justify-content: center;
            gap: 6px;
            margin-bottom: 28px;
        }
        .step-dot {
            width: 8px; height: 8px;
            border-radius: 50%;
            background: #D1E0EE;
            transition: background .2s, width .2s;
        }
        .step-dot.done  { background: #1a7a4a; }
        .step-dot.active { background: var(--sky-blue); width: 22px; border-radius: 4px; }

        /* Responsive */
        @media (max-width: 768px) {
            body { grid-template-columns: 1fr; }
            .left-panel { display: none; }
            .right-panel { padding: 40px 24px; }
        }
    </style>
</head>
<body>

<!-- ──────── LEFT PANEL ──────── -->
<div class="left-panel">
    <div class="deco-cross dc1"></div>
    <div class="deco-cross dc2"></div>
    <div class="deco-cross dc3"></div>
    <div class="deco-cross dc4"></div>

    <!-- Logo -->
    <div class="left-logo">
        <div class="left-logo-icon">💊</div>
        <div class="left-logo-text">Medi<span>Vault</span></div>
    </div>

    <div class="left-content">
        <div class="left-tag">
            🔐 Bảo mật 2 lớp
        </div>
        <h1 class="left-title">
            Xác nhận<br>qua <span>Email</span>
        </h1>
        <p class="left-desc">
            <%= isNewAccount
                ? "Mã OTP đã được gửi đến email nhân viên để xác nhận tài khoản mới. Quá trình này giúp đảm bảo email nhân viên hợp lệ."
                : "Hệ thống đã gửi mã xác thực 6 chữ số đến email của bạn. Nhập mã để hoàn tất đăng nhập an toàn." %>
        </p>

        <div class="left-features">
            <div class="left-feat">
                <div class="feat-icon">🔒</div>
                <div class="feat-text">
                    <strong>Bảo mật cao</strong>
                    <span>Mã OTP ngẫu nhiên, hết hạn sau 5 phút</span>
                </div>
            </div>
            <div class="left-feat">
                <div class="feat-icon">📧</div>
                <div class="feat-text">
                    <strong>Xác thực Email</strong>
                    <span><%= isNewAccount ? "Đảm bảo email nhân viên tồn tại và hợp lệ" : "Chỉ người có quyền truy cập email mới xác nhận được" %></span>
                </div>
            </div>
            <div class="left-feat">
                <div class="feat-icon">⚡</div>
                <div class="feat-text">
                    <strong>Nhanh chóng</strong>
                    <span>Email thường đến trong vài giây</span>
                </div>
            </div>
        </div>

        <div class="left-email-badge">
            <div class="icon">📨</div>
            <div class="info">
                <strong>Đã gửi OTP đến</strong>
                <div class="email"><%= maskedEmail.isEmpty() ? "email của bạn" : maskedEmail %></div>
            </div>
        </div>

        <div class="left-timer">
            ⏱ Mã còn hiệu lực:
            <span class="countdown" id="leftCountdown">05:00</span>
        </div>
    </div>
</div>

<!-- ──────── RIGHT PANEL ──────── -->
<div class="right-panel">
    <div class="right-inner">

        <!-- Step dots -->
        <div class="step-dots">
            <div class="step-dot done"></div>
            <div class="step-dot active"></div>
            <div class="step-dot"></div>
        </div>

        <div class="right-icon">📧</div>
        <h1 class="right-title">
            <%= isNewAccount ? "Xác nhận email nhân viên" : "Nhập mã OTP" %>
        </h1>
        <p class="right-sub">
            Nhập mã <strong>6 chữ số</strong> đã được gửi tới<br>
            <span class="email-hl"><%= maskedEmail.isEmpty() ? "email của bạn" : maskedEmail %></span>
        </p>

        <!-- Error / info messages -->
        <% if (errMsg != null && !errMsg.isEmpty()) { %>
        <div class="alert alert-error">❌ <%= errMsg %></div>
        <% } %>
        <% if (infoMsg != null && !infoMsg.isEmpty()) { %>
        <div class="alert alert-info">ℹ️ <%= infoMsg %></div>
        <% } %>

        <!-- OTP form -->
        <form method="post" action="${pageContext.request.contextPath}/otp-verify" id="otpForm">
            <input type="hidden" name="context" value="<%= context %>">
            <input type="hidden" name="otpCode" id="otpCode">

            <!-- 6 OTP boxes -->
            <div class="otp-group" id="otpGroup">
                <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-index="0" autofocus>
                <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-index="1">
                <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-index="2">
                <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-index="3">
                <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-index="4">
                <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-index="5">
            </div>

            <button type="submit" class="btn-verify" id="verifyBtn" disabled>
                🔓 Xác nhận
            </button>
        </form>

        <!-- Resend -->
        <div class="resend-row">
            Không nhận được mã?
            <form method="post" action="${pageContext.request.contextPath}/otp-verify" style="display:inline">
                <input type="hidden" name="context" value="<%= context %>">
                <input type="hidden" name="resend" value="1">
                <button type="submit" id="resendBtn" disabled>
                    Gửi lại (<span id="resendCountdown">60</span>s)
                </button>
            </form>
        </div>

        <!-- Back -->
        <div class="back-link">
            <a href="${pageContext.request.contextPath}/<%= isNewAccount ? "account-form" : "login" %>">
                ← <%= isNewAccount ? "Quay lại form tạo tài khoản" : "Quay lại đăng nhập" %>
            </a>
        </div>

    </div>
</div><!-- /right-panel -->

<script>
    // ─── OTP Box behavior ───────────────────────────
    const boxes   = document.querySelectorAll('.otp-box');
    const otpHid  = document.getElementById('otpCode');
    const verifyBtn = document.getElementById('verifyBtn');

    function getOtpValue() {
        return Array.from(boxes).map(b => b.value).join('');
    }

    function syncHidden() {
        const val = getOtpValue();
        otpHid.value = val;
        verifyBtn.disabled = val.length < 6 || val.split('').some(c => !/\d/.test(c));
        boxes.forEach((b, i) => {
            b.classList.toggle('filled', b.value !== '');
            b.classList.remove('error');
        });
    }

    boxes.forEach((box, idx) => {
        box.addEventListener('input', e => {
            const val = e.target.value.replace(/\D/g, '');
            box.value = val.slice(-1);  // only last digit
            syncHidden();
            if (val && idx < 5) boxes[idx + 1].focus();
        });

        box.addEventListener('keydown', e => {
            if (e.key === 'Backspace') {
                if (!box.value && idx > 0) { boxes[idx - 1].focus(); boxes[idx - 1].value = ''; }
                syncHidden();
            }
            if (e.key === 'ArrowLeft'  && idx > 0) boxes[idx - 1].focus();
            if (e.key === 'ArrowRight' && idx < 5) boxes[idx + 1].focus();
        });

        box.addEventListener('paste', e => {
            e.preventDefault();
            const pasted = (e.clipboardData || window.clipboardData)
                .getData('text').replace(/\D/g, '').slice(0, 6);
            boxes.forEach((b, i) => { b.value = pasted[i] || ''; });
            if (pasted.length === 6) verifyBtn.focus();
            syncHidden();
        });

        box.addEventListener('focus', () => box.select());
    });

    // ─── Form submit: loading state ─────────────────
        document.getElementById('otpForm').addEventListener('submit', function(e) {
            const otp = getOtpValue();
            if (otp.length < 6) { e.preventDefault(); return; }
            verifyBtn.disabled = true;
            verifyBtn.innerHTML = '⏳ Đang kiểm tra…';
            boxes.forEach(b => b.disabled = true);
        });

    // ─── Countdown timer (5 min) ────────────────────
    let totalSec = 5 * 60;
    const leftCd = document.getElementById('leftCountdown');

    function formatTime(s) {
        const m = Math.floor(s / 60).toString().padStart(2, '0');
        const sec = (s % 60).toString().padStart(2, '0');
        return m + ':' + sec;
    }

    const mainTimer = setInterval(() => {
        totalSec--;
        if (leftCd) leftCd.textContent = formatTime(totalSec);
        if (totalSec <= 0) {
            clearInterval(mainTimer);
            if (leftCd) leftCd.style.color = '#e74c3c';
            verifyBtn.disabled = true;
            verifyBtn.innerHTML = '⏰ Mã đã hết hạn';
            boxes.forEach(b => { b.disabled = true; b.classList.add('error'); });
        }
    }, 1000);

    // ─── Resend countdown (60s) ──────────────────────
    let resendSec = 60;
    const resendBtn = document.getElementById('resendBtn');
    const resendCd  = document.getElementById('resendCountdown');

    const resendTimer = setInterval(() => {
        resendSec--;
        if (resendCd) resendCd.textContent = resendSec;
        if (resendSec <= 0) {
            clearInterval(resendTimer);
            if (resendBtn) {
                resendBtn.disabled = false;
                resendBtn.innerHTML = 'Gửi lại mã OTP';
            }
        }
    }, 1000);

    // ─── Show shake on error ─────────────────────────
    <% if (errMsg != null && !errMsg.isEmpty()) { %>
    boxes.forEach(b => b.classList.add('error'));
    setTimeout(() => boxes.forEach(b => { b.classList.remove('error'); b.value = ''; }), 400);
    boxes[0].focus();
    <% } %>
</script>

</body>
</html>
