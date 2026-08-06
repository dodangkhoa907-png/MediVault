$jars = Get-ChildItem -Recurse "$env:USERPROFILE\.m2\repository\*.jar" | Select-Object -ExpandProperty FullName
$localJars = Get-ChildItem -Recurse "lib\*.jar" | Select-Object -ExpandProperty FullName
$allJars = @($localJars + $jars + "target/classes") -join ";"
Set-Content -Path "options.txt" -Value "-encoding`nUTF-8`n-cp`n$allJars`n-d`ntarget/classes"
Get-ChildItem -Recurse "src/main/java/*.java" | Select-Object -ExpandProperty FullName | Out-File -Encoding ascii sources.txt
cmd /c javac `@options.txt `@sources.txt
if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilation SUCCESSFUL!" -ForegroundColor Green
    if (Test-Path "target/MediVault-1.0-SNAPSHOT/WEB-INF/classes") {
        Copy-Item -Recurse -Force target/classes/* target/MediVault-1.0-SNAPSHOT/WEB-INF/classes/
        Write-Host "Copied compiled classes to Tomcat deployment directory!" -ForegroundColor Green
    }
} else {
    Write-Host "Compilation FAILED!" -ForegroundColor Red
}
