$BitlockerStatus = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
$BitlockerStatusText = if ($BitlockerStatus) { $BitlockerStatus.ProtectionStatus.ToString() } else { "none" }

Action1-Set-CustomAttribute "BitLocker" "$BitlockerStatusText";