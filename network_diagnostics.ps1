
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
    Write-Host "$($adapter.Name): $ipAddress `"$($adapter.InterfaceDescription)`" " -ForegroundColor $color
}

Write-Host "`n=== Public-IP ===" -ForegroundColor Cyan
try {
    $trace = Invoke-WebRequest "https://cloudflare.com/cdn-cgi/trace" -UseBasicParsing -TimeoutSec 5
    $data = ConvertFrom-StringData $trace.Content
	$loc = if ($data.loc) { $data.loc } else { "Unknown" }
    $color = if ($data.loc -eq "IR") { "Green" } else { "Yellow" }
    Write-Host "IP: $($data.ip) $loc" -ForegroundColor $color
} catch {
    Write-Host "Unable to retrieve"
}

Write-Host "`n=== DNS SETTINGS ===" -ForegroundColor Cyan
$dnsSettings = Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 -and $_.ServerAddresses }

foreach ($dns in $dnsSettings) {
    $dnsServers = $dns.ServerAddresses -join ','
    Write-Host "$($dns.InterfaceAlias) `"$dnsServers`", " -NoNewline
}

try {
    Resolve-DnsName google.com -ErrorAction Stop | Out-Null
    Write-Host "`nDNS: Working" -ForegroundColor Green
} catch {
    Write-Host "`nDNS: Failed" -ForegroundColor Red
}

Write-Host "`n=== NETWORK LATENCY ===" -ForegroundColor Cyan

try {
    $pingResults = Test-Connection 4.2.2.4 -Count 9 -Delay 1 -ErrorAction Stop

    $successPings = @($pingResults | Where-Object { $_.ResponseTime -ne $null })

    if ($successPings.Count -eq 0) {
        Write-Host "latency: Timeout" -ForegroundColor Red
    }
    else {
        $avgPing = [math]::Round(($successPings.ResponseTime | Measure-Object -Average).Average)
        $maxPing = ($successPings.ResponseTime | Measure-Object -Maximum).Maximum
        $lostPackets = 9 - $successPings.Count
        $differ = [math]::Abs($avgPing - $maxPing)

        if ($maxPing -gt 300 -or $lostPackets -gt 0 -or $differ -gt 20) {
            Write-Host "latency: ${avgPing}ms (issues detected)" -ForegroundColor Yellow
        }
        else {
            Write-Host "latency: ${avgPing}ms" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "Unable to test" -ForegroundColor Red
}

Write-Host "`n=== PROXY STATUS ===" -ForegroundColor Cyan
netsh winhttp show proxy

Write-Host "`n=== DEFENDER STATUS ===" -ForegroundColor Cyan
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $def = Get-MpComputerStatus -ErrorAction Stop
        Write-Host "Real-time Protection:" $def.RealTimeProtectionEnabled
        Write-Host "Antispyware:" $def.AntispywareEnabled
        Write-Host "Antivirus:" $def.AntivirusEnabled
	} catch {
        Write-Host "Defender module not available" -ForegroundColor Red
	}
} else {
    Write-Host "Defender module not available"
}

Write-Host "`n=== OTHER ANTIVIRUS ===" -ForegroundColor Cyan
$otherAV = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
if ($otherAV) {
    $otherAV | ForEach-Object {
        Write-Host "AV: $($_.displayName) (State: $($_.productState))" 
    }
} else {
    Write-Host "No antivirus"
}

try {
    $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
    $tpm = Get-Tpm
    $color = if ($secureBoot -eq "True") { "White" } else { "Red" }
    Write-Host "`nSecureBoot: $secureBoot`nTPM: $($tpm.TpmReady) $($tpm.TpmEnabled) $($tpm.TpmActivated)" -ForegroundColor $color
} catch {
    Write-Host "`nUnable to get SecureBoot" -ForegroundColor Red
}

Write-Host "`n=== FIREWALL STATUS ===" -ForegroundColor Cyan
Get-NetFirewallProfile | Select-Object Name, Enabled
