# TEST ADMINISTRATOR
$user = [Security.Principal.WindowsIdentity]::GetCurrent();
if (-not ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)))  
{
    Write-Host "Run script as administrator, please!"
    exit
}

# CONTAINER NAME
$ContainerName2 = 'Cont_' +  (Get-Date -Format "MMdd_HHmm")
$ContainerName = Read-Host "`n Container name (ENTER for '" + $ContainerName2 + "')"    

if($ContainerName -eq "") {
    $ContainerName = $ContainerName2
}

# ONPREM or SANDBOX
do {
$ContainerType = Read-Host "`n Sandbox (S) or Onprem (O)"    
}
until (($ContainerType -eq "S") -or ($ContainerType -eq "O"))

if (($ContainerType -eq "S")){
$ContainerType = "Sandbox"
} else {
$ContainerType = "OnPrem"
}

# VERSION
$Version = Read-Host "`n Version (ENTER for latest)"    

if ($Version -eq "")
{
$Select = 'Latest'
}
else
{
$Select = 'Closest'
}

# COUNTRY
$Country = Read-Host "`n Country (ENTER for nz)"

if ($Country -eq "")
{
$Country = 'nz'
}

# LICENSE
Write-Host 'Select license...'

$DefDir = 'C:\NAV\Other\'

if ((Test-Path -Path $DefDir) -eq 0){
    $DefDir = [Environment]::GetFolderPath('Desktop')
}
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = $DefDir
    Filter = 'License (*.flf)|*.flf'
}
$null = $FileBrowser.ShowDialog()

if ($licenseFile -eq "")
{
    Write-Host '...no license selected'
    exit
}

$licenseFile = $FileBrowser.FileName
if ((Test-Path -Path $LicenseFile -PathType Leaf) -eq 0){
    Write-Host "You must select a valid license"
    exit
}
Write-Host '...license selected:' + $licenseFile

# PASSWORD (set to admin)
$password = 'admin'
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object pscredential 'admin', $securePassword
$auth = 'UserPassword'

$StartDate=(GET-DATE)

# SELECT ARTIFACT AND CREATE CONTAINER
if ($Version -eq ""){    
    $artifactUrl = Get-BcArtifactUrl -type $ContainerType -country $Country -select $Select    
}
else {
    $artifactUrl = Get-BcArtifactUrl -type $ContainerType -country $Country -select $Select -version $Version
}
Write-Host 'Artifact URL: ' + $artifactUrl

New-BcContainer `
    -accept_eula `
    -containerName $containerName `
    -credential $credential `
    -auth $auth `
    -artifactUrl $artifactUrl `
    -isolation process `
    -imageName 'myimage' `
    -assignPremiumPlan `
    -licenseFile $licenseFile `
    -includeAL `
    -vsixFile (Get-LatestAlLanguageExtensionUrl) `
    -updateHosts 
    #-includeTestToolkit 
    #-includeCSide

# END
$EndDate=(GET-DATE)

$TimespanThingy = NEW-TIMESPAN –Start $StartDate –End $EndDate

Write-Host '`n Time to crate a container: ' + $TimespanThingy
