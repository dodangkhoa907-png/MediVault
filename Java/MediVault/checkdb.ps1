$conn = New-Object System.Data.SqlClient.SqlConnection("Server=14.225.217.109;Database=PharmacyPro_DB;User Id=sa;Password=TOP1@iyounguru!;Encrypt=True;TrustServerCertificate=True;")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT TOP 1 CategoryName FROM Categories"
$reader = $cmd.ExecuteReader()
$reader.Read() | Out-Null
Write-Output "Category: $($reader.GetString(0))"
$conn.Close()




