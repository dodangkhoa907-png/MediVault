$conn = New-Object System.Data.SqlClient.SqlConnection("Server=14.225.217.109;Database=PharmacyPro_DB;User Id=sa;Password=TOP1@iyounguru!;Encrypt=True;TrustServerCertificate=True;")
$conn.Open()
Write-Output "Connected to DB..."

function Get-Val { param($reader, $index) if ($reader.IsDBNull($index)) { return $null } else { return $reader.GetString($index) } }

function Get-Param { param($val) if ($val -eq $null) { return [System.DBNull]::Value } else { return $val } }

$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT CategoryId, CategoryName, Description FROM Categories"
$reader = $cmd.ExecuteReader()

$catUpdates = @()
while ($reader.Read()) {
    $id = $reader.GetInt32(0)
    $name = Get-Val $reader 1
    $desc = Get-Val $reader 2
    $changed = $false
    
    if ($name -ne $null) {
        $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($name)
        $r = [System.Text.Encoding]::UTF8.GetString($bytes)
        if (-not $r.Contains("") -and $r -ne $name) { $name = $r; $changed = $true }
    }
    if ($desc -ne $null) {
        $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($desc)
        $r = [System.Text.Encoding]::UTF8.GetString($bytes)
        if (-not $r.Contains("") -and $r -ne $desc) { $desc = $r; $changed = $true }
    }
    if ($changed) { $catUpdates += @{ id=$id; name=$name; desc=$desc } }
}
$reader.Close()

foreach ($u in $catUpdates) {
    Write-Output "Fixing Category: $($u.name)"
    $upd = $conn.CreateCommand()
    $upd.CommandText = "UPDATE Categories SET CategoryName=@name, Description=@desc WHERE CategoryId=@id"
    $upd.Parameters.AddWithValue("@name", (Get-Param $u.name)) | Out-Null
    $upd.Parameters.AddWithValue("@desc", (Get-Param $u.desc)) | Out-Null
    $upd.Parameters.AddWithValue("@id", $u.id) | Out-Null
    $upd.ExecuteNonQuery() | Out-Null
}

$cmd.CommandText = "SELECT MedicineId, MedicineName, GenericName, Unit, Dosage, StorageConditions, Contraindications FROM Medicines"
$reader = $cmd.ExecuteReader()

$medUpdates = @()
while ($reader.Read()) {
    $id = $reader.GetInt32(0)
    $vals = @($null, $null, $null, $null, $null, $null)
    $changed = $false
    for ($i=0; $i -lt 6; $i++) {
        $val = Get-Val $reader ($i+1)
        $vals[$i] = $val
        if ($val -ne $null) {
            $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($val)
            $r = [System.Text.Encoding]::UTF8.GetString($bytes)
            if (-not $r.Contains("") -and $r -ne $val) {
                $vals[$i] = $r; $changed = $true
            }
        }
    }
    if ($changed) { $medUpdates += @{ id=$id; vals=$vals } }
}
$reader.Close()

foreach ($m in $medUpdates) {
    Write-Output "Fixing Medicine: $($m.vals[0])"
    $upd = $conn.CreateCommand()
    $upd.CommandText = "UPDATE Medicines SET MedicineName=@v1, GenericName=@v2, Unit=@v3, Dosage=@v4, StorageConditions=@v5, Contraindications=@v6 WHERE MedicineId=@id"
    $upd.Parameters.AddWithValue("@v1", (Get-Param($m.vals[0]))) | Out-Null
    $upd.Parameters.AddWithValue("@v2", (Get-Param($m.vals[1]))) | Out-Null
    $upd.Parameters.AddWithValue("@v3", (Get-Param($m.vals[2]))) | Out-Null
    $upd.Parameters.AddWithValue("@v4", (Get-Param($m.vals[3]))) | Out-Null
    $upd.Parameters.AddWithValue("@v5", (Get-Param($m.vals[4]))) | Out-Null
    $upd.Parameters.AddWithValue("@v6", (Get-Param($m.vals[5]))) | Out-Null
    $upd.Parameters.AddWithValue("@id", $m.id) | Out-Null
    $upd.ExecuteNonQuery() | Out-Null
}

$conn.Close()
Write-Output "Fixed $($catUpdates.Length) categories and $($medUpdates.Length) medicines."
