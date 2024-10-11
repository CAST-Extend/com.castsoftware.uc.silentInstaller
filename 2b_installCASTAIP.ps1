
$CurrentDirectory = Get-Location
$pathToInstallers="$CurrentDirectory\download"
$installerID="com.castsoftware.aip"
$extractToPath="$CurrentDirectory\download"

# Read configurations, list of packages to download
$jsonInstallConfigFile = "config\InstallConfig.json"
$installTemplatesdirectory = "config\installtemplates"
$setupissTemplateFile = $installTemplatesdirectory + "\aipcore_setup.iss.template"

$installdefaultsdirectory = "logs\generatedinstallfiles"
$setupissOutputFile = $installdefaultsdirectory + "\aipcore_setup.iss"

# Check if the directory for default settings exists, create if it doesn't exist
if (-not (Test-Path -Path $installdefaultsdirectory)) {
    New-Item -Path $installdefaultsdirectory -ItemType Directory -Force
}

# Read the JSON file for list of files to download
$jsonContent = Get-Content -Path $jsonInstallConfigFile -Raw
$data = $jsonContent | ConvertFrom-Json
$installDir = $data.InstallParameters.installdir

# Read the setup iss template file for imaging core installation
$setupissTemplateContent = Get-Content -Path $setupissTemplateFile -Raw
#generate the new setup iss file using the install path per the config provided
$setupissContent = $setupissTemplateContent.Replace("template_aipcore_path", "$installDir")
$setupissContent | Out-File -FilePath $setupissOutputFile 

#Time to Install the component
function Install-SilentApp {
    param (
        [string]$installerPath,
        [string]$silentArgs
    )

    # Check if the installer file exists
    if (-Not (Test-Path -Path $installerPath)) {
        Write-Host "Installer not found at: $installerPath"
        return
    }

    # Run the installer as an administrator
    Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Verb RunAs -Wait

    # Check the exit code to confirm the installation was successful
	Write-Host "Installation completed" # with code $LASTEXITCODE"
}

Write-Host "################# Installing AIP Core #################"

$files = Get-ChildItem -Path $pathToInstallers -File

$files = Get-ChildItem -Path $pathToInstallers -File

foreach ($file in $files) {
	
	$fileNameParts = $file.Name.split("[0123456789]")

    if ($fileNameParts[0] -eq "$installerID.") {
        $InstallerFullPath = $file.FullName
		$InstallerFileName = [System.IO.Path]::GetFileNameWithoutExtension($InstallerFullPath)
		continue
    }
}

if (![string]::IsNullOrEmpty($InstallerFileName)) {
	
	# Load the required assembly
	Add-Type -AssemblyName "System.IO.Compression.FileSystem"

	# Extract the ZIP file
	$extractToPath = "$extractToPath\$InstallerFileName"
	
	Write-host "Extracting $InstallerFileName at $extractToPath"
	
	#Check if the extraction folder exists
	if (-not (Test-Path -Path $extractToPath)) 
	{
		New-Item -Path $extractToPath -ItemType Directory
	}

	# Check if the folder is empty
	$folderIsEmpty = -not (Get-ChildItem -Path $extractToPath | Where-Object { $_.PSIsContainer })
	if ($folderIsEmpty) 
	{
		[System.IO.Compression.ZipFile]::ExtractToDirectory($InstallerFullPath, $extractToPath)
		Write-Host "INFO: Extraction complete."
	} 
	else 
	{
		Write-Host "INFO: Extraction was already done hence skipping."
	} 

	#Now its time to install the application
	$setuplogfile = "logs\imagingcoreinstall.log"
	$installerPath = "$extractToPath\data\setup.exe"
	$setupArgs = "/s /f1$setupissOutputFile /f2$setuplogfile"
	
	Write-Host "INFO: Starting Installation"
	Install-SilentApp -installerPath $installerPath $setupArgs
}





