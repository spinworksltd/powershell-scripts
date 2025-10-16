$IPType = "IPv4"
# Get the main network adapter (first connected adapter that's not virtual)
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike "*Virtual*" -and $_.InterfaceDescription -notlike "*Tunnel*" } | Select-Object -First 1
$interface = $adapter | Get-NetIPInterface -AddressFamily $IPType

If ($interface -and $interface.Dhcp -eq "Disabled") {
    # Enable DHCP
    $interface | Set-NetIPInterface -DHCP Enabled
    # Configure the DNS Servers automatically
    $interface | Set-DnsClientServerAddress -ResetServerAddresses

    Write-Host "Network adapter reset to DHCP completed!" -ForegroundColor Green
} else {
    Write-Host "No suitable network adapter found." -ForegroundColor Red
}