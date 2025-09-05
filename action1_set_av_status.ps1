# define bit flags
 
[Flags()] enum ProductState 
{
      Off         = 0x0000
      On          = 0x1000
      Snoozed     = 0x2000
      Expired     = 0x3000
}
 
[Flags()] enum SignatureStatus
{
      UpToDate     = 0x00
      OutOfDate    = 0x10
}
 
# define bit masks
 
[Flags()] enum ProductFlags
{
      SignatureStatus = 0x00F0
      ProductOwner    = 0x0F00
      ProductState    = 0xF000
}
 
# get bits
$infos = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
:avSearch ForEach ($info in $infos){
    [UInt32]$state = $info.productState
    $productState = [ProductState]($state -band [ProductFlags]::ProductState)
    if ( 'off' -ne $productState )
    {
        $signatureStatus = [SignatureStatus]($state -band [ProductFlags]::SignatureStatus)
        Action1-Set-CustomAttribute 'Antivirus' "$($info.DisplayName) ($($signatureStatus))";
        break avSearch
    }
}