[CmdletBinding()]
<#
    .Synopsis 
    Update-XLRBackup.ps1 is designed to be run on a schedule or ad-hoc. It polls the XLR API and checks to see if any templates have been amended since the last run. If there have, it iterates over all the templates and compares the latest JSON format with the last known version. If there is a difference, it increments the version number and keeps a new copy in the store. 

    .Parameter Store
    Parent Path to the store where the folders should be kept.

    .Parameter User
    The user who will be logging on to the XLR API

    .Parameter Server
    Which box will be used.

    .Parameter EncodedCreds
    If you do not wish to use the password at the start, encode the username and password as shown below and pass as an argument

#>
Param(
[Parameter(Mandatory=$False)]
[string]
[ValidateScript({Test-Path $_})]
$Store = ".\Store",

[Parameter(Mandatory=$True)]
[string]
$User,

[Parameter(Mandatory=$True)]
[string]
$Server,

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
$Now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Templates = Invoke-RestMethod -Uri "https://$Server/api/v1/templates/" -Method Get -Headers $Headers


$MainDiff = "$Store/Difference"
$MainRef = "$Store/Reference"

If(!(Test-Path $MainRef)){
    New-Item -Path $MainRef -ItemType File 
    Write-Output "EMPTY" > $MainRef 
}

$Templates > $MainDiff
$MainComp = Compare-Object -ReferenceObject (Get-Content $MainRef) -DifferenceObject (Get-Content $MainDiff)

If($MainComp -ne $Null){

    $Reported = @()

    ForEach ($Template in $Templates){
        $TempTitle = $Template.title
        $Amended = $False
        $TemplateFolder = "$Store\$($Template.id)"
        $TempRequest = Invoke-WebRequest -Uri "https://xlr.eu.rabonet.com/api/v1/templates/$($Template.id)" -Method Get -Headers $Headers
        If(Test-Path -Path $TemplateFolder){
            Write-Verbose "$TemplateFolder Exists"
            $LastKnown = Get-ChildItem $TemplateFolder | Sort-Object -Descending | Select -First 1
            $CurrentVersion = $LastKnown.FullName
            $ReferenceObject = Get-Content $CurrentVersion
            $VersionNumber = [convert]::ToInt32($LastKnown.Name, 10)
            $NextVersion = $VersionNumber + 1
            Write-Verbose "$VersionNumber $NextVersion"

            $DifferencePath = "$TemplateFolder/$NextVersion"
            $LatestKnown = $TempRequest.Content > $DifferencePath  
            $DifferenceObject = Get-Content $DifferencePath

            $Compare = Compare-Object -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject -Verbose
        
            If($Compare -eq $Null){
                Write-Verbose "$CurrentVersion is current version of $TempTitle."
                Remove-Item $DifferencePath -Force
            }
            Else{
                Write-Verbose "$CurrentVersion is no longer current version of $TempTitle."
                $VersionNumber = $NextVersion
                $Amended = $True
            }
        }

        Else{
            Write-Verbose "$TemplateFolder does not exist"
            $Create = New-Item -Path $TemplateFolder -ItemType Directory
            $CurrentVersion = "$TemplateFolder/1"
            $TempRequest.Content > $CurrentVersion
            $VersionNumber = 1
        }

        $Report = New-Object -type PSObject -Property @{Title=$TempTitle;Version=$VersionNumber;Amended=$Amended}
        $Reported += $Report
    }

    $Total = $Reported.Count
    $AmendedCheck = $Reported | Where Amended -eq True | Measure-Object  
    $AmendedCount = $AmendedCheck.Count
    
    Write-Output "$Now Total:$Total Amended:$AmendedCount"
    $Reported | ConvertTo-Json
}
Else{
    Write-Output "$Now No Amendments since last run"
}

Move-Item -Path $MainDiff -Destination $MainRef -Force
