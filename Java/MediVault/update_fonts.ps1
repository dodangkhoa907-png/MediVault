$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Path "d:\H2NO3\My STUDY\DO_AN_TOT_NGHIEP\MediVault\Java\MediVault\src\main\webapp\WEB-INF\views" -Recurse -Filter *.jsp

$css = @"
<style>
h1, h2, title, .table-card-title, .page-head-left h1, .sm-title { font-family: 'Inter', sans-serif !important; font-weight: 800 !important; letter-spacing: -0.5px !important; }
p { font-weight: 400 !important; line-height: 1.6 !important; }
i { color: #6b7280 !important; font-style: italic !important; }
</style>
</head>
"@

$count = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $modified = $false

    # Fix pageEncoding
    if ($content -match '<%@\s*page\s+contentType="text/html;\s*charset=UTF-8"\s*%>') {
        $content = $content -replace '<%@\s*page\s+contentType="text/html;\s*charset=UTF-8"\s*%>', '<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>'
        $modified = $true
    } elseif ($content -notmatch 'pageEncoding="UTF-8"') {
        $content = '<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>' + "`r`n" + $content
        $modified = $true
    }

    # Replace Font URL
    if ($content -match "family=Outfit") {
        $content = $content -replace "family=Outfit[^\`"]*", "family=Inter:wght@300;400;500;600;700;800;900&display=swap"
        $modified = $true
    }

    # Replace Font Family
    if ($content -match "'Outfit'") {
        $content = $content -replace "'Outfit'", "'Inter'"
        $modified = $true
    }
    
    # Inject CSS before </head>
    if ($content -match "</head>" -and $content -notmatch "font-family: 'Inter'") {
        $content = $content -replace "</head>", $css
        $modified = $true
    }

    if ($modified) {
        [System.IO.File]::WriteAllText($file.FullName, $content, (New-Object System.Text.UTF8Encoding($false)))
        $count++
    }
}

Write-Host "Updated $count files."
