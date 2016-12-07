[CmdletBinding()]
<#
    .Synopsis 
    Upload-XLRJsonTemplate puts the archived JSON into the correct format (adds leading and trailing brackets) and imports. The user must have the import template right!

    .Parameter File
    File to the JSON you want to import. It must exist!

    .Parameter User
    The user who will be logging on to the XLR API

    .Parameter Server
    Which box will be used.

    .Parameter EncodedCreds
    If you do not wish to use the password at the start, encode the username and password as shown below and pass as an argument

#>
Param(
[Parameter(Mandatory=$True)]
[string]
[ValidateScript({Test-Path $_})]
$File =,

[Parameter(Mandatory=$True)]
[string]
$Server,

[Parameter(Mandatory=$True)]
[string]
$User,

[Parameter(Mandatory=$False)]
[string]
$EncodedCreds
)
If(!$encodedCreds){

    $pass = Read-Host 
    $pair = "$($user):$($pass)"

    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
}
$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

$Object = Get-Content $File
$Body = "[$Object]"
Invoke-RestMethod -Uri "https://$server/api/v1/templates/import" -Method POST -Headers $Headers -Body $Body -ContentType application/json
