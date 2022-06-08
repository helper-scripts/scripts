###### DISABLING IEEC
#####Disable IE security on Windows Server via PowerShell
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
function Enable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1 -Force
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled." -ForegroundColor Green
}
function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
}
Disable-UserAccessControl
Disable-InternetExplorerESC

###### INSTALLING GIT

# get latest download url for git-for-windows 64-bit exe
$git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
$asset = Invoke-RestMethod -Method Get -Uri $git_url | % assets | where name -like "*64-bit.exe"
# download installer
$installer = "$env:temp\$($asset.name)"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer
# run installer
$git_install_inf = "<install inf file>"
$install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
Start-Process -FilePath $installer -ArgumentList $install_args -Wait


###### INSTALLING TERRAFORM
$SaveToPath = 'C:\Terraform'

try
{
    if ($PSCmdlet.ParameterSetName -eq 'Version')
    {
        $downloadVersion = $Version
    }
    else
    {
        $releasesUrl = 'https://api.github.com/repos/hashicorp/terraform/releases'
        $releases = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $releasesUrl
        $downloadVersion = $releases.Where({!$_.prerelease})[0].name.trim('v')
    }

    $terraformFile = "terraform_${downloadVersion}_windows_amd64.zip"
    $terraformURL = "https://releases.hashicorp.com/terraform/${downloadVersion}/${terraformFile}"

    $download = Invoke-WebRequest -UseBasicParsing -Uri $terraformURL -DisableKeepAlive -OutFile "${env:Temp}\${terraformFile}" -ErrorAction SilentlyContinue -PassThru

    if (($download.StatusCode -eq 200) -and (Test-Path "${env:Temp}\${terraformFile}"))
    {
        # If SaveToPath does not exist, create it
        if (-not (Test-Path -Path $SaveToPath))
        {
            $null = New-Item -Path $SaveToPath -ItemType Directory -Force
        }

        # Unblock File
        Unblock-File "${env:Temp}\${terraformFile}"

        # Unpack archive
        Start-Sleep -Seconds 10
        Expand-Archive -Path "${env:Temp}\${terraformFile}" -DestinationPath $SaveToPath -Force

        # Clean up temp folder
        Remove-Item -Path "${env:Temp}\${terraformFile}" -Force

        # Set up environment variable
        
        $path = [Environment]::GetEnvironmentVariable('Path', "Machine")
        [Environment]::SetEnvironmentVariable('PATH', "${path};${SaveToPath}", 'Machine')

    }
}
catch
{
    Write-Error $_
}

###### INSTALLING AZ CLI

$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi


###### INSTALLING AZURE POWERSHELL

#Etape : Installation Module AZ
install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

#Etape : register the default repository for PowerShell modules
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

#Etape : Install the module AZ
Install-Module -Name Az