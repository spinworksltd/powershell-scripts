# Disable ALL network adapters
Get-NetAdapter | Disable-NetAdapter -Confirm:$false