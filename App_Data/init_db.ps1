# Tự động nạp dữ liệu chuẩn Unicode tiếng Việt bằng SeedDatabase.exe
$seedExe = Join-Path $PSScriptRoot "SeedDatabase.exe"
if (Test-Path $seedExe) {
    & $seedExe
} else {
    $sqlFile = Join-Path $PSScriptRoot "..\Database.sql"
    $sql = [System.IO.File]::ReadAllText($sqlFile, [System.Text.Encoding]::UTF8)
    $conn = New-Object System.Data.SqlClient.SqlConnection('Server=(localdb)\MSSQLLocalDB;Integrated Security=true;')
    $conn.Open()
    $batches = $sql -split '(?m)^\s*GO\s*$'
    foreach ($b in $batches) {
        if ($b.Trim()) {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $b
            [void]$cmd.ExecuteNonQuery()
        }
    }
    $conn.Close()
    Write-Output "Database re-initialized from Database.sql successfully!"
}
