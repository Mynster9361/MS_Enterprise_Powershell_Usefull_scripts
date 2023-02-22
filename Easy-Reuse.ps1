function addToArray_example() {
    $result = @()
    $result += New-Object -TypeName PSObject -Property ([ordered]@{
            'ADGroup'       = ""
            'Creation Date' = ""
            'Description'   = ""
            'Members'       = $memberName
            'objectClass'   = $memberObject
        })
}

function ADCommands_examples() {
    # Filter ad objects so we only get those where the ObjectClass is eq to a group
    Get-ADObject -Filter 'ObjectClass -eq "group"'

    # Get all adobjects in a specific OU
    Get-ADObject -Filter * -SearchBase 'CN=Configuration,DC=Fabrikam,DC=Com'   

    # Get ADobject with LDAPFilter
    Get-ADObject -LDAPFilter "(objectClass=site)"

}

function RandomPassword {
    param (
        [Parameter(Mandatory)]
        [ValidateRange(4, [int]::MaxValue)]
        [int]$length,
        [int]$upper = 1,
        [int]$lower = 1,
        [int]$numeric = 1,
        [int]$special = 1
    )
    if ($upper + $lower + $numeric + $special -gt $length) {
        throw "number of upper/lower/numeric/special char must be lower or equal to length"
    }
    $uCharSet = "ABCDEFGHJKMNPQRSTUWXYZ"
    $lCharSet = "abcdfhjkmnrstuwxyz"
    $nCharSet = "23456789"
    $sCharSet = "/*-+!?=@_"
    $charSet = ""
    if ($upper -gt 0) { $charSet += $uCharSet }
    if ($lower -gt 0) { $charSet += $lCharSet }
    if ($numeric -gt 0) { $charSet += $nCharSet }
    if ($special -gt 0) { $charSet += $sCharSet }
    $charSet = $charSet.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
    $rng.GetBytes($bytes)
    $result = New-Object char[]($length)
    for ($i = 0; $i -lt $length; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }
    $password = (-join $result)
    $valid = $true
    if ($upper -gt ($password.ToCharArray() | Where-Object { $_ -cin $uCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($lower -gt ($password.ToCharArray() | Where-Object { $_ -cin $lCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($numeric -gt ($password.ToCharArray() | Where-Object { $_ -cin $nCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($special -gt ($password.ToCharArray() | Where-Object { $_ -cin $sCharSet.ToCharArray() }).Count) { $valid = $false }
    if (!$valid) {
        $password = RandomPassword $length $upper $lower $numeric $special
    }
    return $password
}