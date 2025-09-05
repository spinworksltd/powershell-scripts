$disks = Get-PhysicalDisk | Where-Object { $_.BusType -ne "USB" }

if ($disks.Count -eq 0) {
    Write-Output "No internal disks found"
    exit 1
}

$unhealthy = $disks | Where-Object { $_.HealthStatus -ne "Healthy" }

if ($unhealthy.Count -eq 0) {
    Action1-Set-CustomAttribute 'HDD Health' 'OK';
} else {
    Action1-Set-CustomAttribute 'HDD Health' 'BAD';
}