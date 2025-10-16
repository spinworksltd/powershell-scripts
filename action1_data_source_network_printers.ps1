$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

function Get-MacFromIP {
    param($IP)
    if (-not $IP) { return $null }
    try { Test-Connection -Count 1 -Quiet -ComputerName $IP -ErrorAction SilentlyContinue | Out-Null } catch {}
    try {
        $n = Get-NetNeighbor -AddressFamily IPv4 -IPAddress $IP -ErrorAction SilentlyContinue
        if ($n -and $n.LinkLayerAddress) { return ($n.LinkLayerAddress -replace ':','-').ToUpper() }
    } catch {}
    try {
        $arp = arp -a 2>$null
        if ($arp -match "$IP\s+([0-9a-fA-F\.\:-]{11,17})") {
            $mac = $Matches[1]
            return ($mac -replace '\.', '-' -replace ':', '-' ).ToUpper()
        }
    } catch {}
    return $null
}

function Get-PrinterIPFromPortName {
    param($PortName)
    if (-not $PortName) { return $null }
    if ($PortName -match '((?:\d{1,3}\.){3}\d{1,3})') { return $Matches[1] }
    if ($PortName -match 'socket://([^:\/]+)') { return $Matches[1] }
    if ($PortName -match '^[a-zA-Z0-9\-.]+$') {
        try {
            $addrs = [System.Net.Dns]::GetHostAddresses($PortName) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
            if ($addrs) { return $addrs[0].IPAddressToString }
        } catch {}
    }
    return $null
}

function Get-DeterministicKey {
    param($s)
    if (-not $s) { $s = (Get-Random -Maximum 9999999).ToString() }
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
    $hash = $md5.ComputeHash($bytes)
    $hex = ([System.BitConverter]::ToString($hash)).Replace('-','').ToLower()
    return "A1_$hex"
}

# --- Collect printers (suppress any formatting) ---
try {
    $printers = Get-Printer -ErrorAction Stop
} catch {
    $printers = Get-CimInstance -ClassName Win32_Printer -ErrorAction SilentlyContinue
}

try { $printerPorts = Get-PrinterPort -ErrorAction SilentlyContinue } catch { $printerPorts = @() }
try { $tcpipPorts = Get-CimInstance -ClassName Win32_TCPIPPrinterPort -ErrorAction SilentlyContinue } catch { $tcpipPorts = @() }

$results = @()

foreach ($p in $printers) {
    $name     = ($p.Name) -as [string]
    $driver   = ($p.DriverName) -as [string]
    $portName = ($p.PortName) -as [string]
    $deviceId = ($p.DeviceId) -as [string]
    $status = $null
    if ($p.PrinterStatus -ne $null) { $status = $p.PrinterStatus }

    $ip = $null; $mac = $null; $snmp = $null

    if ($portName) {
        try { $pp = $printerPorts | Where-Object { $_.Name -eq $portName } | Select-Object -First 1 } catch { $pp = $null }
        if ($pp -and $pp.PrinterHostAddress) { $ip = $pp.PrinterHostAddress }
    }

    if (-not $ip -and $portName -and $tcpipPorts) {
        try { $tcp = $tcpipPorts | Where-Object { $_.Name -eq $portName -or $_.PortName -eq $portName } | Select-Object -First 1 } catch { $tcp = $null }
        if ($tcp) {
            if ($tcp.HostAddress) { $ip = $tcp.HostAddress }
            if ($tcp.PSObject.Properties.Match('SNMPEnabled').Count -gt 0 -and $tcp.SNMPEnabled -ne $null) { $snmp = [bool]$tcp.SNMPEnabled }
        }
    }

    if (-not $ip -and $portName) { $ip = Get-PrinterIPFromPortName -PortName $portName }

    if (-not $ip -and $portName) {
        try {
            $addrs = [System.Net.Dns]::GetHostAddresses($portName) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
            if ($addrs) { $ip = $addrs[0].IPAddressToString }
        } catch {}
    }

    if (-not $ip) { continue }

    $mac = Get-MacFromIP -IP $ip

    $obj = [PSCustomObject]@{
        PrinterName   = $name
        DeviceID      = $deviceId
        DriverName    = $driver
        IPAddress     = $ip
        MacAddress    = $mac -replace '-', ':'
        SNMPEnabled   = $snmp
        PrinterStatus = $status
        A1_Key        = Get-DeterministicKey -s $ip
    }

    $results += $obj
}

$results