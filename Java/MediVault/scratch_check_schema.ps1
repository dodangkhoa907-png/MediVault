$conn = New-Object System.Data.SqlClient.SqlConnection("Server=14.225.217.109;Database=PharmacyPro_DB;User Id=sa;Password=TOP1@iyounguru!;Encrypt=True;TrustServerCertificate=True;")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    Write-Output "Table: $($reader.GetValue(0))"
}
$conn.Close()
