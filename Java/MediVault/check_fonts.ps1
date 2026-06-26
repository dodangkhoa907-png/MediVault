$jspsDir = "d:\H2NO3\My STUDY\DO_AN_TOT_NGHIEP\MediVault\Java\MediVault\src\main\webapp\WEB-INF\views"
$enc = [System.Text.Encoding]::UTF8

$files = Get-ChildItem -Path $jspsDir -Recurse -Filter "*.jsp"
$issues = @()
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, $enc)
    $hasOutfit = $c.Contains("family=Outfit") -or $c.Contains("Outfit',sans-serif") -or $c.Contains("Outfit', sans-serif") -or $c.Contains("'Outfit'")
    $missingInter = -not $c.Contains("Inter")
    $missingPageEnc = ($c -match "contentType=.text/html") -and (-not $c.Contains("pageEncoding"))
    if ($hasOutfit -or ($missingInter -and ($c -match "font-family"))) {
        $issues += $f.FullName
    }
}
Write-Host "Files still using Outfit / missing Inter:"
$issues | ForEach-Object { Write-Host "  $_" }
Write-Host "`nTotal: $($issues.Count)"
