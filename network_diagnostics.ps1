<#
.NOTES
    Author         : yonesYN
    GitHub         : https://github.com/yonesYN
    Version        : 1.1
#>


$gg = [bool](whoami /groups | findstr "S-1-5-32-544")
$ee = [bool](whoami /groups | findstr "S-1-16-12288")

$agroup = whoami /groups | Select-String "S-1-16-"
switch -Wildcard ($agroup.ToString()) {
    "*S-1-16-12288*" { $ll = "Admin" }
    "*S-1-16-8192*"  { $ll = "User" }
    "*S-1-16-16384*" { $ll = "System" }
    "*S-1-16-4096*"  { $ll = "Low" }
    "*S-1-16-20480*" { $ll = "Protected Process" }
    Default          { $ll = "Unknown" }
}

$services = @(
    'nsi',
    'msiserver',
    'RpcSs',
    'PlugPlay',
    'RpcLocator',
    'Netman',
    'Dhcp',
    'WlanSvc',
    'WwanSvc',
    'NlaSvc',
    'netprofm',
    'RmSvc',
    'DsmSvc',
    'DeviceInstall',
	'W32Time'
)

$svcs2 = @(
    'nsi',
    'Dhcp',
    'netprofm',
    'PlugPlay',
    'RpcSs',
    'NlaSvc'
)

Write-Host "`n=== GENERAL ===" -ForegroundColor Cyan
$robo = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -like "*Roboping*" | Select-Object -ExpandProperty InstallLocation

if ($robo) {
    Write-Host "$path"
} else {
    Write-Host "Not found" -ForegroundColor red
}

Write-Host "`nAdminGroup: $gg" -ForegroundColor $(if ($gg) { "Green" } else { "Red" })
Write-Host "elevated: $ee"
Write-Host "Level: $ll"

Write-Host "`n=== INTERFACE ===" -ForegroundColor Cyan
$adapters = Get-NetAdapter -ErrorAction SilentlyContinue

if ($adapters) {
    $adapters = $adapters | Sort-Object InterfaceIndex

    foreach ($adapter in $adapters) {
        $color = if ($adapter.Status -eq "Up") { "Green" } else { "White" }

        $ip = Get-NetIPAddress -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
        $ipAddress = if ($ip) { ($ip.IPAddress -join ", ") } else { "No-IP" }

        Write-Host "$($adapter.Name): $ipAddress [$($adapter.InterfaceDescription)]" -ForegroundColor $color
    }
} else {
    Write-Host "No adapters found" -ForegroundColor Red
}

Write-Host "`n=== Public-IP ===" -ForegroundColor Cyan
try {
    $trace = Invoke-WebRequest "https://cloudflare.com/cdn-cgi/trace" -UseBasicParsing
    $data = ConvertFrom-StringData $trace.Content
    $loc = if ($data.loc) { $data.loc } else { "Unknown" }
    $color = if ($data.loc -eq "IR") { "Green" } else { "Yellow" }
    Write-Host "IP: $($data.ip) $loc" -ForegroundColor $color
} catch {
    Write-Host "Unable to retrieve"
}

Write-Host "`n=== DNS SETTINGS ===" -ForegroundColor Cyan
$dnsSettings = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses }
if ($dnsSettings) {
    foreach ($dns in $dnsSettings) {
        $dnsServer = $dns.ServerAddresses -join ', '
        Write-Host "$($dns.InterfaceAlias): $dnsServer"
    }
} else {
    Write-Host "No DNS found" -ForegroundColor Red
}

try {
    Resolve-DnsName google.com -ErrorAction Stop | Out-Null
    Write-Host "`nDNS: Working" -ForegroundColor Green
} catch {
    Write-Host "`nDNS: Failed" -ForegroundColor Red
}

Write-Host "`n=== NETWORK LATENCY ===" -ForegroundColor Cyan

try {
    Test-Connection 4.2.2.4 -Count 1 -ErrorAction Stop | Out-Null
    $pingResults = Test-Connection 4.2.2.4 -Count 9 -Delay 1 -ErrorAction SilentlyContinue
} catch {
    Write-Host "Unable to test" -ForegroundColor Red
}

$successPings = @($pingResults | Where-Object { $_.ResponseTime -ne $null })
if ($successPings.Count -eq 0) {
    Write-Host "Timeout" -ForegroundColor Red
} else {
    $avgPing = [math]::Round(($successPings.ResponseTime | Measure-Object -Average).Average)
    $maxPing = ($successPings.ResponseTime | Measure-Object -Maximum).Maximum
    $differ = [math]::Abs($avgPing - $maxPing)

    $color = if ($successPings.Count -lt 9) { "Red" } elseif ($maxPing -gt 250 -or $differ -gt 19) { "Yellow" } else { "Green" }
    Write-Host "latency: ${avgPing}ms" -ForegroundColor $color
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
        Write-Host "Defender module not Working" -ForegroundColor Red
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

Write-Host "`n=== SERVICES ===" -ForegroundColor Cyan

foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.StartType -eq 'Disabled') {
            Write-Host "$($svc.DisplayName) : Disabled" -ForegroundColor Red
        } elseif ($svcs2 -contains $service -and $svc.Status -ne 'Running') {
            Write-Host "$($svc.DisplayName) : $($svc.Status)" -ForegroundColor Magenta
        }
    } else {
        Write-Host "XXX $service XXX" -ForegroundColor DarkRed
    }
}

Write-Host "`n=== FIREWALL ===" -ForegroundColor Cyan

$path = "C:\Windows\System32\drivers\etc\hosts"

if (Test-Path $path) {
    Get-Content $path | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^\s*#' }
} else {
    Write-Host "Hosts file not found" -ForegroundColor Red
}

Get-NetFirewallProfile | Select-Object Name, Enabled
