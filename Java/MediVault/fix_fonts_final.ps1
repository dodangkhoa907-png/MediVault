$ErrorActionPreference = "Stop"
$enc = New-Object System.Text.UTF8Encoding($false)
$jspsDir = "d:\H2NO3\My STUDY\DO_AN_TOT_NGHIEP\MediVault\Java\MediVault\src\main\webapp\WEB-INF\views"

$files = Get-ChildItem -Path $jspsDir -Recurse -Filter "*.jsp"
$count = 0

foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $original = $c
    $changed = $false

    # --- 1. Loại bỏ link style.css không tồn tại ---
    if ($c -match '<link[^>]*assets/css/style\.css[^>]*>') {
        $c = $c -replace '<link[^>]*assets/css/style\.css[^>]*>', ''
        $changed = $true
    }

    # --- 2. Thay Outfit -> Inter trong Google Fonts URL ---
    if ($c -match "family=Outfit") {
        $c = $c -replace "family=Outfit[^&`"]*", "family=Inter:wght@300;400;500;600;700;800;900"
        $changed = $true
    }

    # --- 3. Thay font-family Outfit -> Inter trong CSS ---
    if ($c -match "'Outfit'") {
        $c = $c -replace "'Outfit'", "'Inter'"
        $changed = $true
    }
    if ($c -match '"Outfit"') {
        $c = $c -replace '"Outfit"', '"Inter"'
        $changed = $true
    }

    # --- 4. Xóa dòng pageEncoding bị thêm trùng (trường hợp script cũ thêm cả dòng mới ở đầu) ---
    # Pattern: file bắt đầu bằng dòng <%@ page ...pageEncoding... %> rồi ngay sau đó lại có <%@ page ... %>
    # Xóa dòng đầu nếu là dòng page directive trùng
    $lines = $c -split "`r`n"
    if ($lines.Count -ge 2) {
        $line0 = $lines[0].Trim()
        $line1 = $lines[1].Trim()
        # Nếu cả 2 dòng đầu đều là <%@ page ... %>
        if ($line0 -match "<%@\s*page" -and $line1 -match "<%@\s*page") {
            # Xóa dòng 0 nếu nó là dòng được thêm vào (chỉ có contentType và pageEncoding)
            # và dòng 1 đã có contentType
            if ($line0 -match 'contentType' -and $line1 -match 'contentType') {
                # Merge: giữ dòng 1 nhưng thêm pageEncoding vào nó nếu chưa có
                if ($line1 -notmatch 'pageEncoding') {
                    $lines[1] = $lines[1] -replace '%>', ' pageEncoding="UTF-8" %>'
                }
                $lines = $lines[1..($lines.Count-1)]
                $c = $lines -join "`r`n"
                $changed = $true
            }
        }
    }

    # --- 5. Đảm bảo có pageEncoding UTF-8 trong <%@ page %> ---
    if ($c -match "contentType") {
        if ($c -notmatch 'pageEncoding') {
            # Thêm pageEncoding vào dòng <%@ page ... %> đầu tiên
            $c = $c -replace '(%>)', ' pageEncoding="UTF-8" %>', 1
            $changed = $true
        }
    }

    # --- 6. Đảm bảo inject CSS body chuẩn nếu có </style> + </head> ---
    # Chỉ inject nếu chưa có
    if ($c -match "</style>" -and $c -match "</head>" -and $c -notmatch "font-family: 'Inter'!important" -and $c -notmatch "font-family:'Inter',sans-serif!important") {
        # Kiểm tra xem đã có inject chưa
        if ($c -notmatch "line-height: 1.6 !important" -and $c -notmatch "line-height:1.6!important") {
            # Tìm lần </style> cuối cùng trước </head> để inject
            $injectCss = @"
h1,h2{font-family:'Inter',sans-serif!important;font-weight:800!important;letter-spacing:-.5px!important}
p{font-family:'Inter',sans-serif!important;font-weight:400!important;line-height:1.6!important}
i{color:#6b7280!important;font-style:italic!important}
</style>
</head>
"@
            # Thay </style>\r\n</head> hoặc </style>\n</head>
            if ($c -match "</style>\r\n</head>") {
                $c = $c -replace "</style>\r\n</head>", $injectCss
                $changed = $true
            } elseif ($c -match "</style>\n</head>") {
                $c = $c -replace "</style>\n</head>", $injectCss
                $changed = $true
            }
        }
    }

    if ($changed) {
        [System.IO.File]::WriteAllText($f.FullName, $c, $enc)
        $count++
    }
}

Write-Host "Done. Updated $count files."
