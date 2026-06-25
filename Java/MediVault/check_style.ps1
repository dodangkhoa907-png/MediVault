$enc = [System.Text.Encoding]::UTF8
$files = Get-ChildItem -Path "src\main\webapp\WEB-INF\views" -Recurse -Filter "*.jsp"
$issues = @()
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, $enc)
    if ($c.Contains("assets/css/style.css")) {
        $issues += $f.FullName
    }
}
if ($issues.Count -eq 0) { Write-Host "OK: No leftover style.css links." }
else { Write-Host "STILL HAS style.css:"; $issues | ForEach-Object { Write-Host "  $_" } }
