$DiskDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

# Create a readable output of disk drives and their free space
$DiskStatusText = $DiskDrives | ForEach-Object {
    $FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2) # Convert free space to gigabytes and round to two decimals
    "$($_.DeviceID) $FreeSpaceGB GB"
}

# Output all disk drives and their free space
$OutputText = $DiskStatusText -join '; '

Action1-Set-CustomAttribute 'Free HDD' $OutputText;