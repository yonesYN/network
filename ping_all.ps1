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

function PingServer {
    param([string]$Server)
    
    try {
        $response = Test-Connection -ComputerName $Server -Count 1 -ErrorAction Stop
        $pingTime = $response.ResponseTime
        
        $color = if ($pingTime -gt 180) { 'Yellow' } else { 'White' }
        Write-Host "$Server - ${pingTime}ms" -ForegroundColor $color
    }
    catch {
        Write-Host "$Server" -ForegroundColor Red
    }
}

foreach ($server in $servers) {
    PingServer -Server $server
}
