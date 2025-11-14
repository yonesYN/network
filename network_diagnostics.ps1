
Write-Host "`n=== InstallLocation ===" -ForegroundColor Cyan
$path = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -like "*Roboping*" | Select-Object -ExpandProperty InstallLocation -ErrorAction SilentlyContinue

if ($path) {
    Write-Host "$path"
} else {
    Write-Host "Not found" -ForegroundColor red
}

Write-Host "`n=== INTERFACE ===" -ForegroundColor Cyan
$adapters = Get-NetAdapter | Sort-Object InterfaceIndex
foreach ($adapter in $adapters) {
    $color = if ($adapter.Status -eq "Up") { "Green" } else { "White" }
    $ip = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $ipAddress = if ($ip) { $ip.IPAddress } else { "No-IP" }
    Write-Host "$($adapter.Name): $ipAddress `"$($adapter.InterfaceDescription)`", " -ForegroundColor $color
}

Write-Host "`n=== Public-IP ===" -ForegroundColor Cyan

try {
    $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Write-Host "Public-IP: $publicIP"
} catch {
    Write-Host "Public-IP: Unable to retrieve"
}


Write-Host "`n=== DNS SETTINGS ===" -ForegroundColor Cyan
$dnsSettings = Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 -and $_.ServerAddresses }

foreach ($dns in $dnsSettings) {
    $dnsServers = $dns.ServerAddresses -join ','
    Write-Host "$($dns.InterfaceAlias) `"$dnsServers`", " -NoNewline
}
Write-Host " "
try {
    Resolve-DnsName google.com -ErrorAction Stop | Out-Null
    Write-Host "DNS Resolution: Working" -ForegroundColor Green
} catch {
    Write-Host "DNS Resolution: Failed" -ForegroundColor Red
}

Write-Host "`n=== NETWORK LATENCY ===" -ForegroundColor Cyan

try {
    $pingResults = Test-Connection 4.2.2.4 -Count 9 -ErrorAction Stop
    $successPings = $pingResults | Where-Object { $_.ResponseTime -ne $null }
	
    if ($successPings.Count -eq 0) {
        Write-Host "latency: Timeout" -ForegroundColor Red
    } else {
        $avgPing = [math]::Round(($successPings.ResponseTime | Measure-Object -Average).Average)
        $maxPing = ($successPings.ResponseTime | Measure-Object -Maximum).Maximum
        $lostPackets = 9 - $successPings.Count

        if ($maxPing -gt 230 -or $lostPackets -gt 0) {
            Write-Host "latency: ${avgPing}ms 'packet lost'" -ForegroundColor Yellow
        } else {
            Write-Host "latency: ${avgPing}ms" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "latency: Unable to test" -ForegroundColor Red
}

Write-Host "`n=== PROXY STATUS ===" -ForegroundColor Cyan
netsh winhttp show proxy

Write-Host "`n=== WINDOWS DEFENDER STATUS ===" -ForegroundColor Cyan
if (Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    $def = Get-MpComputerStatus
    Write-Host "Real-time Protection Enabled:" $def.RealTimeProtectionEnabled
    Write-Host "Antispyware Enabled:" $def.AntispywareEnabled
    Write-Host "Antivirus Enabled:" $def.AntivirusEnabled
} else {
    Write-Host "Windows Defender module not available"
}

Write-Host "`n=== OTHER ANTIVIRUS ===" -ForegroundColor Cyan
$otherAV = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
if ($otherAV) {
    $otherAV | ForEach-Object { 
        Write-Host "AV Product: $($_.displayName) (State: $($_.productState))" 
    }
} else {
    Write-Host "No antivirus"
}

Write-Host "`n=== FIREWALL STATUS ===" -ForegroundColor Cyan
Get-NetFirewallProfile | Select-Object Name, Enabled
