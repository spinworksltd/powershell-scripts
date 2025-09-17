$locals = Get-LocalGroupMember -Group "Administrators" |
    Where-Object { $_.PrincipalSource -eq 'Local' -and $_.ObjectClass -eq 'User' } |
    ForEach-Object {
        $user = [ADSI]"WinNT://$($_.Name)"
        if (($user.UserFlags -band 2) -eq 0) { $_.Name }
    }

$result = $locals -join ","

Action1-Set-CustomAttribute 'Local Admins' $result;
