$SoftwareName = "Software Name" # change to the software you want to track

Function Test-SoftInstalled {
    Param ([string]$Name)
    $RegKeys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", 
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $KeyExists = $false
    ForEach ($RegKey in $RegKeys) {
        $DisplayName = Get-ItemProperty -Path $RegKey -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "$($Name)*" }
        if ($null -ne $DisplayName) {
            $KeyExists = $true
            break
        }
    }

    Return $KeyExists
}

$SoftwareStatus = Test-SoftInstalled -Name $SoftwareName
$SoftwareStatusText = if ($SoftwareStatus) { 'Installed' } else { 'Not Installed' }

Action1-Set-CustomAttribute $SoftwareName $SoftwareStatusText;