# Server Ping Test Script
$servers = @(
    "hybrid.roboping.ir",
    "germany.roboping.ir", 
    "oman.roboping.ir",
    "download.roboping.ir",
    "turkiye.roboping.ir",
    "uae.roboping.ir",
    "russia.roboping.ir",
    "uk.roboping.ir",
    "usa.roboping.ir",
    "goethe.roboping.ir",
    "izmir.roboping.ir"
)

function Test-ServerPing {
    param([string]$Server)
    
    try {
        $ping = Test-Connection -ComputerName $Server -Count 1 -Quiet -ErrorAction Stop
        if ($ping) {
            $response = Test-Connection -ComputerName $Server -Count 1 -ErrorAction Stop
            $pingTime = $response.ResponseTime
            Write-Host "$Server - ${pingTime}ms" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "$Server - Timeout" -ForegroundColor Red
    }
}

Write-Host "============================" -ForegroundColor Cyan

foreach ($server in $servers) {
    Test-ServerPing -Server $server
}

