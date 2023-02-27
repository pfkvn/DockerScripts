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

# IMAGE selection
$dockerService = (Get-Service docker -ErrorAction Ignore)
    if (!($dockerService)) {
        throw "Docker Service not found. Docker is not started, not installed or not running Windows Containers."
    }

    if ($dockerService.Status -ne "Running") {
        throw "Docker Service is $($dockerService.Status) (Needs to be running)"
    }

    $dockerVersion = docker version -f "{{.Server.Os}}/{{.Client.Version}}/{{.Server.Version}}"
    $dockerOS = $dockerVersion.Split('/')[0]
    $dockerClientVersion = $dockerVersion.Split('/')[1]
    $dockerServerVersion = $dockerVersion.Split('/')[2]

    if ("$dockerOS" -eq "") {
        throw "Docker service is not yet ready."
    }
    elseif ($dockerOS -ne "Windows") {
        throw "Docker is running $dockerOS containers, you need to switch to Windows containers."
   	}
Write-Host "Docker Client Version is $dockerClientVersion"
Write-Host "Docker Server Version is $dockerServerVersion"

$ImageName = 'alworkspace'
$allImages = @(docker images --format "{{.Repository}}:{{.Tag}}")
#Write-Host $allImages

foreach ($Image in $allImages)
    {
    '{0} - {1}' -f ($allImages.IndexOf($Image) + 1), $Image
    }

$Choice = ''
while ([string]::IsNullOrEmpty($Choice))
    {
    Write-Host
    $Choice = Read-Host 'Please choose an image by number '
    if ($Choice -notin 1..$allImages.Count)
        {
        [console]::Beep(1000, 300)
        Write-Warning ('')
        Write-Warning ('Your choice [ {0} ] is not valid.' -f $Choice)
        Write-Warning ('The valid choices are 1 thru {0}.' -f $allImages.Count)
        Write-Warning ('Please try again ...')
        pause

        $Choice = ''
        }
    }

''
'You chose {0}' -f $allImages[$Choice - 1]

# PASSWORD (set to admin)
$password = 'admin'
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credential = New-Object pscredential 'admin', $securePassword
$auth = 'UserPassword'

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

$StartDate=(GET-DATE)

# CREATE CONTAINER from image
New-BcContainer `
    -accept_eula `
    -containerName $containerName `
    -isolation Process `
    -credential $credential `
    -auth $auth `
    -imageName $allImages[$Choice - 1] `
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
