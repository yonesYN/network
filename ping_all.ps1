mode con: cols=40 lines=20
$servers = @(
    "hybrid.roboping.ir",
    "germany.roboping.ir", 
    "download.roboping.ir",
    "turkiye.roboping.ir",
    "russia.roboping.ir",
    "goethe.roboping.ir",
    "oman.roboping.ir",
    "izmir.roboping.ir",
    "uae.roboping.ir",
    "uk.roboping.ir",
    "usa.roboping.ir"
)

$previousPingTimes = @{}

function PingServer {
    param([string]$Server)
    try {
        $response = Test-Connection -ComputerName $Server -Count 1 -ErrorAction Stop
        $pingTime = $response.ResponseTime
        $previousTime = $previousPingTimes[$Server]

		$color = if ($pingTime -gt 190) { 
            'Yellow'
        } elseif ($previousTime -and [Math]::Abs($pingTime - $previousTime) -gt 18) {
            'Yellow'
        } else { 
            'White'
        }

        Write-Host "$Server	${pingTime}ms" -ForegroundColor $color
        $previousPingTimes[$Server] = $pingTime
    }
    catch {
        Write-Host "$Server" -ForegroundColor Red
        $previousPingTimes[$Server] = $null
    }
}

while ($true) {
    Clear-Host
    Write-Host "========================" -ForegroundColor Cyan
    foreach ($server in $servers) {
        PingServer -Server $server
    }
    Start-Sleep -Seconds 4
}

